// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get switchAccount => '切换邮箱';

  @override
  String get closeAccountPicker => '关闭邮箱选择';

  @override
  String switchAccountCurrent(String p0) {
    return '切换邮箱，当前 $p0';
  }

  @override
  String get openWithAnotherApp => '使用其他应用打开';

  @override
  String get openInAnotherApp => '其他应用打开';

  @override
  String get saveToDevice => '保存到手机';

  @override
  String get couldNotStartRecording => '无法开始录音';

  @override
  String get addImage => '添加图片';

  @override
  String get addFile => '添加文件';

  @override
  String get selectEmails => '选择邮件';

  @override
  String get manageImportedMaterials => '管理已导入资料';

  @override
  String get deepThinking => '深度思考';

  @override
  String get editInput => '修改输入';

  @override
  String get cancelEdit => '取消修改';

  @override
  String selectedMaterialsCount(int p0, int p1) {
    return '已选 $p0 封邮件 · $p1 个附件';
  }

  @override
  String get clearSelection => '清空选择';

  @override
  String get listeningUpToSeconds => '正在聆听 · 最长 60 秒';

  @override
  String get transcribing => '正在识别…';

  @override
  String get startingMicrophone => '正在启动麦克风…';

  @override
  String get recordAgainInCloudMode => '云端重录';

  @override
  String get cancelVoiceInput => '取消语音输入';

  @override
  String get askAboutSelectedMaterials => '询问所选资料…';

  @override
  String get messageOrUseVoiceInput => '发消息，或语音输入';

  @override
  String get smartSearch => '智能搜索';

  @override
  String get thinking => '思考';

  @override
  String get search => '搜索';

  @override
  String get addAttachment => '添加附件';

  @override
  String get stopResponse => '停止回答';

  @override
  String get stopRecording => '结束录音';

  @override
  String get sendQuestion => '发送问题';

  @override
  String get voiceInput => '语音输入';

  @override
  String get draftDeleted => '草稿已删除';

  @override
  String get pleaseViewTheLatestVersion => '请查看最新版本';

  @override
  String get from => '发件人';

  @override
  String get to => '收件人';

  @override
  String get cc => '抄送';

  @override
  String get bcc => '密送';

  @override
  String get notEntered => '尚未填写';

  @override
  String get noSubject => '（无主题）';

  @override
  String get afterReviewingConfirmSendingOrTapThe => '核对后回复“确认发送”，或点击下方按钮。';

  @override
  String get confirmSend => '确认发送';

  @override
  String get addRecipient => '补充收件人';

  @override
  String get viewLatestVersion => '查看最新版本';

  @override
  String get reviewAndEdit => '查看并修改';

  @override
  String get editEmail => '编辑邮件';

  @override
  String get jumpToLatestMessage => '回到最新消息';

  @override
  String get inbox => '收件箱';

  @override
  String get sent => '已发送';

  @override
  String get drafts => '草稿';

  @override
  String get deleted => '已删除';

  @override
  String get spam => '垃圾邮件';

  @override
  String get archive => '归档';

  @override
  String get mailFolders => '邮件文件夹';

  @override
  String get refreshFolders => '刷新文件夹';

  @override
  String couldNotRefreshFoldersLocalListRetained(String p0) {
    return '文件夹刷新失败，已保留本地列表。$p0';
  }

  @override
  String get unreadOnly => '仅显示未读';

  @override
  String get deleteThisDraft => '删除这份草稿？';

  @override
  String get onlyTheLocalDraftIsDeletedChats => '仅删除本地草稿，聊天记录和服务器邮件保留。';

  @override
  String get delete => '删除';

  @override
  String get draftActions => '草稿操作';

  @override
  String get rewrite => '重新拟写';

  @override
  String get deleteDraft => '删除草稿';

  @override
  String get recipientEmail => '目标邮箱';

  @override
  String get separateMultipleAddressesWithCommas => '多个地址用英文逗号分隔';

  @override
  String get afterSavingReviewTheNewConfirmationCard => '保存后展示新确认卡片，由你核对并发送。';

  @override
  String get saveRecipients => '保存收件人';

  @override
  String get draftAnswerPrompt => '请将本次对话中这条回答涉及的内容写成正式邮件：';

  @override
  String get draftAnswerPromptSuffix => '供我检查并确认发送。';

  @override
  String get turnThisAnswerIntoAnEmail => '将这条回答写成邮件';

  @override
  String get viewOriginalOfOlderVersion => '查看旧版原文';

  @override
  String get messageActions => '消息操作';

  @override
  String get needsVerification => '待核实';

  @override
  String get sending => '发送中';

  @override
  String get sendFailed => '发送失败';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String attachmentCount(int p0) {
    return '$p0 个附件';
  }

  @override
  String select(String p0) {
    return '选择 $p0';
  }

  @override
  String get emailAndModelConnectionsRequireAndroidUse =>
      '邮箱与模型连接需要 Android 设备，请使用界面预览入口。';

  @override
  String get notConnectedToTheAndroidMailService =>
      '未连接到 Android 邮件服务。请完全关闭后重新打开最新版 APK；浏览器和 Widget Preview 请使用界面预览入口。';

  @override
  String get actionIncomplete => '操作未完成';

  @override
  String get thisFeatureIsUnavailableInTheCurrent => '当前运行环境不支持此功能';

  @override
  String get pin => '置顶';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get previousDays => '7 天内';

  @override
  String get previousDays86 => '30 天内';

  @override
  String olderConversationDate(String p0, String p1, String p2) {
    return '$p0 年 $p1 月 $p2 日';
  }

  @override
  String get loadingConversations => '正在加载对话';

  @override
  String get noMatchingConversations => '没有找到相关对话';

  @override
  String get yourConversationsWillAppearHere => '对话会保存在这里';

  @override
  String get tryShorterKeywordsOrClearTheSearch => '试试更短的关键词，或清空搜索。';

  @override
  String get startAChatAndComeBackAnytime => '开始聊天后，随时回来继续。';

  @override
  String get clearSearch => '清空搜索';

  @override
  String get startAConversation => '开始对话';

  @override
  String get couldNotLoadConversationsTapToRetry => '会话加载失败，点击重试';

  @override
  String get renameConversation => '重命名对话';

  @override
  String get enterConversationName => '输入对话名称';

  @override
  String get save => '保存';

  @override
  String deleteConversationCount(int p0) {
    return '删除 $p0 个对话？';
  }

  @override
  String get chatsSummariesAndAnalysisCachesForThese =>
      '聊天记录、摘要及这些会话的分析缓存会被删除，邮箱邮件和草稿保留。';

  @override
  String get rename => '重命名';

  @override
  String get unpin => '取消置顶';

  @override
  String get selectMultiple => '多选';

  @override
  String selectedConversationCount(int p0) {
    return '已选 $p0 个对话';
  }

  @override
  String get exitSelection => '退出多选';

  @override
  String get closeSidebar => '关闭侧栏';

  @override
  String get searchConversations => '搜索对话内容…';

  @override
  String get conversationSummary => '对话摘要';

  @override
  String get loading => '正在加载…';

  @override
  String get loadMore => '加载更多';

  @override
  String get selectConversations => '多选对话';

  @override
  String get settings => '设置';

  @override
  String get thisConversationSSummary => '本次对话摘要';

  @override
  String summarizedMessageCount(int p0) {
    return '已整理 $p0 条较早消息';
  }

  @override
  String get closeSummary => '关闭对话摘要';

  @override
  String get originalMessagesAreRetainedYouCanAdd => '原始聊天仍保留，可继续补充或纠正。';

  @override
  String get noSummaryForThisConversationYet => '当前对话暂无摘要。';

  @override
  String get conversationChangedPleaseReopenTheSummary => '对话已切换，请重新打开摘要。';

  @override
  String get draftingReadOnlyPreview => '正在起草 · 只读预览';

  @override
  String get incompleteCannotSend => '未完成 · 不能发送';

  @override
  String get draftingEmail => '邮件起草';

  @override
  String get generatingResponse => '生成回答';

  @override
  String get readingImages => '读取图片';

  @override
  String get preparingMaterials => '准备资料';

  @override
  String get generatingContent => '生成内容';

  @override
  String get parsingModelAction => '解析模型操作';

  @override
  String get organizingExistingResults => '整理已有结果';

  @override
  String get organizingContext => '整理上下文';

  @override
  String get webSearch => '联网搜索';

  @override
  String get currentRequest => '本轮请求';

  @override
  String get requestId => '请求标识';

  @override
  String get serverId => '服务端标识';

  @override
  String get httpStatus => 'HTTP 状态';

  @override
  String get finishReason => '结束原因';

  @override
  String get exceptionType => '异常类型';

  @override
  String get validationResult => '校验结果';

  @override
  String get requestBudgetAndDiagnostics => '本轮预算与诊断';

  @override
  String get connectionDiagnostics => '连接诊断';

  @override
  String get requestRecordsForThisTurn => '本轮请求记录';

  @override
  String get closeDiagnostics => '关闭连接诊断';

  @override
  String get processingStage => '处理阶段';

  @override
  String get model => '模型';

  @override
  String get apiHost => '接口主机';

  @override
  String get imageProcessing => '图片处理';

  @override
  String get fullTextAndImageResponse => '完整图文回答';

  @override
  String get visionAssistantReading => '视觉助手读取';

  @override
  String get batchProcessingSelectedForThisTurn => '本轮选择分批';

  @override
  String get reusingPreviousAnalysis => '复用此前分析';

  @override
  String get requestsWithImages => '带图请求';

  @override
  String requestCount(int p0) {
    return '$p0 次';
  }

  @override
  String get totalImagesUploaded => '累计上传图片';

  @override
  String imageCount(int p0) {
    return '$p0 张';
  }

  @override
  String get reusedImages => '复用图片';

  @override
  String get batchingReason => '分批原因';

  @override
  String get estimatedInput => '预计输入';

  @override
  String get availableInputBudget => '可用输入预算';

  @override
  String get configuredContext => '配置上下文';

  @override
  String get outputReserve => '输出预留';

  @override
  String get thinkingReserve => '思考预留';

  @override
  String get suggestedSummaryLength => '建议摘要长度';

  @override
  String get summaryBudgetLimit => '摘要可用上限';

  @override
  String get currentSummaryEstimate => '当前摘要估算';

  @override
  String get localEstimatesMayDifferFromProviderMetering =>
      '本地估算，不等同于厂商计量。95% 触发整理，60% 为整理目标。';

  @override
  String get timeToFirstChunk => '首包耗时';

  @override
  String get lastChunkReceived => '末包到达';

  @override
  String get requestDuration => '请求用时';

  @override
  String get technicalDetails => '技术详情';

  @override
  String get requestIdsAndExceptionInformation => '请求标识与异常信息';

  @override
  String get convertedToEmailBodyReviewBeforeSaving => '已转换为邮件正文，请检查后保存';

  @override
  String get conversionFailedOriginalTextRetained => '正文转换失败，原文已保留';

  @override
  String get discardUnsavedChanges => '放弃未保存的修改？';

  @override
  String get savedDraftsAreRetained => '已保存的草稿会保留。';

  @override
  String get discardChanges => '放弃修改';

  @override
  String get deleteThisLocalRecord => '删除这条本地记录？';

  @override
  String get serverEmailsAreRetained => '服务器邮件会保留。';

  @override
  String get composeEmail => '写邮件';

  @override
  String get back => '返回';

  @override
  String get moreEmailActions => '更多邮件操作';

  @override
  String get saveChangesAndRewrite => '保存修改后重新拟写';

  @override
  String get convertMarkdownToBodyText => '将 Markdown 转为正文';

  @override
  String get sendingAccount => '发件邮箱';

  @override
  String get subject => '主题';

  @override
  String get body => '正文';

  @override
  String get sendAsThePlainTextShownHere => '按此处显示的纯文本发送';

  @override
  String get ccBcc => '抄送 / 密送';

  @override
  String remove(String p0) {
    return '移除 $p0';
  }

  @override
  String get firstCheckTheServerSSentFolder => '请先核对服务器的已发送记录和收件情况。';

  @override
  String get verifiedThatSendingSucceeded => '已经核实发送成功？';

  @override
  String get thisOnlyUpdatesTheLocalRecord => '此操作只更新本地记录。';

  @override
  String get verifiedSentSuccessfully => '已核实：发送成功';

  @override
  String get confirmedThatNoRecipientsReceivedIt => '确认所有收件人都未收到？';

  @override
  String get restoreTheDraftToReviewAndSend =>
      '恢复草稿后可重新审核发送。若有部分收件人已收到，请先修改收件人。';

  @override
  String get restoreDraft => '恢复草稿';

  @override
  String get verifiedNotSent => '已核实：未发送';

  @override
  String get confirmSendingInChat => '在聊天中确认发送';

  @override
  String get confirmBeforeSending => '发送前确认';

  @override
  String get pleaseReviewTheFollowing => '请核对以下内容';

  @override
  String get accountDeleted => '账号已删除';

  @override
  String get couldNotReadAttachment => '附件读取失败';

  @override
  String get couldNotReadImagePleaseRetry => '图片未能读取，请重试';

  @override
  String get couldNotReadPagePleaseRetry => '页面未能读取，请重试';

  @override
  String get reload => '重新加载';

  @override
  String get referencedMaterial => '引用资料';

  @override
  String get formattedView => '排版阅读';

  @override
  String get viewOriginal => '查看原文';

  @override
  String get theFollowingWasGeneratedByAVision => '以下内容由视觉模型阅读图片后生成，可结合原图核对。';

  @override
  String get previousPage => '上一页';

  @override
  String get nextPage => '下一页';

  @override
  String get loadingReferencedMaterial => '正在加载引用资料…';

  @override
  String get selectedImageOrPdfPagePinchTo => '所选图片附件或 PDF 页面，可双指缩放';

  @override
  String get imageUnavailableRetryOrOpenWithAnother => '图片无法显示，可重试或用其他应用打开。';

  @override
  String get pinchToZoomSavingAndExternalOpening => '双指缩放查看 · 保存和外部打开使用原始附件';

  @override
  String get mail => '邮件';

  @override
  String get myEmails => '我的邮件';

  @override
  String get draftsAndSending => '草稿与发送';

  @override
  String get emailAccounts => '邮箱账户';

  @override
  String get addEmailAccount => '添加邮箱';

  @override
  String get modelsAndServices => '模型与服务';

  @override
  String get defaultModel => '默认模型';

  @override
  String get visionAssistant => '视觉助手';

  @override
  String get addModel => '添加模型';

  @override
  String get automaticCurrentModelPreferred => '自动选择 · 当前模型优先';

  @override
  String fixedAssistant(String p0) {
    return '固定助手 · $p0';
  }

  @override
  String get configurationUnavailable => '配置已失效';

  @override
  String get chooseAutomatically => '自动选择';

  @override
  String get searchAndVoice => '搜索与语音';

  @override
  String get webServicesAndSpeechRecognition => '联网服务、语音识别';

  @override
  String get preferences => '偏好设置';

  @override
  String get contextOrganization => '上下文整理';

  @override
  String get fastOrganizationResponseSettingsUnchanged => '快速整理 · 正式回答不变';

  @override
  String get followCurrentThinkingMode => '跟随当前思考模式';

  @override
  String get fastOrganizationNonThinkingModeOnSupported => '快速整理（支持的接口使用非思考模式）';

  @override
  String get appearance => '外观';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get backgroundSync => '后台同步';

  @override
  String get off => '关闭';

  @override
  String get hourly => '每小时';

  @override
  String get onceADay => '每天一次';

  @override
  String everyMinutes(String p0) {
    return '每 $p0 分钟';
  }

  @override
  String get everyMinutes242 => '每 30 分钟';

  @override
  String get clearCacheAndChats => '清理缓存与聊天记录';

  @override
  String get clearLocalCache => '清理本地缓存？';

  @override
  String get downloadedAttachmentsPagePreviewsAllChatsAnd =>
      '下载的附件、页面预览、全部聊天记录和上下文摘要会被清理。邮箱、模型配置及草稿附件会保留。';

  @override
  String versionAndSendConfirmation(String p0) {
    return 'MailPilot $p0\n每次发送邮件，都由你确认。';
  }

  @override
  String get custom => '自定义';

  @override
  String get appPassword => '授权码';

  @override
  String get alibabaBusiness => '阿里企业';

  @override
  String get passwordSecurityPassword => '密码／安全密码';

  @override
  String get alibabaPersonal => '阿里个人';

  @override
  String get emailPassword => '邮箱密码';

  @override
  String get passwordAppPassword => '密码／授权码';

  @override
  String get leaveBlankToKeepSavedCredentials => '留空保留已保存的凭据。';

  @override
  String get theAdministratorMustAllowThirdPartyClients =>
      '管理员需允许第三方客户端和 IMAP/SMTP。已启用安全密码时，请填写三方客户端安全密码。';

  @override
  String get enterTheFullEmailAddressAndPassword =>
      '填写完整邮箱地址及邮箱密码；请确认已允许客户端访问。';

  @override
  String get enableImapSmtpInYourEmailSettings => '在邮箱设置中开启 IMAP/SMTP 后获取授权码。';

  @override
  String get useTheEmailPasswordOrAppPassword => '填写服务商要求的邮箱密码或客户端授权码。';

  @override
  String get hideCredentials => '隐藏凭据';

  @override
  String get showCredentials => '显示凭据';

  @override
  String get connectEmail => '连接邮箱';

  @override
  String get emailSettings => '邮箱设置';

  @override
  String mail263(String p0) {
    return '$p0 邮箱';
  }

  @override
  String mail264(String p0) {
    return '$p0邮箱';
  }

  @override
  String get emailAddress => '邮箱地址';

  @override
  String get senderNameOptional => '发件人名称（选填）';

  @override
  String get emailSetupGuide => '如何配置邮箱';

  @override
  String get connectionDetailsAndInstructions => '连接参数与填写说明';

  @override
  String officialGuide(String p0) {
    return '$p0 · 官方指引';
  }

  @override
  String get serverAndAdvancedSettings => '服务器与高级设置';

  @override
  String get accountLabel => '账号备注';

  @override
  String get loginUsername => '登录用户名';

  @override
  String get leaveBlankToUseTheFullEmail => '留空使用完整邮箱地址';

  @override
  String get imapHost => 'IMAP 主机';

  @override
  String get imapPort => 'IMAP 端口';

  @override
  String get incomingEncryption => '收信加密';

  @override
  String get smtpHost => 'SMTP 主机';

  @override
  String get smtpPort => 'SMTP 端口';

  @override
  String get outgoingEncryption => '发信加密';

  @override
  String get testConnection => '测试连接';

  @override
  String get saveAccount => '保存邮箱';

  @override
  String get deleteThisAccount => '删除这个邮箱？';

  @override
  String get localEmailsDraftsAndAnalysisForThis =>
      '此邮箱的本地邮件、草稿和分析记录会被删除，服务器邮件会保留。';

  @override
  String get deleteAccount => '删除邮箱';

  @override
  String get modelOptions => '模型选项';

  @override
  String get closeModelOptions => '关闭模型选项';

  @override
  String get defaultTextModel => '默认文字模型';

  @override
  String get forEverydayChatAndEmailDrafting => '用于日常对话与邮件起草';

  @override
  String get useAsFixedVisionAssistant => '固定为视觉助手';

  @override
  String get forReadingImagesAndPdfPages => '用于阅读图片与 PDF 页面';

  @override
  String get connectionDiagnosticsOptional => '连接诊断（可选）';

  @override
  String get sendTextStreamingToolAndImageRequests => '发送文字、流式、工具及图片请求';

  @override
  String get deleteModel => '删除模型';

  @override
  String get deleteLocalConfigurationAndKeyAfterConfirmation =>
      '删除本机配置和密钥，需要再次确认';

  @override
  String get deleteThisModel => '删除这个模型？';

  @override
  String get theLocalConfigurationAndKeyWillBe => '本机的配置和密钥会被删除。';

  @override
  String get setAsFixedVisionAssistant => '已固定为视觉助手';

  @override
  String get setAsDefaultTextModel => '已设为默认文字模型';

  @override
  String get savedLeaveBlankToRetain => '已保存 · 留空保留';

  @override
  String get hideKey => '隐藏密钥';

  @override
  String get showKey => '显示密钥';

  @override
  String get providerDefault => '服务商默认';

  @override
  String get enableThinking => '开启思考';

  @override
  String get disableThinking => '关闭思考';

  @override
  String get letTheModelDecide => '模型自动判断';

  @override
  String get modelSettings => '模型设置';

  @override
  String get connectionConfiguration => '连接配置';

  @override
  String get modelProvider => '模型服务商';

  @override
  String get autoDetect => '自动识别';

  @override
  String autoDetect310(String p0) {
    return '自动识别 · $p0';
  }

  @override
  String get configurationName => '配置名称';

  @override
  String get apiUrl => 'API 地址';

  @override
  String get modelName => '模型名称';

  @override
  String get selectABundledModel => '选择内置型号';

  @override
  String get youCanAlsoEnterTheModelName => '也可以直接填写模型名称';

  @override
  String get bundledModels => '内置型号';

  @override
  String get advancedParameters => '高级参数';

  @override
  String get thinkingModeEffortAndOutputLength => '思考模式、思考档位与输出长度';

  @override
  String get thinkingMode => '思考模式';

  @override
  String get useProviderDefaultsWithoutExtraThinkingParameters =>
      '沿用服务商设置，不附加思考参数';

  @override
  String get askTheModelToThinkDeeply => '请求模型进行深入思考';

  @override
  String get askTheModelToAnswerDirectly => '请求模型直接回答';

  @override
  String get letTheModelDecideWhetherThinkingIs => '由模型按问题决定是否思考';

  @override
  String get thinkingEffort => '思考档位';

  @override
  String get higherEffortUsuallyTakesLongerAndUses =>
      '档位越高，通常等待更久、消耗更多 Token。可用档位以具体模型为准。';

  @override
  String get thinkingBudgetTokens => '思考预算（Token）';

  @override
  String get blankOrUsesProviderDefaultsChooseEither => '留空或 0 跟随服务商；预算与档位二选一。';

  @override
  String get contextSettings => '上下文设置';

  @override
  String get followModelSpecification => '跟随型号';

  @override
  String get officialApisUseVerifiedContextLimitsFor => '官方接口自动匹配已核实型号的上下文额度';

  @override
  String get setALocalBudgetWithinTheProvider => '手动设置本地可用额度，不能超过厂商上限';

  @override
  String currentContextTokens(String p0, String p1) {
    return '当前上下文：$p0 Token。$p1';
  }

  @override
  String get planApiLimitsAreUnverifiedCurrentSettings =>
      '套餐接口限额暂未核实，保留当前配置，不套用标准接口额度。';

  @override
  String get thisApiOrModelIsNotIn => '此接口或型号未收录，可使用自定义额度。';

  @override
  String currentContextTokensOfficialMaximumInputTokens(
    String p0,
    String p1,
    String p2,
    String p3,
  ) {
    return '当前上下文：$p0 Token\n官方最大输入：$p1 Token · $p2\n目录核实于 $p3。实际输入还会预留输出空间。';
  }

  @override
  String get nonThinking => '非思考';

  @override
  String get thinkingDefault => '思考／默认';

  @override
  String get contextIsOrganizedAtOfTheEffective =>
      '预计达到有效输入预算的 95% 时整理，目标降至 60%；原始记录保留。';

  @override
  String get maximumOutputLength => '最大输出长度';

  @override
  String get useModelMaximum => '跟随型号最大值';

  @override
  String get useTheVerifiedMaximumOutputForThe => '按实际型号使用已核实的最大输出额度';

  @override
  String get keepYourCustomOutputLength => '保留你填写的输出长度';

  @override
  String get theMaximumOutputForThisApiIs =>
      '此接口的最大输出尚未核实，暂用 4096 Token，可切换自定义。';

  @override
  String modelMaximumOutputTokensRequestsAdjustTo(String p0) {
    return '型号最大输出：$p0 Token。实际请求按剩余上下文空间调整；模型可以提前结束，不会强制写满。';
  }

  @override
  String get contextLength => '上下文长度';

  @override
  String get customOutputLength => '自定义输出长度';

  @override
  String get lengthsAreInTokensSomeModelsCount => '长度单位为 Token；部分模型会将思考计入输出。';

  @override
  String get outputLengthParameter => '输出长度参数';

  @override
  String get standardParameter => '标准参数';

  @override
  String get completionLengthParameter => '完成长度参数';

  @override
  String get chooseAccordingToTheProviderSApi => '按服务商接口要求选择，不改变填写的输出长度。';

  @override
  String get notTested => '尚未测试';

  @override
  String get processing => '处理中…';

  @override
  String get saveModel => '保存模型';

  @override
  String emailCount(int p0) {
    return '$p0 封邮件';
  }

  @override
  String expandEmailCount(int p0) {
    return '展开全部 $p0 封';
  }

  @override
  String get previousEmailPage => '上一页邮件';

  @override
  String get nextEmailPage => '下一页邮件';

  @override
  String get collapse => '收起';

  @override
  String get qqMail => 'QQ 邮箱';

  @override
  String get enableMailServices => '开启邮箱服务';

  @override
  String get signInToQqMailInA =>
      '在电脑浏览器登录 QQ 邮箱，进入设置 → 账号与安全 → 安全设置，开启 POP3/IMAP/SMTP 服务。';

  @override
  String get generateAnAppPassword => '生成授权码';

  @override
  String get completeIdentityVerificationOnTheOfficialPage =>
      '按官方页面完成身份验证，生成 16 位授权码。在本页填写授权码。';

  @override
  String get returnToAccountForm => '返回填写账号';

  @override
  String get enterTheFullEmailAddressServersAre =>
      '邮箱地址填写完整地址。服务器已预填，可先测试连接，再保存。';

  @override
  String get getAndManageAppPasswords => '获取与管理授权码';

  @override
  String get mail368 => '163 邮箱';

  @override
  String get enableImapSmtp => '开启 IMAP/SMTP';

  @override
  String get signInToWebmailFindPopSmtp =>
      '登录 163 邮箱网页版，在设置中找到 POP3/SMTP/IMAP，开启 IMAP/SMTP 服务。';

  @override
  String get getAClientAppPassword => '获取客户端授权码';

  @override
  String get completeTheVerificationAsInstructedAndEnter =>
      '按页面提示完成验证，将生成的客户端授权码填入本页。';

  @override
  String get checkTheFullEmailAddress => '核对完整邮箱地址';

  @override
  String get useYourFullComAddressIfYou =>
      '使用完整的 @163.com 地址；若找不到开关，可在网易官方帮助中心搜索“授权码”或“IMAP”。';

  @override
  String get neteaseMailOfficialHelp => '网易邮箱官方帮助中心';

  @override
  String get alibabaBusinessMail => '阿里企业邮箱';

  @override
  String get checkClientPermissions => '确认客户端权限';

  @override
  String get askTheAdministratorToAllowThirdParty =>
      '请管理员为当前账号允许第三方客户端登录，并开启 IMAP/SMTP。新购企业邮箱可能默认限制第三方客户端。';

  @override
  String get prepareASecurityPassword => '准备安全密码';

  @override
  String get inWebmailGoToSettingsAccountAnd =>
      '在网页版设置 → 账号与安全中生成三方客户端安全密码。启用后，在本页使用该安全密码。';

  @override
  String get enterTheBusinessEmailAddress => '填写企业邮箱地址';

  @override
  String get useTheFullBusinessAddressDefaultServers =>
      '使用完整的企业邮箱地址。默认使用通用服务器；香港地区或企业指定配置可在高级设置中修改。';

  @override
  String get allowThirdPartyClients => '允许第三方客户端访问';

  @override
  String get generateAThirdPartyClientSecurityPassword => '生成三方客户端安全密码';

  @override
  String get serverAddressesAndPorts => '服务器地址与端口';

  @override
  String get alibabaPersonalMail => '阿里个人邮箱';

  @override
  String get checkAccountType => '确认邮箱类型';

  @override
  String get thisPresetIsForFreeAlibabaCloud =>
      '此配置适用于阿里云免费个人邮箱。使用公司域名的企业邮箱，请选择“阿里企业”。';

  @override
  String get prepareLoginDetails => '准备登录信息';

  @override
  String get enterTheFullEmailAddressAndRequired =>
      '填写完整邮箱地址及邮箱要求的登录凭据；确认账号已允许客户端访问。';

  @override
  String get checkServers => '核对服务器';

  @override
  String get useTheOfficialSslServerSettingsBelow =>
      '使用下方官方 SSL 服务器参数，可先测试连接，再保存。';

  @override
  String get personalMailServersAndPorts => '个人邮箱服务器与端口';

  @override
  String get customEmailProvider => '自定义邮箱';

  @override
  String get identifyYourProvider => '确认服务商';

  @override
  String get aCustomDomainDoesNotIdentifyThe => '自定义域名不能确定邮箱服务商，请向邮箱管理员确认。';

  @override
  String get getConnectionSettings => '获取连接参数';

  @override
  String get prepareImapAndSmtpHostsPortsEncryption =>
      '准备 IMAP、SMTP 主机、端口、加密方式，以及密码或客户端授权码。';

  @override
  String get enterAndVerify => '填写并验证';

  @override
  String get expandServerAndAdvancedSettingsAndEnter =>
      '展开服务器与高级设置，按服务商提供的参数填写。';

  @override
  String setupGuide(String p0) {
    return '$p0配置指引';
  }

  @override
  String get closeSetupGuide => '关闭配置指引';

  @override
  String get defaultServersSsl => '默认服务器 · SSL';

  @override
  String incomingPortOutgoingPort(String p0, String p1) {
    return '收信  $p0\n端口 993\n\n发信  $p1\n端口 465';
  }

  @override
  String get officialHelp => '官方帮助';

  @override
  String verifiedOfficialPagesOpenInYourBrowser(String p0) {
    return '资料核对：$p0 · 官方网页将在浏览器打开';
  }

  @override
  String get returnToForm => '返回填写';

  @override
  String get mailpilotPreview => 'MailPilot · 样例界面';

  @override
  String get thisLinkIsNotAValidWeb => '该链接不是可打开的网页地址';

  @override
  String get openWebpage => '打开网页';

  @override
  String get copyLink => '复制链接';

  @override
  String get openInBrowser => '在浏览器打开';

  @override
  String image(String p0) {
    return '[图片$p0]';
  }

  @override
  String get sizeUnknown => '大小待确认';

  @override
  String get firstPagesByDefaultPageCountPending => '默认前 10 页，页数待读取';

  @override
  String get selectPdfPageNumbers => '选择 PDF 页码';

  @override
  String page(String p0) {
    return '第 $p0 页';
  }

  @override
  String get fileName => '文件名';

  @override
  String get deselect => '取消选择';

  @override
  String get select420 => '选择';

  @override
  String get materialsForThisAnalysis => '本次分析资料';

  @override
  String materialSummary(String p0, String p1, String p2) {
    return '$p0 个附件 · $p1$p2';
  }

  @override
  String withUnknownSize(String p0) {
    return ' · $p0 个大小待确认';
  }

  @override
  String get closeMaterials => '关闭资料管理';

  @override
  String upToAttachmentsMbAndImagesOr(String p0) {
    return '每轮最多 10 个附件、50 MB、20 张图片或 PDF 页面。\n$p0';
  }

  @override
  String get actualImageCountsInPdfAndOffice => 'PDF 与 Office 的实际图片量会在读取时检查。';

  @override
  String get selectedFilesAreReadOnlyWhenPreviewing => '只在预览或提问时读取选中的文件。';

  @override
  String get attachmentListAwaitingSync => '附件清单待同步';

  @override
  String get selectAllSupportedAttachments => '全选可分析附件';

  @override
  String get keepBodyOnly => '只保留正文';

  @override
  String get deviceFiles => '手机文件';

  @override
  String get noMaterialsSelectedAddFilesOrSelect => '尚未选择资料，添加文件或选择邮件即可。';

  @override
  String get materialCheckIncomplete => '资料检查未完成';

  @override
  String get retryWithCurrentMaterials => '按当前资料重试本轮';

  @override
  String get analyzedImages => '已分析的图片';

  @override
  String get previousAnalysisIsReusedByDefaultSelect =>
      '默认复用此前分析。需要查看新细节时，勾选重新核对；下次发送时生效。';

  @override
  String get cancelRecheck => '取消重新核对';

  @override
  String get recheckImages => '重新核对图片';

  @override
  String get previousVersion => '上一版本';

  @override
  String messageVersionCount(String p0, String p1) {
    return '第 $p0 个版本，共 $p1 个版本';
  }

  @override
  String get nextVersion => '下一版本';

  @override
  String get closeMessageActions => '关闭消息操作';

  @override
  String get copyMessage => '复制消息';

  @override
  String get messageCopied => '已复制消息';

  @override
  String close(String p0) {
    return '关闭$p0';
  }

  @override
  String get volcengineArk => '火山引擎 · 方舟';

  @override
  String get alibabaCloudModelStudio => '阿里云 · 百炼';

  @override
  String get openaiCompatibleApi => '通用兼容接口';

  @override
  String get minimalMinimal => '极低 · minimal';

  @override
  String get lowLow => '低 · low';

  @override
  String get mediumMedium => '中 · medium';

  @override
  String get highHigh => '高 · high';

  @override
  String get veryHighXhigh => '很高 · xhigh';

  @override
  String get maximumMax => '最高 · max';

  @override
  String get chooseImageProcessing => '选择图片处理方式';

  @override
  String get yourQuestionMaterialsAndCompletedAnalysisAre => '问题、资料和已完成的分析已保留。';

  @override
  String get adjustMaterials => '调整资料';

  @override
  String get reduceImagesPagesOrTextAndSubmit => '减少图片、页面或文字后重新提交';

  @override
  String get processThisTurnInBatches => '分批处理本轮';

  @override
  String get readUnfinishedImagesInBatchesThenSummarize => '分次读取尚未完成的图片，再汇总回答';

  @override
  String get couldNotReadThisPage => '无法读取此页';

  @override
  String get couldNotReadThisPagePleaseRetry => '无法读取此页，请重试';

  @override
  String get closePagePreview => '关闭页面预览';

  @override
  String get pageImageUnavailable => '此页图片无法显示';

  @override
  String get selectPdfPages => '选择 PDF 页面';

  @override
  String pagesTotal(String p0) {
    return ' · 共 $p0 页';
  }

  @override
  String pagesSelectedMaximum(String p0) {
    return '已选 $p0 页 / 最多 20 页';
  }

  @override
  String get selectAll => '全选';

  @override
  String get firstPages => '前 10 页';

  @override
  String get clear => '清空';

  @override
  String get readingPdf => '正在读取当前 PDF…';

  @override
  String get couldNotReadPageNumbers => '无法读取页码';

  @override
  String get retryReading => '重试读取';

  @override
  String get selectUpToPagesPerPdf => '每份 PDF 最多选择 20 页';

  @override
  String get deselectThisAttachment => '取消选择此附件';

  @override
  String confirmSelectionPages(String p0) {
    return '确认选择 · $p0 页';
  }

  @override
  String get retryPreview => '重试预览';

  @override
  String previewPage(String p0) {
    return '预览第 $p0 页';
  }

  @override
  String get loadingPreview => '正在显示预览…';

  @override
  String page480(String p0, String p1) {
    return '$p0第 $p1 页';
  }

  @override
  String reasoningSegmentHeading(String p0) {
    return '思考 $p0\n';
  }

  @override
  String get searching => '正在搜索';

  @override
  String get searchIncomplete => '搜索未完成';

  @override
  String searchResultCount(int p0) {
    return '搜索到 $p0 条结果';
  }

  @override
  String get readingWebpages => '正在读取网页';

  @override
  String readWebpageCount(int p0) {
    return '已读取 $p0 个网页';
  }

  @override
  String get webpageReadingFinished => '网页读取结束';

  @override
  String get readingMaterials => '正在读取资料';

  @override
  String get sourceExcerptViewed => '已查看来源摘录';

  @override
  String get materialsReused => '已复用资料';

  @override
  String get searchingEmails => '正在检索邮件';

  @override
  String get emailsSearched => '已检索邮件';

  @override
  String get processing493 => '正在处理';

  @override
  String get actionCompleted => '操作已完成';

  @override
  String get lessThanSecond => '不足 1 秒';

  @override
  String elapsedSeconds(int p0) {
    return '$p0 秒';
  }

  @override
  String get thinking497 => '正在思考';

  @override
  String get thinkingStopped => '思考已停止';

  @override
  String get thinkingInterrupted => '思考已中断';

  @override
  String get process => '处理过程';

  @override
  String get thought => '已思考';

  @override
  String get reasoning => '思考过程';

  @override
  String get viewReasoning => '查看思考记录';

  @override
  String get currentAttempt => '本次尝试';

  @override
  String get previousAttempt => '上次尝试';

  @override
  String earlierAttempt(String p0) {
    return '更早尝试 $p0';
  }

  @override
  String get viewingAPreviousAttempt => '正在查看上次尝试';

  @override
  String get reasoningIsLongTheFirstCharactersHave => '思考内容较长，已保留前 128000 字符。';

  @override
  String get jumpToEndOfReasoning => '回到思考末尾';

  @override
  String get uiPreviewSampleDataInstallAndroidTo =>
      '界面预览 · 使用样例数据，连接邮箱和模型请安装 Android 版';

  @override
  String get dismissNotice => '关闭提示';

  @override
  String get backToHome => '返回主页';

  @override
  String get backToSettings => '返回设置';

  @override
  String get backToConversation => '返回对话';

  @override
  String get openMenu => '打开菜单';

  @override
  String get noVersionsAvailable => '版本记录为空';

  @override
  String get couldNotLoadVersionsPleaseRetry => '版本记录暂时无法读取，请重试';

  @override
  String get cannotEditThisQuestion => '无法修改此问题';

  @override
  String get couldNotEditThisQuestionPleaseRetry => '无法修改此问题，请重试';

  @override
  String get editNotSubmittedPleaseRetry => '修改未提交，请重试';

  @override
  String get addAModelFirst => '请先添加模型';

  @override
  String get materialCheckIncompletePleaseRetry => '资料检查未完成，请重试';

  @override
  String get newConversation => '新对话';

  @override
  String get whatSOnYourMind => '有什么想聊的？';

  @override
  String get letSMakeSenseOfYourEmails => '邮件里的事，一起理清。';

  @override
  String get configureAModelToChatYouCan => '配置模型即可聊天，邮箱可以稍后添加。';

  @override
  String get askAQuestionOrSelectEmailsAs => '直接提问，或选择邮件作为资料。';

  @override
  String get helpMeOrganizeMyThoughts => '帮我整理思路';

  @override
  String get helpMeWriteSomething => '帮我写段文字';

  @override
  String get summarizeSelectedEmails => '总结所选邮件';

  @override
  String get helpMeDraftAReply => '帮我起草回复';

  @override
  String get retryWebSearch => '重试联网';

  @override
  String get answerWithoutSearch => '关闭搜索后回答';

  @override
  String get continueSearching => '继续检索';

  @override
  String get responseIncomplete => '回答未完成';

  @override
  String get continueOrganizing => '继续整理';

  @override
  String get retryThisTurn => '重试本轮';

  @override
  String get viewBudget => '查看预算';

  @override
  String get retryWithCompatibleFormat => '兼容格式重试';

  @override
  String get chooseProcessingMethod => '选择处理方式';

  @override
  String get adjustMaterialsAndRetry => '调整资料后重试';

  @override
  String get restoreDefaultThinkingAndRetry => '恢复默认思考并重试';

  @override
  String get chooseVisionAssistant => '选择视觉助手';

  @override
  String get editConfiguration => '修改配置';

  @override
  String vision(String p0) {
    return '读图 · $p0';
  }

  @override
  String sourceCount(int p0) {
    return '$p0 处来源';
  }

  @override
  String get copyResponse => '复制回答';

  @override
  String get originalMarkdownCopied => '已复制 Markdown 原文';

  @override
  String get responseStopped => '本次回答已停止';

  @override
  String get stoppedThePartialResponseReceivedIsShown => '已停止，以上是收到的部分回答';

  @override
  String get reviewDraftAndSend => '查看草稿并发送';

  @override
  String get writeAsEmail => '写成邮件';

  @override
  String get connectingToModel => '正在连接模型…';

  @override
  String get viewingAnOlderVersion => '正在查看历史版本';

  @override
  String get backToLatest => '回到最新';

  @override
  String get textModel => '文字模型';

  @override
  String tapToCancelSync(String p0) {
    return '$p0 · 点击取消同步';
  }

  @override
  String get syncLatestEmailsInEachFolder => '同步各文件夹最新 50 封';

  @override
  String get searchEmails => '搜索邮件';

  @override
  String get emailActions => '邮件操作';

  @override
  String get syncEmailsPerFolder => '同步邮件（每文件夹 50 封）';

  @override
  String get showAll => '显示全部';

  @override
  String get showUnread => '只看未读';

  @override
  String get subjectOrSender => '主题或发件人';

  @override
  String get runSearch => '执行搜索';

  @override
  String get connectAnEmailAccountFirst => '先连接一个邮箱';

  @override
  String get supportsQqAndCustomEmailProviders => '支持 QQ、163 和自定义邮箱。';

  @override
  String get noLocalEmailsYet => '暂无本地邮件';

  @override
  String get pullDownToSyncRecentEmailsStartup => '下拉同步最新邮件，启动时不会自动同步。';

  @override
  String analyzeSelectedEmails(String p0) {
    return '分析已选的 $p0 封邮件';
  }

  @override
  String get emailDetails => '邮件详情';

  @override
  String get replyAndForward => '回复与转发';

  @override
  String get reply => '回复';

  @override
  String get replyAll => '回复全部';

  @override
  String get forward => '转发';

  @override
  String get recipientDetails => '收件信息';

  @override
  String toCc(String p0, String p1) {
    return '收件人：$p0\n抄送：$p1';
  }

  @override
  String get bodyAwaitingBackgroundSyncYouCanKeep => '正文待后台同步，可继续浏览其他邮件。';

  @override
  String attachments(String p0) {
    return '附件 · $p0';
  }

  @override
  String get tapAnAttachmentToPreviewSelectIt => '点按附件预览，勾选用于 AI 分析';

  @override
  String get askAssistant => '交给助手';

  @override
  String get noDraftsYet => '还没有草稿';

  @override
  String get writeYourOwnOrAskTheAssistant => '自己写，或让助手帮你起草。';

  @override
  String get configurationSaved => '配置已保存';

  @override
  String get closeConfiguration => '关闭配置';

  @override
  String get actionFailed => '操作失败';

  @override
  String get backToConfiguration => '返回配置';

  @override
  String get volcengineWebSearch => '火山联网搜索';

  @override
  String get bocha => '博查';

  @override
  String get systemPreferredCloudOptional => '系统优先，云端可选';

  @override
  String get qwenCloudTranscription => '千问云端识别';

  @override
  String get automaticSystemRecognitionFollowsDeviceLanguage =>
      '自动（系统识别跟随手机语言）';

  @override
  String get chinese => '中文';

  @override
  String get searchProvider => '搜索服务商';

  @override
  String get recognitionMode => '识别方式';

  @override
  String get speechLanguage => '语音语言';

  @override
  String get automatic => '自动';

  @override
  String get systemRecognitionNeedsNoApiKeyIf =>
      '系统识别不需要配置密钥。手机没有识别服务时，可使用下方千问 ASR。';

  @override
  String get usedOnlyWhenSmartSearchIsEnabled =>
      '仅在开启智能搜索并提问时使用。搜索服务只接收本轮问题提取的关键词，不接收邮件、附件或历史聊天。';

  @override
  String get qwenAsrBaseUrl => '千问 ASR Base URL';

  @override
  String get fullSearchApiUrl => '完整搜索接口地址';

  @override
  String get leaveBlankToRetainTheSavedKey => '留空保留已保存密钥';

  @override
  String get showOrHideKey => '显示或隐藏密钥';

  @override
  String get asrModel => 'ASR 模型';

  @override
  String get forExampleQwenAsrFlash => '例如 qwen3-asr-flash';

  @override
  String get transcriptionFillsTheInputFieldOnlyReview =>
      '识别结果只填入输入框；检查后由你发送。切换云端需要重新录音，最长 60 秒。';

  @override
  String get streamingUiStateIsOutOfSync => '流式界面状态已失步，请重新打开当前对话。';

  @override
  String get streamNotReceivedCompletelyReopenThisConversation =>
      '流式内容未完整接收，请重新打开当前对话。';

  @override
  String get appLanguage => '语言';

  @override
  String get languageTitle => '选择语言';

  @override
  String get languageDescription => '切换界面语言，邮件与对话内容保持原文。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get switchAccount => '切換郵箱';

  @override
  String get closeAccountPicker => '關閉郵箱選擇';

  @override
  String switchAccountCurrent(String p0) {
    return '切換郵箱，當前 $p0';
  }

  @override
  String get openWithAnotherApp => '使用其他應用開啟';

  @override
  String get openInAnotherApp => '其他應用開啟';

  @override
  String get saveToDevice => '儲存到手機';

  @override
  String get couldNotStartRecording => '無法開始錄音';

  @override
  String get addImage => '新增圖片';

  @override
  String get addFile => '新增檔案';

  @override
  String get selectEmails => '選擇郵件';

  @override
  String get manageImportedMaterials => '管理已匯入資料';

  @override
  String get deepThinking => '深度思考';

  @override
  String get editInput => '修改輸入';

  @override
  String get cancelEdit => '取消修改';

  @override
  String selectedMaterialsCount(int p0, int p1) {
    return '已選 $p0 封郵件 · $p1 個附件';
  }

  @override
  String get clearSelection => '清空選擇';

  @override
  String get listeningUpToSeconds => '正在聆聽 · 最長 60 秒';

  @override
  String get transcribing => '正在識別…';

  @override
  String get startingMicrophone => '正在啟動麥克風…';

  @override
  String get recordAgainInCloudMode => '雲端重錄';

  @override
  String get cancelVoiceInput => '取消語音輸入';

  @override
  String get askAboutSelectedMaterials => '詢問所選資料…';

  @override
  String get messageOrUseVoiceInput => '發訊息，或語音輸入';

  @override
  String get smartSearch => '智慧搜尋';

  @override
  String get thinking => '思考';

  @override
  String get search => '搜尋';

  @override
  String get addAttachment => '新增附件';

  @override
  String get stopResponse => '停止回答';

  @override
  String get stopRecording => '結束錄音';

  @override
  String get sendQuestion => '傳送問題';

  @override
  String get voiceInput => '語音輸入';

  @override
  String get draftDeleted => '草稿已刪除';

  @override
  String get pleaseViewTheLatestVersion => '請檢視最新版本';

  @override
  String get from => '發件人';

  @override
  String get to => '收件人';

  @override
  String get cc => '抄送';

  @override
  String get bcc => '密送';

  @override
  String get notEntered => '尚未填寫';

  @override
  String get noSubject => '（無主題）';

  @override
  String get afterReviewingConfirmSendingOrTapThe => '核對後回覆“確認傳送”，或點選下方按鈕。';

  @override
  String get confirmSend => '確認傳送';

  @override
  String get addRecipient => '補充收件人';

  @override
  String get viewLatestVersion => '檢視最新版本';

  @override
  String get reviewAndEdit => '檢視並修改';

  @override
  String get editEmail => '編輯郵件';

  @override
  String get jumpToLatestMessage => '回到最新訊息';

  @override
  String get inbox => '收件箱';

  @override
  String get sent => '已傳送';

  @override
  String get drafts => '草稿';

  @override
  String get deleted => '已刪除';

  @override
  String get spam => '垃圾郵件';

  @override
  String get archive => '歸檔';

  @override
  String get mailFolders => '郵件資料夾';

  @override
  String get refreshFolders => '重新整理資料夾';

  @override
  String couldNotRefreshFoldersLocalListRetained(String p0) {
    return '資料夾重新整理失敗，已保留本地列表。$p0';
  }

  @override
  String get unreadOnly => '僅顯示未讀';

  @override
  String get deleteThisDraft => '刪除這份草稿？';

  @override
  String get onlyTheLocalDraftIsDeletedChats => '僅刪除本地草稿，聊天記錄和伺服器郵件保留。';

  @override
  String get delete => '刪除';

  @override
  String get draftActions => '草稿操作';

  @override
  String get rewrite => '重新擬寫';

  @override
  String get deleteDraft => '刪除草稿';

  @override
  String get recipientEmail => '目標郵箱';

  @override
  String get separateMultipleAddressesWithCommas => '多個地址用英文逗號分隔';

  @override
  String get afterSavingReviewTheNewConfirmationCard => '儲存後展示新確認卡片，由你核對併傳送。';

  @override
  String get saveRecipients => '儲存收件人';

  @override
  String get draftAnswerPrompt => '請將本次對話中這條回答涉及的內容寫成正式郵件：';

  @override
  String get draftAnswerPromptSuffix => '供我檢查並確認傳送。';

  @override
  String get turnThisAnswerIntoAnEmail => '將這條回答寫成郵件';

  @override
  String get viewOriginalOfOlderVersion => '檢視舊版原文';

  @override
  String get messageActions => '訊息操作';

  @override
  String get needsVerification => '待核實';

  @override
  String get sending => '傳送中';

  @override
  String get sendFailed => '傳送失敗';

  @override
  String get confirm => '確認';

  @override
  String get cancel => '取消';

  @override
  String attachmentCount(int p0) {
    return '$p0 個附件';
  }

  @override
  String select(String p0) {
    return '選擇 $p0';
  }

  @override
  String get emailAndModelConnectionsRequireAndroidUse =>
      '郵箱與模型連線需要 Android 裝置，請使用介面預覽入口。';

  @override
  String get notConnectedToTheAndroidMailService =>
      '未連線到 Android 郵件服務。請完全關閉後重新開啟最新版 APK；瀏覽器和 Widget Preview 請使用介面預覽入口。';

  @override
  String get actionIncomplete => '操作未完成';

  @override
  String get thisFeatureIsUnavailableInTheCurrent => '當前執行環境不支援此功能';

  @override
  String get pin => '置頂';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get previousDays => '7 天內';

  @override
  String get previousDays86 => '30 天內';

  @override
  String olderConversationDate(String p0, String p1, String p2) {
    return '$p0 年 $p1 月 $p2 日';
  }

  @override
  String get loadingConversations => '正在載入對話';

  @override
  String get noMatchingConversations => '沒有找到相關對話';

  @override
  String get yourConversationsWillAppearHere => '對話會儲存在這裡';

  @override
  String get tryShorterKeywordsOrClearTheSearch => '試試更短的關鍵詞，或清空搜尋。';

  @override
  String get startAChatAndComeBackAnytime => '開始聊天后，隨時回來繼續。';

  @override
  String get clearSearch => '清空搜尋';

  @override
  String get startAConversation => '開始對話';

  @override
  String get couldNotLoadConversationsTapToRetry => '會話載入失敗，點選重試';

  @override
  String get renameConversation => '重新命名對話';

  @override
  String get enterConversationName => '輸入對話名稱';

  @override
  String get save => '儲存';

  @override
  String deleteConversationCount(int p0) {
    return '刪除 $p0 個對話？';
  }

  @override
  String get chatsSummariesAndAnalysisCachesForThese =>
      '聊天記錄、摘要及這些會話的分析快取會被刪除，郵箱郵件和草稿保留。';

  @override
  String get rename => '重新命名';

  @override
  String get unpin => '取消置頂';

  @override
  String get selectMultiple => '多選';

  @override
  String selectedConversationCount(int p0) {
    return '已選 $p0 個對話';
  }

  @override
  String get exitSelection => '退出多選';

  @override
  String get closeSidebar => '關閉側欄';

  @override
  String get searchConversations => '搜尋對話內容…';

  @override
  String get conversationSummary => '對話摘要';

  @override
  String get loading => '正在載入…';

  @override
  String get loadMore => '載入更多';

  @override
  String get selectConversations => '多選對話';

  @override
  String get settings => '設定';

  @override
  String get thisConversationSSummary => '本次對話摘要';

  @override
  String summarizedMessageCount(int p0) {
    return '已整理 $p0 條較早訊息';
  }

  @override
  String get closeSummary => '關閉對話摘要';

  @override
  String get originalMessagesAreRetainedYouCanAdd => '原始聊天仍保留，可繼續補充或糾正。';

  @override
  String get noSummaryForThisConversationYet => '當前對話暫無摘要。';

  @override
  String get conversationChangedPleaseReopenTheSummary => '對話已切換，請重新開啟摘要。';

  @override
  String get draftingReadOnlyPreview => '正在起草 · 只讀預覽';

  @override
  String get incompleteCannotSend => '未完成 · 不能傳送';

  @override
  String get draftingEmail => '郵件起草';

  @override
  String get generatingResponse => '生成回答';

  @override
  String get readingImages => '讀取圖片';

  @override
  String get preparingMaterials => '準備資料';

  @override
  String get generatingContent => '生成內容';

  @override
  String get parsingModelAction => '解析模型操作';

  @override
  String get organizingExistingResults => '整理已有結果';

  @override
  String get organizingContext => '整理上下文';

  @override
  String get webSearch => '聯網搜尋';

  @override
  String get currentRequest => '本輪請求';

  @override
  String get requestId => '請求標識';

  @override
  String get serverId => '服務端標識';

  @override
  String get httpStatus => 'HTTP 狀態';

  @override
  String get finishReason => '結束原因';

  @override
  String get exceptionType => '異常型別';

  @override
  String get validationResult => '校驗結果';

  @override
  String get requestBudgetAndDiagnostics => '本輪預算與診斷';

  @override
  String get connectionDiagnostics => '連線診斷';

  @override
  String get requestRecordsForThisTurn => '本輪請求記錄';

  @override
  String get closeDiagnostics => '關閉連線診斷';

  @override
  String get processingStage => '處理階段';

  @override
  String get model => '模型';

  @override
  String get apiHost => '介面主機';

  @override
  String get imageProcessing => '圖片處理';

  @override
  String get fullTextAndImageResponse => '完整圖文回答';

  @override
  String get visionAssistantReading => '視覺助手讀取';

  @override
  String get batchProcessingSelectedForThisTurn => '本輪選擇分批';

  @override
  String get reusingPreviousAnalysis => '複用此前分析';

  @override
  String get requestsWithImages => '帶圖請求';

  @override
  String requestCount(int p0) {
    return '$p0 次';
  }

  @override
  String get totalImagesUploaded => '累計上傳圖片';

  @override
  String imageCount(int p0) {
    return '$p0 張';
  }

  @override
  String get reusedImages => '複用圖片';

  @override
  String get batchingReason => '分批原因';

  @override
  String get estimatedInput => '預計輸入';

  @override
  String get availableInputBudget => '可用輸入預算';

  @override
  String get configuredContext => '配置上下文';

  @override
  String get outputReserve => '輸出預留';

  @override
  String get thinkingReserve => '思考預留';

  @override
  String get suggestedSummaryLength => '建議摘要長度';

  @override
  String get summaryBudgetLimit => '摘要可用上限';

  @override
  String get currentSummaryEstimate => '當前摘要估算';

  @override
  String get localEstimatesMayDifferFromProviderMetering =>
      '本地估算，不等同於廠商計量。95% 觸發整理，60% 為整理目標。';

  @override
  String get timeToFirstChunk => '首包耗時';

  @override
  String get lastChunkReceived => '末包到達';

  @override
  String get requestDuration => '請求用時';

  @override
  String get technicalDetails => '技術詳情';

  @override
  String get requestIdsAndExceptionInformation => '請求標識與異常資訊';

  @override
  String get convertedToEmailBodyReviewBeforeSaving => '已轉換為郵件正文，請檢查後儲存';

  @override
  String get conversionFailedOriginalTextRetained => '正文轉換失敗，原文已保留';

  @override
  String get discardUnsavedChanges => '放棄未儲存的修改？';

  @override
  String get savedDraftsAreRetained => '已儲存的草稿會保留。';

  @override
  String get discardChanges => '放棄修改';

  @override
  String get deleteThisLocalRecord => '刪除這條本地記錄？';

  @override
  String get serverEmailsAreRetained => '伺服器郵件會保留。';

  @override
  String get composeEmail => '寫郵件';

  @override
  String get back => '返回';

  @override
  String get moreEmailActions => '更多郵件操作';

  @override
  String get saveChangesAndRewrite => '儲存修改後重新擬寫';

  @override
  String get convertMarkdownToBodyText => '將 Markdown 轉為正文';

  @override
  String get sendingAccount => '發件郵箱';

  @override
  String get subject => '主題';

  @override
  String get body => '正文';

  @override
  String get sendAsThePlainTextShownHere => '按此處顯示的純文字傳送';

  @override
  String get ccBcc => '抄送 / 密送';

  @override
  String remove(String p0) {
    return '移除 $p0';
  }

  @override
  String get firstCheckTheServerSSentFolder => '請先核對伺服器的已傳送記錄和收件情況。';

  @override
  String get verifiedThatSendingSucceeded => '已經核實傳送成功？';

  @override
  String get thisOnlyUpdatesTheLocalRecord => '此操作只更新本地記錄。';

  @override
  String get verifiedSentSuccessfully => '已核實：傳送成功';

  @override
  String get confirmedThatNoRecipientsReceivedIt => '確認所有收件人都未收到？';

  @override
  String get restoreTheDraftToReviewAndSend =>
      '恢復草稿後可重新稽核傳送。若有部分收件人已收到，請先修改收件人。';

  @override
  String get restoreDraft => '恢復草稿';

  @override
  String get verifiedNotSent => '已核實：未傳送';

  @override
  String get confirmSendingInChat => '在聊天中確認傳送';

  @override
  String get confirmBeforeSending => '傳送前確認';

  @override
  String get pleaseReviewTheFollowing => '請核對以下內容';

  @override
  String get accountDeleted => '賬號已刪除';

  @override
  String get couldNotReadAttachment => '附件讀取失敗';

  @override
  String get couldNotReadImagePleaseRetry => '圖片未能讀取，請重試';

  @override
  String get couldNotReadPagePleaseRetry => '頁面未能讀取，請重試';

  @override
  String get reload => '重新載入';

  @override
  String get referencedMaterial => '引用資料';

  @override
  String get formattedView => '排版閱讀';

  @override
  String get viewOriginal => '檢視原文';

  @override
  String get theFollowingWasGeneratedByAVision => '以下內容由視覺模型閱讀圖片後生成，可結合原圖核對。';

  @override
  String get previousPage => '上一頁';

  @override
  String get nextPage => '下一頁';

  @override
  String get loadingReferencedMaterial => '正在載入引用資料…';

  @override
  String get selectedImageOrPdfPagePinchTo => '所選圖片附件或 PDF 頁面，可雙指縮放';

  @override
  String get imageUnavailableRetryOrOpenWithAnother => '圖片無法顯示，可重試或用其他應用開啟。';

  @override
  String get pinchToZoomSavingAndExternalOpening => '雙指縮放檢視 · 儲存和外部開啟使用原始附件';

  @override
  String get mail => '郵件';

  @override
  String get myEmails => '我的郵件';

  @override
  String get draftsAndSending => '草稿與傳送';

  @override
  String get emailAccounts => '郵箱賬戶';

  @override
  String get addEmailAccount => '新增郵箱';

  @override
  String get modelsAndServices => '模型與服務';

  @override
  String get defaultModel => '預設模型';

  @override
  String get visionAssistant => '視覺助手';

  @override
  String get addModel => '新增模型';

  @override
  String get automaticCurrentModelPreferred => '自動選擇 · 當前模型優先';

  @override
  String fixedAssistant(String p0) {
    return '固定助手 · $p0';
  }

  @override
  String get configurationUnavailable => '配置已失效';

  @override
  String get chooseAutomatically => '自動選擇';

  @override
  String get searchAndVoice => '搜尋與語音';

  @override
  String get webServicesAndSpeechRecognition => '聯網服務、語音識別';

  @override
  String get preferences => '偏好設定';

  @override
  String get contextOrganization => '上下文整理';

  @override
  String get fastOrganizationResponseSettingsUnchanged => '快速整理 · 正式回答不變';

  @override
  String get followCurrentThinkingMode => '跟隨當前思考模式';

  @override
  String get fastOrganizationNonThinkingModeOnSupported => '快速整理（支援的介面使用非思考模式）';

  @override
  String get appearance => '外觀';

  @override
  String get systemDefault => '跟隨系統';

  @override
  String get light => '淺色';

  @override
  String get dark => '深色';

  @override
  String get backgroundSync => '後臺同步';

  @override
  String get off => '關閉';

  @override
  String get hourly => '每小時';

  @override
  String get onceADay => '每天一次';

  @override
  String everyMinutes(String p0) {
    return '每 $p0 分鐘';
  }

  @override
  String get everyMinutes242 => '每 30 分鐘';

  @override
  String get clearCacheAndChats => '清理快取與聊天記錄';

  @override
  String get clearLocalCache => '清理本地快取？';

  @override
  String get downloadedAttachmentsPagePreviewsAllChatsAnd =>
      '下載的附件、頁面預覽、全部聊天記錄和上下文摘要會被清理。郵箱、模型配置及草稿附件會保留。';

  @override
  String versionAndSendConfirmation(String p0) {
    return 'MailPilot $p0\n每次傳送郵件，都由你確認。';
  }

  @override
  String get custom => '自定義';

  @override
  String get appPassword => '授權碼';

  @override
  String get alibabaBusiness => '阿里企業';

  @override
  String get passwordSecurityPassword => '密碼／安全密碼';

  @override
  String get alibabaPersonal => '阿里個人';

  @override
  String get emailPassword => '郵箱密碼';

  @override
  String get passwordAppPassword => '密碼／授權碼';

  @override
  String get leaveBlankToKeepSavedCredentials => '留空保留已儲存的憑據。';

  @override
  String get theAdministratorMustAllowThirdPartyClients =>
      '管理員需允許第三方客戶端和 IMAP/SMTP。已啟用安全密碼時，請填寫三方客戶端安全密碼。';

  @override
  String get enterTheFullEmailAddressAndPassword =>
      '填寫完整郵箱地址及郵箱密碼；請確認已允許客戶端訪問。';

  @override
  String get enableImapSmtpInYourEmailSettings => '在郵箱設定中開啟 IMAP/SMTP 後獲取授權碼。';

  @override
  String get useTheEmailPasswordOrAppPassword => '填寫服務商要求的郵箱密碼或客戶端授權碼。';

  @override
  String get hideCredentials => '隱藏憑據';

  @override
  String get showCredentials => '顯示憑據';

  @override
  String get connectEmail => '連線郵箱';

  @override
  String get emailSettings => '郵箱設定';

  @override
  String mail263(String p0) {
    return '$p0 郵箱';
  }

  @override
  String mail264(String p0) {
    return '$p0郵箱';
  }

  @override
  String get emailAddress => '郵箱地址';

  @override
  String get senderNameOptional => '發件人名稱（選填）';

  @override
  String get emailSetupGuide => '如何配置郵箱';

  @override
  String get connectionDetailsAndInstructions => '連線引數與填寫說明';

  @override
  String officialGuide(String p0) {
    return '$p0 · 官方指引';
  }

  @override
  String get serverAndAdvancedSettings => '伺服器與高階設定';

  @override
  String get accountLabel => '賬號備註';

  @override
  String get loginUsername => '登入使用者名稱';

  @override
  String get leaveBlankToUseTheFullEmail => '留空使用完整郵箱地址';

  @override
  String get imapHost => 'IMAP 主機';

  @override
  String get imapPort => 'IMAP 埠';

  @override
  String get incomingEncryption => '收信加密';

  @override
  String get smtpHost => 'SMTP 主機';

  @override
  String get smtpPort => 'SMTP 埠';

  @override
  String get outgoingEncryption => '發信加密';

  @override
  String get testConnection => '測試連線';

  @override
  String get saveAccount => '儲存郵箱';

  @override
  String get deleteThisAccount => '刪除這個郵箱？';

  @override
  String get localEmailsDraftsAndAnalysisForThis =>
      '此郵箱的本地郵件、草稿和分析記錄會被刪除，伺服器郵件會保留。';

  @override
  String get deleteAccount => '刪除郵箱';

  @override
  String get modelOptions => '模型選項';

  @override
  String get closeModelOptions => '關閉模型選項';

  @override
  String get defaultTextModel => '預設文字模型';

  @override
  String get forEverydayChatAndEmailDrafting => '用於日常對話與郵件起草';

  @override
  String get useAsFixedVisionAssistant => '固定為視覺助手';

  @override
  String get forReadingImagesAndPdfPages => '用於閱讀圖片與 PDF 頁面';

  @override
  String get connectionDiagnosticsOptional => '連線診斷（可選）';

  @override
  String get sendTextStreamingToolAndImageRequests => '傳送文字、流式、工具及圖片請求';

  @override
  String get deleteModel => '刪除模型';

  @override
  String get deleteLocalConfigurationAndKeyAfterConfirmation =>
      '刪除本機配置和金鑰，需要再次確認';

  @override
  String get deleteThisModel => '刪除這個模型？';

  @override
  String get theLocalConfigurationAndKeyWillBe => '本機的配置和金鑰會被刪除。';

  @override
  String get setAsFixedVisionAssistant => '已固定為視覺助手';

  @override
  String get setAsDefaultTextModel => '已設為預設文字模型';

  @override
  String get savedLeaveBlankToRetain => '已儲存 · 留空保留';

  @override
  String get hideKey => '隱藏金鑰';

  @override
  String get showKey => '顯示金鑰';

  @override
  String get providerDefault => '服務商預設';

  @override
  String get enableThinking => '開啟思考';

  @override
  String get disableThinking => '關閉思考';

  @override
  String get letTheModelDecide => '模型自動判斷';

  @override
  String get modelSettings => '模型設定';

  @override
  String get connectionConfiguration => '連線配置';

  @override
  String get modelProvider => '模型服務商';

  @override
  String get autoDetect => '自動識別';

  @override
  String autoDetect310(String p0) {
    return '自動識別 · $p0';
  }

  @override
  String get configurationName => '配置名稱';

  @override
  String get apiUrl => 'API 地址';

  @override
  String get modelName => '模型名稱';

  @override
  String get selectABundledModel => '選擇內建型號';

  @override
  String get youCanAlsoEnterTheModelName => '也可以直接填寫模型名稱';

  @override
  String get bundledModels => '內建型號';

  @override
  String get advancedParameters => '高階引數';

  @override
  String get thinkingModeEffortAndOutputLength => '思考模式、思考檔位與輸出長度';

  @override
  String get thinkingMode => '思考模式';

  @override
  String get useProviderDefaultsWithoutExtraThinkingParameters =>
      '沿用服務商設定，不附加思考引數';

  @override
  String get askTheModelToThinkDeeply => '請求模型進行深入思考';

  @override
  String get askTheModelToAnswerDirectly => '請求模型直接回答';

  @override
  String get letTheModelDecideWhetherThinkingIs => '由模型按問題決定是否思考';

  @override
  String get thinkingEffort => '思考檔位';

  @override
  String get higherEffortUsuallyTakesLongerAndUses =>
      '檔位越高，通常等待更久、消耗更多 Token。可用檔位以具體模型為準。';

  @override
  String get thinkingBudgetTokens => '思考預算（Token）';

  @override
  String get blankOrUsesProviderDefaultsChooseEither => '留空或 0 跟隨服務商；預算與檔位二選一。';

  @override
  String get contextSettings => '上下文設定';

  @override
  String get followModelSpecification => '跟隨型號';

  @override
  String get officialApisUseVerifiedContextLimitsFor => '官方介面自動匹配已核實型號的上下文額度';

  @override
  String get setALocalBudgetWithinTheProvider => '手動設定本地可用額度，不能超過廠商上限';

  @override
  String currentContextTokens(String p0, String p1) {
    return '當前上下文：$p0 Token。$p1';
  }

  @override
  String get planApiLimitsAreUnverifiedCurrentSettings =>
      '套餐介面限額暫未核實，保留當前配置，不套用標準介面額度。';

  @override
  String get thisApiOrModelIsNotIn => '此介面或型號未收錄，可使用自定義額度。';

  @override
  String currentContextTokensOfficialMaximumInputTokens(
    String p0,
    String p1,
    String p2,
    String p3,
  ) {
    return '當前上下文：$p0 Token\n官方最大輸入：$p1 Token · $p2\n目錄核實於 $p3。實際輸入還會預留輸出空間。';
  }

  @override
  String get nonThinking => '非思考';

  @override
  String get thinkingDefault => '思考／預設';

  @override
  String get contextIsOrganizedAtOfTheEffective =>
      '預計達到有效輸入預算的 95% 時整理，目標降至 60%；原始記錄保留。';

  @override
  String get maximumOutputLength => '最大輸出長度';

  @override
  String get useModelMaximum => '跟隨型號最大值';

  @override
  String get useTheVerifiedMaximumOutputForThe => '按實際型號使用已核實的最大輸出額度';

  @override
  String get keepYourCustomOutputLength => '保留你填寫的輸出長度';

  @override
  String get theMaximumOutputForThisApiIs =>
      '此介面的最大輸出尚未核實，暫用 4096 Token，可切換自定義。';

  @override
  String modelMaximumOutputTokensRequestsAdjustTo(String p0) {
    return '型號最大輸出：$p0 Token。實際請求按剩餘上下文空間調整；模型可以提前結束，不會強制寫滿。';
  }

  @override
  String get contextLength => '上下文長度';

  @override
  String get customOutputLength => '自定義輸出長度';

  @override
  String get lengthsAreInTokensSomeModelsCount => '長度單位為 Token；部分模型會將思考計入輸出。';

  @override
  String get outputLengthParameter => '輸出長度引數';

  @override
  String get standardParameter => '標準引數';

  @override
  String get completionLengthParameter => '完成長度引數';

  @override
  String get chooseAccordingToTheProviderSApi => '按服務商介面要求選擇，不改變填寫的輸出長度。';

  @override
  String get notTested => '尚未測試';

  @override
  String get processing => '處理中…';

  @override
  String get saveModel => '儲存模型';

  @override
  String emailCount(int p0) {
    return '$p0 封郵件';
  }

  @override
  String expandEmailCount(int p0) {
    return '展開全部 $p0 封';
  }

  @override
  String get previousEmailPage => '上一頁郵件';

  @override
  String get nextEmailPage => '下一頁郵件';

  @override
  String get collapse => '收起';

  @override
  String get qqMail => 'QQ 郵箱';

  @override
  String get enableMailServices => '開啟郵箱服務';

  @override
  String get signInToQqMailInA =>
      '在電腦瀏覽器登入 QQ 郵箱，進入設定 → 賬號與安全 → 安全設定，開啟 POP3/IMAP/SMTP 服務。';

  @override
  String get generateAnAppPassword => '生成授權碼';

  @override
  String get completeIdentityVerificationOnTheOfficialPage =>
      '按官方頁面完成身份驗證，生成 16 位授權碼。在本頁填寫授權碼。';

  @override
  String get returnToAccountForm => '返回填寫賬號';

  @override
  String get enterTheFullEmailAddressServersAre =>
      '郵箱地址填寫完整地址。伺服器已預填，可先測試連線，再儲存。';

  @override
  String get getAndManageAppPasswords => '獲取與管理授權碼';

  @override
  String get mail368 => '163 郵箱';

  @override
  String get enableImapSmtp => '開啟 IMAP/SMTP';

  @override
  String get signInToWebmailFindPopSmtp =>
      '登入 163 郵箱網頁版，在設定中找到 POP3/SMTP/IMAP，開啟 IMAP/SMTP 服務。';

  @override
  String get getAClientAppPassword => '獲取客戶端授權碼';

  @override
  String get completeTheVerificationAsInstructedAndEnter =>
      '按頁面提示完成驗證，將生成的客戶端授權碼填入本頁。';

  @override
  String get checkTheFullEmailAddress => '核對完整郵箱地址';

  @override
  String get useYourFullComAddressIfYou =>
      '使用完整的 @163.com 位址；若找不到開關，可在網易官方說明中心搜尋「授权码」或「IMAP」。';

  @override
  String get neteaseMailOfficialHelp => '網易郵箱官方幫助中心';

  @override
  String get alibabaBusinessMail => '阿里企業郵箱';

  @override
  String get checkClientPermissions => '確認客戶端許可權';

  @override
  String get askTheAdministratorToAllowThirdParty =>
      '請管理員為當前賬號允許第三方客戶端登入，並開啟 IMAP/SMTP。新購企業郵箱可能預設限制第三方客戶端。';

  @override
  String get prepareASecurityPassword => '準備安全密碼';

  @override
  String get inWebmailGoToSettingsAccountAnd =>
      '在網頁版設定 → 賬號與安全中生成三方客戶端安全密碼。啟用後，在本頁使用該安全密碼。';

  @override
  String get enterTheBusinessEmailAddress => '填寫企業郵箱地址';

  @override
  String get useTheFullBusinessAddressDefaultServers =>
      '使用完整的企業郵箱地址。預設使用通用伺服器；香港地區或企業指定配置可在高階設定中修改。';

  @override
  String get allowThirdPartyClients => '允許第三方客戶端訪問';

  @override
  String get generateAThirdPartyClientSecurityPassword => '生成三方客戶端安全密碼';

  @override
  String get serverAddressesAndPorts => '伺服器地址與埠';

  @override
  String get alibabaPersonalMail => '阿里個人郵箱';

  @override
  String get checkAccountType => '確認郵箱型別';

  @override
  String get thisPresetIsForFreeAlibabaCloud =>
      '此配置適用於阿里雲免費個人郵箱。使用公司域名的企業郵箱，請選擇“阿里企業”。';

  @override
  String get prepareLoginDetails => '準備登入資訊';

  @override
  String get enterTheFullEmailAddressAndRequired =>
      '填寫完整郵箱地址及郵箱要求的登入憑據；確認賬號已允許客戶端訪問。';

  @override
  String get checkServers => '核對伺服器';

  @override
  String get useTheOfficialSslServerSettingsBelow =>
      '使用下方官方 SSL 伺服器引數，可先測試連線，再儲存。';

  @override
  String get personalMailServersAndPorts => '個人郵箱伺服器與埠';

  @override
  String get customEmailProvider => '自定義郵箱';

  @override
  String get identifyYourProvider => '確認服務商';

  @override
  String get aCustomDomainDoesNotIdentifyThe => '自定義域名不能確定郵箱服務商，請向郵箱管理員確認。';

  @override
  String get getConnectionSettings => '獲取連線引數';

  @override
  String get prepareImapAndSmtpHostsPortsEncryption =>
      '準備 IMAP、SMTP 主機、埠、加密方式，以及密碼或客戶端授權碼。';

  @override
  String get enterAndVerify => '填寫並驗證';

  @override
  String get expandServerAndAdvancedSettingsAndEnter =>
      '展開伺服器與高階設定，按服務商提供的引數填寫。';

  @override
  String setupGuide(String p0) {
    return '$p0配置指引';
  }

  @override
  String get closeSetupGuide => '關閉配置指引';

  @override
  String get defaultServersSsl => '預設伺服器 · SSL';

  @override
  String incomingPortOutgoingPort(String p0, String p1) {
    return '收信  $p0\n埠 993\n\n發信  $p1\n埠 465';
  }

  @override
  String get officialHelp => '官方幫助';

  @override
  String verifiedOfficialPagesOpenInYourBrowser(String p0) {
    return '資料核對：$p0 · 官方網頁將在瀏覽器開啟';
  }

  @override
  String get returnToForm => '返回填寫';

  @override
  String get mailpilotPreview => 'MailPilot · 樣例介面';

  @override
  String get thisLinkIsNotAValidWeb => '該連結不是可開啟的網頁地址';

  @override
  String get openWebpage => '開啟網頁';

  @override
  String get copyLink => '複製連結';

  @override
  String get openInBrowser => '在瀏覽器開啟';

  @override
  String image(String p0) {
    return '[圖片$p0]';
  }

  @override
  String get sizeUnknown => '大小待確認';

  @override
  String get firstPagesByDefaultPageCountPending => '預設前 10 頁，頁數待讀取';

  @override
  String get selectPdfPageNumbers => '選擇 PDF 頁碼';

  @override
  String page(String p0) {
    return '第 $p0 頁';
  }

  @override
  String get fileName => '檔名';

  @override
  String get deselect => '取消選擇';

  @override
  String get select420 => '選擇';

  @override
  String get materialsForThisAnalysis => '本次分析資料';

  @override
  String materialSummary(String p0, String p1, String p2) {
    return '$p0 個附件 · $p1$p2';
  }

  @override
  String withUnknownSize(String p0) {
    return ' · $p0 個大小待確認';
  }

  @override
  String get closeMaterials => '關閉資料管理';

  @override
  String upToAttachmentsMbAndImagesOr(String p0) {
    return '每輪最多 10 個附件、50 MB、20 張圖片或 PDF 頁面。\n$p0';
  }

  @override
  String get actualImageCountsInPdfAndOffice => 'PDF 與 Office 的實際圖片量會在讀取時檢查。';

  @override
  String get selectedFilesAreReadOnlyWhenPreviewing => '只在預覽或提問時讀取選中的檔案。';

  @override
  String get attachmentListAwaitingSync => '附件清單待同步';

  @override
  String get selectAllSupportedAttachments => '全選可分析附件';

  @override
  String get keepBodyOnly => '只保留正文';

  @override
  String get deviceFiles => '手機檔案';

  @override
  String get noMaterialsSelectedAddFilesOrSelect => '尚未選擇資料，新增檔案或選擇郵件即可。';

  @override
  String get materialCheckIncomplete => '資料檢查未完成';

  @override
  String get retryWithCurrentMaterials => '按當前資料重試本輪';

  @override
  String get analyzedImages => '已分析的圖片';

  @override
  String get previousAnalysisIsReusedByDefaultSelect =>
      '預設複用此前分析。需要檢視新細節時，勾選重新核對；下次傳送時生效。';

  @override
  String get cancelRecheck => '取消重新核對';

  @override
  String get recheckImages => '重新核對圖片';

  @override
  String get previousVersion => '上一版本';

  @override
  String messageVersionCount(String p0, String p1) {
    return '第 $p0 個版本，共 $p1 個版本';
  }

  @override
  String get nextVersion => '下一版本';

  @override
  String get closeMessageActions => '關閉訊息操作';

  @override
  String get copyMessage => '複製訊息';

  @override
  String get messageCopied => '已複製訊息';

  @override
  String close(String p0) {
    return '關閉$p0';
  }

  @override
  String get volcengineArk => '火山引擎 · 方舟';

  @override
  String get alibabaCloudModelStudio => '阿里雲 · 百鍊';

  @override
  String get openaiCompatibleApi => '通用相容介面';

  @override
  String get minimalMinimal => '極低 · minimal';

  @override
  String get lowLow => '低 · low';

  @override
  String get mediumMedium => '中 · medium';

  @override
  String get highHigh => '高 · high';

  @override
  String get veryHighXhigh => '很高 · xhigh';

  @override
  String get maximumMax => '最高 · max';

  @override
  String get chooseImageProcessing => '選擇圖片處理方式';

  @override
  String get yourQuestionMaterialsAndCompletedAnalysisAre => '問題、資料和已完成的分析已保留。';

  @override
  String get adjustMaterials => '調整資料';

  @override
  String get reduceImagesPagesOrTextAndSubmit => '減少圖片、頁面或文字後重新提交';

  @override
  String get processThisTurnInBatches => '分批處理本輪';

  @override
  String get readUnfinishedImagesInBatchesThenSummarize => '分次讀取尚未完成的圖片，再彙總回答';

  @override
  String get couldNotReadThisPage => '無法讀取此頁';

  @override
  String get couldNotReadThisPagePleaseRetry => '無法讀取此頁，請重試';

  @override
  String get closePagePreview => '關閉頁面預覽';

  @override
  String get pageImageUnavailable => '此頁圖片無法顯示';

  @override
  String get selectPdfPages => '選擇 PDF 頁面';

  @override
  String pagesTotal(String p0) {
    return ' · 共 $p0 頁';
  }

  @override
  String pagesSelectedMaximum(String p0) {
    return '已選 $p0 頁 / 最多 20 頁';
  }

  @override
  String get selectAll => '全選';

  @override
  String get firstPages => '前 10 頁';

  @override
  String get clear => '清空';

  @override
  String get readingPdf => '正在讀取當前 PDF…';

  @override
  String get couldNotReadPageNumbers => '無法讀取頁碼';

  @override
  String get retryReading => '重試讀取';

  @override
  String get selectUpToPagesPerPdf => '每份 PDF 最多選擇 20 頁';

  @override
  String get deselectThisAttachment => '取消選擇此附件';

  @override
  String confirmSelectionPages(String p0) {
    return '確認選擇 · $p0 頁';
  }

  @override
  String get retryPreview => '重試預覽';

  @override
  String previewPage(String p0) {
    return '預覽第 $p0 頁';
  }

  @override
  String get loadingPreview => '正在顯示預覽…';

  @override
  String page480(String p0, String p1) {
    return '$p0第 $p1 頁';
  }

  @override
  String reasoningSegmentHeading(String p0) {
    return '思考 $p0\n';
  }

  @override
  String get searching => '正在搜尋';

  @override
  String get searchIncomplete => '搜尋未完成';

  @override
  String searchResultCount(int p0) {
    return '搜尋到 $p0 條結果';
  }

  @override
  String get readingWebpages => '正在讀取網頁';

  @override
  String readWebpageCount(int p0) {
    return '已讀取 $p0 個網頁';
  }

  @override
  String get webpageReadingFinished => '網頁讀取結束';

  @override
  String get readingMaterials => '正在讀取資料';

  @override
  String get sourceExcerptViewed => '已檢視來源摘錄';

  @override
  String get materialsReused => '已複用資料';

  @override
  String get searchingEmails => '正在檢索郵件';

  @override
  String get emailsSearched => '已檢索郵件';

  @override
  String get processing493 => '正在處理';

  @override
  String get actionCompleted => '操作已完成';

  @override
  String get lessThanSecond => '不足 1 秒';

  @override
  String elapsedSeconds(int p0) {
    return '$p0 秒';
  }

  @override
  String get thinking497 => '正在思考';

  @override
  String get thinkingStopped => '思考已停止';

  @override
  String get thinkingInterrupted => '思考已中斷';

  @override
  String get process => '處理過程';

  @override
  String get thought => '已思考';

  @override
  String get reasoning => '思考過程';

  @override
  String get viewReasoning => '檢視思考記錄';

  @override
  String get currentAttempt => '本次嘗試';

  @override
  String get previousAttempt => '上次嘗試';

  @override
  String earlierAttempt(String p0) {
    return '更早嘗試 $p0';
  }

  @override
  String get viewingAPreviousAttempt => '正在檢視上次嘗試';

  @override
  String get reasoningIsLongTheFirstCharactersHave => '思考內容較長，已保留前 128000 字元。';

  @override
  String get jumpToEndOfReasoning => '回到思考末尾';

  @override
  String get uiPreviewSampleDataInstallAndroidTo =>
      '介面預覽 · 使用樣例資料，連線郵箱和模型請安裝 Android 版';

  @override
  String get dismissNotice => '關閉提示';

  @override
  String get backToHome => '返回主頁';

  @override
  String get backToSettings => '返回設定';

  @override
  String get backToConversation => '返回對話';

  @override
  String get openMenu => '開啟選單';

  @override
  String get noVersionsAvailable => '版本記錄為空';

  @override
  String get couldNotLoadVersionsPleaseRetry => '版本記錄暫時無法讀取，請重試';

  @override
  String get cannotEditThisQuestion => '無法修改此問題';

  @override
  String get couldNotEditThisQuestionPleaseRetry => '無法修改此問題，請重試';

  @override
  String get editNotSubmittedPleaseRetry => '修改未提交，請重試';

  @override
  String get addAModelFirst => '請先新增模型';

  @override
  String get materialCheckIncompletePleaseRetry => '資料檢查未完成，請重試';

  @override
  String get newConversation => '新對話';

  @override
  String get whatSOnYourMind => '有什麼想聊的？';

  @override
  String get letSMakeSenseOfYourEmails => '郵件裡的事，一起理清。';

  @override
  String get configureAModelToChatYouCan => '配置模型即可聊天，郵箱可以稍後新增。';

  @override
  String get askAQuestionOrSelectEmailsAs => '直接提問，或選擇郵件作為資料。';

  @override
  String get helpMeOrganizeMyThoughts => '幫我整理思路';

  @override
  String get helpMeWriteSomething => '幫我寫段文字';

  @override
  String get summarizeSelectedEmails => '總結所選郵件';

  @override
  String get helpMeDraftAReply => '幫我起草回覆';

  @override
  String get retryWebSearch => '重試聯網';

  @override
  String get answerWithoutSearch => '關閉搜尋後回答';

  @override
  String get continueSearching => '繼續檢索';

  @override
  String get responseIncomplete => '回答未完成';

  @override
  String get continueOrganizing => '繼續整理';

  @override
  String get retryThisTurn => '重試本輪';

  @override
  String get viewBudget => '檢視預算';

  @override
  String get retryWithCompatibleFormat => '相容格式重試';

  @override
  String get chooseProcessingMethod => '選擇處理方式';

  @override
  String get adjustMaterialsAndRetry => '調整資料後重試';

  @override
  String get restoreDefaultThinkingAndRetry => '恢復預設思考並重試';

  @override
  String get chooseVisionAssistant => '選擇視覺助手';

  @override
  String get editConfiguration => '修改配置';

  @override
  String vision(String p0) {
    return '讀圖 · $p0';
  }

  @override
  String sourceCount(int p0) {
    return '$p0 處來源';
  }

  @override
  String get copyResponse => '複製回答';

  @override
  String get originalMarkdownCopied => '已複製 Markdown 原文';

  @override
  String get responseStopped => '本次回答已停止';

  @override
  String get stoppedThePartialResponseReceivedIsShown => '已停止，以上是收到的部分回答';

  @override
  String get reviewDraftAndSend => '檢視草稿併傳送';

  @override
  String get writeAsEmail => '寫成郵件';

  @override
  String get connectingToModel => '正在連線模型…';

  @override
  String get viewingAnOlderVersion => '正在檢視歷史版本';

  @override
  String get backToLatest => '回到最新';

  @override
  String get textModel => '文字模型';

  @override
  String tapToCancelSync(String p0) {
    return '$p0 · 點選取消同步';
  }

  @override
  String get syncLatestEmailsInEachFolder => '同步各資料夾最新 50 封';

  @override
  String get searchEmails => '搜尋郵件';

  @override
  String get emailActions => '郵件操作';

  @override
  String get syncEmailsPerFolder => '同步郵件（每資料夾 50 封）';

  @override
  String get showAll => '顯示全部';

  @override
  String get showUnread => '只看未讀';

  @override
  String get subjectOrSender => '主題或發件人';

  @override
  String get runSearch => '執行搜尋';

  @override
  String get connectAnEmailAccountFirst => '先連線一個郵箱';

  @override
  String get supportsQqAndCustomEmailProviders => '支援 QQ、163 和自定義郵箱。';

  @override
  String get noLocalEmailsYet => '暫無本地郵件';

  @override
  String get pullDownToSyncRecentEmailsStartup => '下拉同步最新郵件，啟動時不會自動同步。';

  @override
  String analyzeSelectedEmails(String p0) {
    return '分析已選的 $p0 封郵件';
  }

  @override
  String get emailDetails => '郵件詳情';

  @override
  String get replyAndForward => '回覆與轉發';

  @override
  String get reply => '回覆';

  @override
  String get replyAll => '回覆全部';

  @override
  String get forward => '轉發';

  @override
  String get recipientDetails => '收件資訊';

  @override
  String toCc(String p0, String p1) {
    return '收件人：$p0\n抄送：$p1';
  }

  @override
  String get bodyAwaitingBackgroundSyncYouCanKeep => '正文待後臺同步，可繼續瀏覽其他郵件。';

  @override
  String attachments(String p0) {
    return '附件 · $p0';
  }

  @override
  String get tapAnAttachmentToPreviewSelectIt => '點按附件預覽，勾選用於 AI 分析';

  @override
  String get askAssistant => '交給助手';

  @override
  String get noDraftsYet => '還沒有草稿';

  @override
  String get writeYourOwnOrAskTheAssistant => '自己寫，或讓助手幫你起草。';

  @override
  String get configurationSaved => '配置已儲存';

  @override
  String get closeConfiguration => '關閉配置';

  @override
  String get actionFailed => '操作失敗';

  @override
  String get backToConfiguration => '返回配置';

  @override
  String get volcengineWebSearch => '火山聯網搜尋';

  @override
  String get bocha => '博查';

  @override
  String get systemPreferredCloudOptional => '系統優先，雲端可選';

  @override
  String get qwenCloudTranscription => '千問雲端識別';

  @override
  String get automaticSystemRecognitionFollowsDeviceLanguage =>
      '自動（系統識別跟隨手機語言）';

  @override
  String get chinese => '中文';

  @override
  String get searchProvider => '搜尋服務商';

  @override
  String get recognitionMode => '識別方式';

  @override
  String get speechLanguage => '語音語言';

  @override
  String get automatic => '自動';

  @override
  String get systemRecognitionNeedsNoApiKeyIf =>
      '系統識別不需要配置金鑰。手機沒有識別服務時，可使用下方千問 ASR。';

  @override
  String get usedOnlyWhenSmartSearchIsEnabled =>
      '僅在開啟智慧搜尋並提問時使用。搜尋服務只接收本輪問題提取的關鍵詞，不接收郵件、附件或歷史聊天。';

  @override
  String get qwenAsrBaseUrl => '千問 ASR Base URL';

  @override
  String get fullSearchApiUrl => '完整搜尋介面地址';

  @override
  String get leaveBlankToRetainTheSavedKey => '留空保留已儲存金鑰';

  @override
  String get showOrHideKey => '顯示或隱藏金鑰';

  @override
  String get asrModel => 'ASR 模型';

  @override
  String get forExampleQwenAsrFlash => '例如 qwen3-asr-flash';

  @override
  String get transcriptionFillsTheInputFieldOnlyReview =>
      '識別結果只填入輸入框；檢查後由你傳送。切換雲端需要重新錄音，最長 60 秒。';

  @override
  String get streamingUiStateIsOutOfSync => '流式介面狀態已失步，請重新開啟當前對話。';

  @override
  String get streamNotReceivedCompletelyReopenThisConversation =>
      '流式內容未完整接收，請重新開啟當前對話。';

  @override
  String get appLanguage => '語言';

  @override
  String get languageTitle => '選擇語言';

  @override
  String get languageDescription => '切換介面語言，郵件與對話內容保持原文。';
}
