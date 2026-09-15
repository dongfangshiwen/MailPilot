package app.mailpilot.services

import android.annotation.SuppressLint
import android.content.Context
import android.webkit.*
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONObject
import org.json.JSONTokener
import org.jsoup.Jsoup
import java.io.ByteArrayInputStream

/** Ephemeral, noninteractive DOM reader. No native bridge, cookies, files, forms or direct networking. */
class AndroidWebRenderer internal constructor(private val context: Context,private val transportFactory: (WebDocument)->WebRenderTransport): WebPageRenderer {
    constructor(context: Context): this(context,{ WebRenderTransport(it) })
    override suspend fun render(document: WebDocument): WebPage = lock.withLock {
        val transport=transportFactory(document)
        val loadError=java.util.concurrent.atomic.AtomicBoolean()
        var view: WebView?=null
        try {
            withContext(Dispatchers.Main) {
                suspendCancellableCoroutine<Unit> { continuation ->
                    CookieManager.getInstance().removeAllCookies { if(continuation.isActive) continuation.resumeWith(Result.success(Unit)) }
                }
                view=create(document,transport,loadError)
            }
            var previous=""; var stable=0
            val initial=WebContentPolicy.analyze(document.html)
            fun normalized(text: String)=text.replace(Regex("\\s+"),"")
            var last=JSONObject()
            withTimeoutOrNull(18000) {
                while(true) {
                    delay(300)
                    if(loadError.get()) return@withTimeoutOrNull WebPage(status="renderer_failed")
                    val snapshot=withContext(Dispatchers.Main) { snapshot(requireNotNull(view)) }
                    last=snapshot
                    if(snapshot.optBoolean("login")) return@withTimeoutOrNull WebPage(status="login_required")
                    val text=snapshot.optString("text").trim()
                    if(text.length>PublicWebReader.MAX_BYTES) return@withTimeoutOrNull WebPage(status="too_large")
                    stable=if(text==previous) stable+1 else 0; previous=text
                    // Avoid returning the page's loading placeholder as a verified document.
                    if(stable>=5 && transport.idle && snapshot.optBoolean("ready") && snapshot.optInt("pending")==0) {
                        if(transport.failureStatus.isNotBlank()) return@withTimeoutOrNull WebPage(text,transport.failureStatus,rendered=true,cause=transport.failureCause)
                        if(snapshot.optBoolean("failed")) return@withTimeoutOrNull WebPage(text,"resource_failed",rendered=true,cause="script_or_request_failed")
                        if(!snapshot.optBoolean("busy")) {
                            val unchanged=initial.scripted && normalized(text)==normalized(initial.page.text)
                            val status=if(snapshot.optBoolean("content") && !unchanged) "complete" else "limited_content"
                            return@withTimeoutOrNull WebPage(text,status,rendered=true)
                        }
                    }
                }
                @Suppress("UNREACHABLE_CODE") WebPage(status="empty_or_dynamic")
            } ?: WebPage(last.optString("text"),transport.failureStatus.ifBlank { "loading_incomplete" },rendered=true,cause=transport.failureCause)
        } finally {
            transport.close()
            withContext(NonCancellable+Dispatchers.Main) {
                view?.apply { stopLoading(); loadUrl("about:blank"); clearHistory(); clearCache(true); removeAllViews(); destroy() }
                WebStorage.getInstance().deleteAllData()
            }
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    @Suppress("DEPRECATION")
    private fun create(document: WebDocument,transport: WebRenderTransport,loadError: java.util.concurrent.atomic.AtomicBoolean): WebView {
        CookieManager.getInstance().setAcceptCookie(false)
        WebStorage.getInstance().deleteAllData()
        ServiceWorkerController.getInstance().serviceWorkerWebSettings.apply {
            blockNetworkLoads=true; allowFileAccess=false; allowContentAccess=false
        }
        return WebView(context.applicationContext).apply {
            settings.apply {
                javaScriptEnabled=true
                domStorageEnabled=true
                allowFileAccess=false; allowContentAccess=false
                allowFileAccessFromFileURLs=false
                allowUniversalAccessFromFileURLs=false
                blockNetworkLoads=true; blockNetworkImage=true; loadsImagesAutomatically=false
                javaScriptCanOpenWindowsAutomatically=false; setSupportMultipleWindows(false)
                mixedContentMode=WebSettings.MIXED_CONTENT_NEVER_ALLOW
                cacheMode=WebSettings.LOAD_NO_CACHE
                userAgentString=PublicWebReader.USER_AGENT
                mediaPlaybackRequiresUserGesture=true
            }
            CookieManager.getInstance().setAcceptThirdPartyCookies(this,false)
            webChromeClient=object: WebChromeClient() {
                override fun onPermissionRequest(request: PermissionRequest) { request.deny() }
                override fun onGeolocationPermissionsShowPrompt(origin: String,callback: GeolocationPermissions.Callback) { callback.invoke(origin,false,false) }
                override fun onJsAlert(view: WebView,url: String,message: String,result: JsResult): Boolean { result.cancel(); return true }
                override fun onJsConfirm(view: WebView,url: String,message: String,result: JsResult): Boolean { result.cancel(); return true }
                override fun onJsPrompt(view: WebView,url: String,message: String,defaultValue: String,result: JsPromptResult): Boolean { result.cancel(); return true }
                override fun onConsoleMessage(consoleMessage: ConsoleMessage)=true // Never log page content.
            }
            webViewClient=object: WebViewClient() {
                private val initial=java.util.concurrent.atomic.AtomicBoolean(true)
                override fun shouldOverrideUrlLoading(view: WebView,request: WebResourceRequest)=true
                override fun onReceivedError(view: WebView,request: WebResourceRequest,error: WebResourceError) { if(request.isForMainFrame) loadError.set(true) }
                override fun onReceivedHttpError(view: WebView,request: WebResourceRequest,response: WebResourceResponse) { if(request.isForMainFrame) loadError.set(true) }
                override fun shouldInterceptRequest(view: WebView,request: WebResourceRequest): WebResourceResponse {
                    if(request.isForMainFrame && initial.compareAndSet(true,false) &&
                        request.url.toString()==document.url.newBuilder().fragment(null).build().toString()) {
                        return WebResourceResponse("text/html","UTF-8",200,"OK",mapOf("Content-Security-Policy" to policy(document),"Cache-Control" to "no-store"),
                            ByteArrayInputStream(sandboxHtml(document.html).toByteArray(Charsets.UTF_8)))
                    }
                    val loaded=if(request.isForMainFrame) null else transport.load(request.url.toString(),request.method)
                    return if(loaded==null) WebResourceResponse("text/plain","UTF-8",403,"Blocked",emptyMap(),ByteArrayInputStream(byteArrayOf()))
                    else WebResourceResponse(loaded.type,loaded.encoding,ByteArrayInputStream(loaded.bytes))
                }
            }
            setDownloadListener { _,_,_,_,_ -> } // Never execute a page-initiated download.
            measure(android.view.View.MeasureSpec.makeMeasureSpec(1080,android.view.View.MeasureSpec.EXACTLY),android.view.View.MeasureSpec.makeMeasureSpec(1920,android.view.View.MeasureSpec.EXACTLY))
            layout(0,0,1080,1920)
            // Supply the already-fetched document through interception; never fetch it a second time.
            loadUrl(document.url.toString())
        }
    }

    private suspend fun snapshot(view: WebView): JSONObject = suspendCancellableCoroutine { continuation ->
        view.evaluateJavascript("""(function(){
          function visible(e){return e.getClientRects().length>0&&getComputedStyle(e).visibility!=='hidden'&&!e.closest('[hidden],[aria-hidden=true]');}
          var login=Array.from(document.querySelectorAll('input[type=password]')).some(visible);
          var busy=Array.from(document.querySelectorAll('[aria-busy=true],[role=progressbar],progress')).some(visible);
          var root=document.querySelector('main,article,[role=main]')||document.body;
          var content=false,text=[],walker=root&&document.createTreeWalker(root,NodeFilter.SHOW_TEXT),node;
          while(walker&&(node=walker.nextNode())){var e=node.parentElement;if(node.textContent.trim()&&visible(e)&&!e.closest('script,style,noscript,nav,footer,header,form,svg')){text.push(node.textContent.trim());if(!e.closest('button,input,select,textarea,[role=button],[role=status],[role=progressbar],progress'))content=true;}}
          var state=window.__mailpilotReadState?window.__mailpilotReadState():{pending:0,failed:true};
          return JSON.stringify({login:login,ready:document.readyState==='complete',busy:busy,pending:state.pending,failed:state.failed,content:content,text:text.join('\n').slice(0,2097153)});
        })()""") { value ->
            if(continuation.isActive) continuation.resumeWith(Result.success(runCatching { JSONObject(JSONTokener(value).nextValue() as String) }.getOrDefault(JSONObject())))
        }
    }
    companion object {
        // WebStorage is process scoped. Serialize renderers and erase it between pages/accounts.
        private val lock=Mutex()
        internal fun policy(document: WebDocument): String {
            val origin=document.url.newBuilder().encodedPath("/").query(null).fragment(null).build().toString().removeSuffix("/")
            return "default-src 'none'; script-src https: http: 'unsafe-inline' 'unsafe-eval'; style-src https: http: 'unsafe-inline'; connect-src $origin; img-src data:; worker-src 'none'; frame-src 'none'; form-action 'none'; base-uri 'none'; object-src 'none'; sandbox allow-scripts allow-same-origin"
        }
        internal fun sandboxHtml(html: String): String {
            val doc=Jsoup.parse(html)
            doc.select("iframe,frame,object,embed,base,meta[http-equiv=refresh]").remove()
            // The mandatory CSP comes from the response header, outside page-controlled DOM.
            doc.head().prependElement("script").appendChild(org.jsoup.nodes.DataNode(READINESS_TRACKER))
            return doc.outerHtml()
        }
        // Observes readiness only. Request methods, bodies and permissions are never rewritten.
        private val READINESS_TRACKER="""(function(){
          let pending=0,failed=false;
          Object.defineProperty(window,'__mailpilotReadState',{value:()=>({pending:pending,failed:failed})});
          const fetch=window.fetch.bind(window);
          window.fetch=function(){pending++;try{return fetch.apply(null,arguments).then(r=>{if(!r.ok)failed=true;pending--;return r;},e=>{failed=true;pending--;throw e;});}catch(e){failed=true;pending--;throw e;}};
          const send=XMLHttpRequest.prototype.send;
          XMLHttpRequest.prototype.send=function(){
            pending++;let done=false;const finish=()=>{if(!done){done=true;pending--;if(this.status===0||this.status>=400)failed=true;}};
            this.addEventListener('loadend',finish,{once:true});
            try{return send.apply(this,arguments);}catch(e){finish();throw e;}
          };
          window.addEventListener('error',e=>{if(e.target===window||(e.target&&e.target.tagName==='SCRIPT'))failed=true;},true);
          window.addEventListener('unhandledrejection',()=>{failed=true;});
        })();"""
    }
}
