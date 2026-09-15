import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @switchAccount.
  ///
  /// In zh, this message translates to:
  /// **'切换邮箱'**
  String get switchAccount;

  /// No description provided for @closeAccountPicker.
  ///
  /// In zh, this message translates to:
  /// **'关闭邮箱选择'**
  String get closeAccountPicker;

  /// MailPilot UI: lib/account_picker.dart
  ///
  /// In zh, this message translates to:
  /// **'切换邮箱，当前 {p0}'**
  String switchAccountCurrent(String p0);

  /// No description provided for @openWithAnotherApp.
  ///
  /// In zh, this message translates to:
  /// **'使用其他应用打开'**
  String get openWithAnotherApp;

  /// No description provided for @openInAnotherApp.
  ///
  /// In zh, this message translates to:
  /// **'其他应用打开'**
  String get openInAnotherApp;

  /// No description provided for @saveToDevice.
  ///
  /// In zh, this message translates to:
  /// **'保存到手机'**
  String get saveToDevice;

  /// No description provided for @couldNotStartRecording.
  ///
  /// In zh, this message translates to:
  /// **'无法开始录音'**
  String get couldNotStartRecording;

  /// No description provided for @addImage.
  ///
  /// In zh, this message translates to:
  /// **'添加图片'**
  String get addImage;

  /// No description provided for @addFile.
  ///
  /// In zh, this message translates to:
  /// **'添加文件'**
  String get addFile;

  /// No description provided for @selectEmails.
  ///
  /// In zh, this message translates to:
  /// **'选择邮件'**
  String get selectEmails;

  /// No description provided for @manageImportedMaterials.
  ///
  /// In zh, this message translates to:
  /// **'管理已导入资料'**
  String get manageImportedMaterials;

  /// No description provided for @deepThinking.
  ///
  /// In zh, this message translates to:
  /// **'深度思考'**
  String get deepThinking;

  /// No description provided for @editInput.
  ///
  /// In zh, this message translates to:
  /// **'修改输入'**
  String get editInput;

  /// No description provided for @cancelEdit.
  ///
  /// In zh, this message translates to:
  /// **'取消修改'**
  String get cancelEdit;

  /// MailPilot UI: lib/chat_composer.dart
  ///
  /// In zh, this message translates to:
  /// **'已选 {p0} 封邮件 · {p1} 个附件'**
  String selectedMaterialsCount(int p0, int p1);

  /// No description provided for @clearSelection.
  ///
  /// In zh, this message translates to:
  /// **'清空选择'**
  String get clearSelection;

  /// No description provided for @listeningUpToSeconds.
  ///
  /// In zh, this message translates to:
  /// **'正在聆听 · 最长 60 秒'**
  String get listeningUpToSeconds;

  /// No description provided for @transcribing.
  ///
  /// In zh, this message translates to:
  /// **'正在识别…'**
  String get transcribing;

  /// No description provided for @startingMicrophone.
  ///
  /// In zh, this message translates to:
  /// **'正在启动麦克风…'**
  String get startingMicrophone;

  /// No description provided for @recordAgainInCloudMode.
  ///
  /// In zh, this message translates to:
  /// **'云端重录'**
  String get recordAgainInCloudMode;

  /// No description provided for @cancelVoiceInput.
  ///
  /// In zh, this message translates to:
  /// **'取消语音输入'**
  String get cancelVoiceInput;

  /// No description provided for @askAboutSelectedMaterials.
  ///
  /// In zh, this message translates to:
  /// **'询问所选资料…'**
  String get askAboutSelectedMaterials;

  /// No description provided for @messageOrUseVoiceInput.
  ///
  /// In zh, this message translates to:
  /// **'发消息，或语音输入'**
  String get messageOrUseVoiceInput;

  /// No description provided for @smartSearch.
  ///
  /// In zh, this message translates to:
  /// **'智能搜索'**
  String get smartSearch;

  /// No description provided for @thinking.
  ///
  /// In zh, this message translates to:
  /// **'思考'**
  String get thinking;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @addAttachment.
  ///
  /// In zh, this message translates to:
  /// **'添加附件'**
  String get addAttachment;

  /// No description provided for @stopResponse.
  ///
  /// In zh, this message translates to:
  /// **'停止回答'**
  String get stopResponse;

  /// No description provided for @stopRecording.
  ///
  /// In zh, this message translates to:
  /// **'结束录音'**
  String get stopRecording;

  /// No description provided for @sendQuestion.
  ///
  /// In zh, this message translates to:
  /// **'发送问题'**
  String get sendQuestion;

  /// No description provided for @voiceInput.
  ///
  /// In zh, this message translates to:
  /// **'语音输入'**
  String get voiceInput;

  /// No description provided for @draftDeleted.
  ///
  /// In zh, this message translates to:
  /// **'草稿已删除'**
  String get draftDeleted;

  /// No description provided for @pleaseViewTheLatestVersion.
  ///
  /// In zh, this message translates to:
  /// **'请查看最新版本'**
  String get pleaseViewTheLatestVersion;

  /// No description provided for @from.
  ///
  /// In zh, this message translates to:
  /// **'发件人'**
  String get from;

  /// No description provided for @to.
  ///
  /// In zh, this message translates to:
  /// **'收件人'**
  String get to;

  /// No description provided for @cc.
  ///
  /// In zh, this message translates to:
  /// **'抄送'**
  String get cc;

  /// No description provided for @bcc.
  ///
  /// In zh, this message translates to:
  /// **'密送'**
  String get bcc;

  /// No description provided for @notEntered.
  ///
  /// In zh, this message translates to:
  /// **'尚未填写'**
  String get notEntered;

  /// No description provided for @noSubject.
  ///
  /// In zh, this message translates to:
  /// **'（无主题）'**
  String get noSubject;

  /// No description provided for @afterReviewingConfirmSendingOrTapThe.
  ///
  /// In zh, this message translates to:
  /// **'核对后回复“确认发送”，或点击下方按钮。'**
  String get afterReviewingConfirmSendingOrTapThe;

  /// No description provided for @confirmSend.
  ///
  /// In zh, this message translates to:
  /// **'确认发送'**
  String get confirmSend;

  /// No description provided for @addRecipient.
  ///
  /// In zh, this message translates to:
  /// **'补充收件人'**
  String get addRecipient;

  /// No description provided for @viewLatestVersion.
  ///
  /// In zh, this message translates to:
  /// **'查看最新版本'**
  String get viewLatestVersion;

  /// No description provided for @reviewAndEdit.
  ///
  /// In zh, this message translates to:
  /// **'查看并修改'**
  String get reviewAndEdit;

  /// No description provided for @editEmail.
  ///
  /// In zh, this message translates to:
  /// **'编辑邮件'**
  String get editEmail;

  /// No description provided for @jumpToLatestMessage.
  ///
  /// In zh, this message translates to:
  /// **'回到最新消息'**
  String get jumpToLatestMessage;

  /// No description provided for @inbox.
  ///
  /// In zh, this message translates to:
  /// **'收件箱'**
  String get inbox;

  /// No description provided for @sent.
  ///
  /// In zh, this message translates to:
  /// **'已发送'**
  String get sent;

  /// No description provided for @drafts.
  ///
  /// In zh, this message translates to:
  /// **'草稿'**
  String get drafts;

  /// No description provided for @deleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除'**
  String get deleted;

  /// No description provided for @spam.
  ///
  /// In zh, this message translates to:
  /// **'垃圾邮件'**
  String get spam;

  /// No description provided for @archive.
  ///
  /// In zh, this message translates to:
  /// **'归档'**
  String get archive;

  /// No description provided for @mailFolders.
  ///
  /// In zh, this message translates to:
  /// **'邮件文件夹'**
  String get mailFolders;

  /// No description provided for @refreshFolders.
  ///
  /// In zh, this message translates to:
  /// **'刷新文件夹'**
  String get refreshFolders;

  /// MailPilot UI: lib/common.dart
  ///
  /// In zh, this message translates to:
  /// **'文件夹刷新失败，已保留本地列表。{p0}'**
  String couldNotRefreshFoldersLocalListRetained(String p0);

  /// No description provided for @unreadOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅显示未读'**
  String get unreadOnly;

  /// No description provided for @deleteThisDraft.
  ///
  /// In zh, this message translates to:
  /// **'删除这份草稿？'**
  String get deleteThisDraft;

  /// No description provided for @onlyTheLocalDraftIsDeletedChats.
  ///
  /// In zh, this message translates to:
  /// **'仅删除本地草稿，聊天记录和服务器邮件保留。'**
  String get onlyTheLocalDraftIsDeletedChats;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @draftActions.
  ///
  /// In zh, this message translates to:
  /// **'草稿操作'**
  String get draftActions;

  /// No description provided for @rewrite.
  ///
  /// In zh, this message translates to:
  /// **'重新拟写'**
  String get rewrite;

  /// No description provided for @deleteDraft.
  ///
  /// In zh, this message translates to:
  /// **'删除草稿'**
  String get deleteDraft;

  /// No description provided for @recipientEmail.
  ///
  /// In zh, this message translates to:
  /// **'目标邮箱'**
  String get recipientEmail;

  /// No description provided for @separateMultipleAddressesWithCommas.
  ///
  /// In zh, this message translates to:
  /// **'多个地址用英文逗号分隔'**
  String get separateMultipleAddressesWithCommas;

  /// No description provided for @afterSavingReviewTheNewConfirmationCard.
  ///
  /// In zh, this message translates to:
  /// **'保存后展示新确认卡片，由你核对并发送。'**
  String get afterSavingReviewTheNewConfirmationCard;

  /// No description provided for @saveRecipients.
  ///
  /// In zh, this message translates to:
  /// **'保存收件人'**
  String get saveRecipients;

  /// No description provided for @draftAnswerPrompt.
  ///
  /// In zh, this message translates to:
  /// **'请将本次对话中这条回答涉及的内容写成正式邮件：'**
  String get draftAnswerPrompt;

  /// No description provided for @draftAnswerPromptSuffix.
  ///
  /// In zh, this message translates to:
  /// **'供我检查并确认发送。'**
  String get draftAnswerPromptSuffix;

  /// No description provided for @turnThisAnswerIntoAnEmail.
  ///
  /// In zh, this message translates to:
  /// **'将这条回答写成邮件'**
  String get turnThisAnswerIntoAnEmail;

  /// No description provided for @viewOriginalOfOlderVersion.
  ///
  /// In zh, this message translates to:
  /// **'查看旧版原文'**
  String get viewOriginalOfOlderVersion;

  /// No description provided for @messageActions.
  ///
  /// In zh, this message translates to:
  /// **'消息操作'**
  String get messageActions;

  /// No description provided for @needsVerification.
  ///
  /// In zh, this message translates to:
  /// **'待核实'**
  String get needsVerification;

  /// No description provided for @sending.
  ///
  /// In zh, this message translates to:
  /// **'发送中'**
  String get sending;

  /// No description provided for @sendFailed.
  ///
  /// In zh, this message translates to:
  /// **'发送失败'**
  String get sendFailed;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// MailPilot UI: lib/common.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0} 个附件'**
  String attachmentCount(int p0);

  /// MailPilot UI: lib/common.dart
  ///
  /// In zh, this message translates to:
  /// **'选择 {p0}'**
  String select(String p0);

  /// No description provided for @emailAndModelConnectionsRequireAndroidUse.
  ///
  /// In zh, this message translates to:
  /// **'邮箱与模型连接需要 Android 设备，请使用界面预览入口。'**
  String get emailAndModelConnectionsRequireAndroidUse;

  /// No description provided for @notConnectedToTheAndroidMailService.
  ///
  /// In zh, this message translates to:
  /// **'未连接到 Android 邮件服务。请完全关闭后重新打开最新版 APK；浏览器和 Widget Preview 请使用界面预览入口。'**
  String get notConnectedToTheAndroidMailService;

  /// No description provided for @actionIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'操作未完成'**
  String get actionIncomplete;

  /// No description provided for @thisFeatureIsUnavailableInTheCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前运行环境不支持此功能'**
  String get thisFeatureIsUnavailableInTheCurrent;

  /// No description provided for @pin.
  ///
  /// In zh, this message translates to:
  /// **'置顶'**
  String get pin;

  /// No description provided for @today.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get yesterday;

  /// No description provided for @previousDays.
  ///
  /// In zh, this message translates to:
  /// **'7 天内'**
  String get previousDays;

  /// No description provided for @previousDays86.
  ///
  /// In zh, this message translates to:
  /// **'30 天内'**
  String get previousDays86;

  /// MailPilot UI: lib/conversation_drawer.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0} 年 {p1} 月 {p2} 日'**
  String olderConversationDate(String p0, String p1, String p2);

  /// No description provided for @loadingConversations.
  ///
  /// In zh, this message translates to:
  /// **'正在加载对话'**
  String get loadingConversations;

  /// No description provided for @noMatchingConversations.
  ///
  /// In zh, this message translates to:
  /// **'没有找到相关对话'**
  String get noMatchingConversations;

  /// No description provided for @yourConversationsWillAppearHere.
  ///
  /// In zh, this message translates to:
  /// **'对话会保存在这里'**
  String get yourConversationsWillAppearHere;

  /// No description provided for @tryShorterKeywordsOrClearTheSearch.
  ///
  /// In zh, this message translates to:
  /// **'试试更短的关键词，或清空搜索。'**
  String get tryShorterKeywordsOrClearTheSearch;

  /// No description provided for @startAChatAndComeBackAnytime.
  ///
  /// In zh, this message translates to:
  /// **'开始聊天后，随时回来继续。'**
  String get startAChatAndComeBackAnytime;

  /// No description provided for @clearSearch.
  ///
  /// In zh, this message translates to:
  /// **'清空搜索'**
  String get clearSearch;

  /// No description provided for @startAConversation.
  ///
  /// In zh, this message translates to:
  /// **'开始对话'**
  String get startAConversation;

  /// No description provided for @couldNotLoadConversationsTapToRetry.
  ///
  /// In zh, this message translates to:
  /// **'会话加载失败，点击重试'**
  String get couldNotLoadConversationsTapToRetry;

  /// No description provided for @renameConversation.
  ///
  /// In zh, this message translates to:
  /// **'重命名对话'**
  String get renameConversation;

  /// No description provided for @enterConversationName.
  ///
  /// In zh, this message translates to:
  /// **'输入对话名称'**
  String get enterConversationName;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// MailPilot UI: lib/conversation_drawer.dart
  ///
  /// In zh, this message translates to:
  /// **'删除 {p0} 个对话？'**
  String deleteConversationCount(int p0);

  /// No description provided for @chatsSummariesAndAnalysisCachesForThese.
  ///
  /// In zh, this message translates to:
  /// **'聊天记录、摘要及这些会话的分析缓存会被删除，邮箱邮件和草稿保留。'**
  String get chatsSummariesAndAnalysisCachesForThese;

  /// No description provided for @rename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get rename;

  /// No description provided for @unpin.
  ///
  /// In zh, this message translates to:
  /// **'取消置顶'**
  String get unpin;

  /// No description provided for @selectMultiple.
  ///
  /// In zh, this message translates to:
  /// **'多选'**
  String get selectMultiple;

  /// MailPilot UI: lib/conversation_drawer.dart
  ///
  /// In zh, this message translates to:
  /// **'已选 {p0} 个对话'**
  String selectedConversationCount(int p0);

  /// No description provided for @exitSelection.
  ///
  /// In zh, this message translates to:
  /// **'退出多选'**
  String get exitSelection;

  /// No description provided for @closeSidebar.
  ///
  /// In zh, this message translates to:
  /// **'关闭侧栏'**
  String get closeSidebar;

  /// No description provided for @searchConversations.
  ///
  /// In zh, this message translates to:
  /// **'搜索对话内容…'**
  String get searchConversations;

  /// No description provided for @conversationSummary.
  ///
  /// In zh, this message translates to:
  /// **'对话摘要'**
  String get conversationSummary;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'正在加载…'**
  String get loading;

  /// No description provided for @loadMore.
  ///
  /// In zh, this message translates to:
  /// **'加载更多'**
  String get loadMore;

  /// No description provided for @selectConversations.
  ///
  /// In zh, this message translates to:
  /// **'多选对话'**
  String get selectConversations;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @thisConversationSSummary.
  ///
  /// In zh, this message translates to:
  /// **'本次对话摘要'**
  String get thisConversationSSummary;

  /// MailPilot UI: lib/conversation_summary.dart
  ///
  /// In zh, this message translates to:
  /// **'已整理 {p0} 条较早消息'**
  String summarizedMessageCount(int p0);

  /// No description provided for @closeSummary.
  ///
  /// In zh, this message translates to:
  /// **'关闭对话摘要'**
  String get closeSummary;

  /// No description provided for @originalMessagesAreRetainedYouCanAdd.
  ///
  /// In zh, this message translates to:
  /// **'原始聊天仍保留，可继续补充或纠正。'**
  String get originalMessagesAreRetainedYouCanAdd;

  /// No description provided for @noSummaryForThisConversationYet.
  ///
  /// In zh, this message translates to:
  /// **'当前对话暂无摘要。'**
  String get noSummaryForThisConversationYet;

  /// No description provided for @conversationChangedPleaseReopenTheSummary.
  ///
  /// In zh, this message translates to:
  /// **'对话已切换，请重新打开摘要。'**
  String get conversationChangedPleaseReopenTheSummary;

  /// No description provided for @draftingReadOnlyPreview.
  ///
  /// In zh, this message translates to:
  /// **'正在起草 · 只读预览'**
  String get draftingReadOnlyPreview;

  /// No description provided for @incompleteCannotSend.
  ///
  /// In zh, this message translates to:
  /// **'未完成 · 不能发送'**
  String get incompleteCannotSend;

  /// No description provided for @draftingEmail.
  ///
  /// In zh, this message translates to:
  /// **'邮件起草'**
  String get draftingEmail;

  /// No description provided for @generatingResponse.
  ///
  /// In zh, this message translates to:
  /// **'生成回答'**
  String get generatingResponse;

  /// No description provided for @readingImages.
  ///
  /// In zh, this message translates to:
  /// **'读取图片'**
  String get readingImages;

  /// No description provided for @preparingMaterials.
  ///
  /// In zh, this message translates to:
  /// **'准备资料'**
  String get preparingMaterials;

  /// No description provided for @generatingContent.
  ///
  /// In zh, this message translates to:
  /// **'生成内容'**
  String get generatingContent;

  /// No description provided for @parsingModelAction.
  ///
  /// In zh, this message translates to:
  /// **'解析模型操作'**
  String get parsingModelAction;

  /// No description provided for @organizingExistingResults.
  ///
  /// In zh, this message translates to:
  /// **'整理已有结果'**
  String get organizingExistingResults;

  /// No description provided for @organizingContext.
  ///
  /// In zh, this message translates to:
  /// **'整理上下文'**
  String get organizingContext;

  /// No description provided for @webSearch.
  ///
  /// In zh, this message translates to:
  /// **'联网搜索'**
  String get webSearch;

  /// No description provided for @currentRequest.
  ///
  /// In zh, this message translates to:
  /// **'本轮请求'**
  String get currentRequest;

  /// No description provided for @requestId.
  ///
  /// In zh, this message translates to:
  /// **'请求标识'**
  String get requestId;

  /// No description provided for @serverId.
  ///
  /// In zh, this message translates to:
  /// **'服务端标识'**
  String get serverId;

  /// No description provided for @httpStatus.
  ///
  /// In zh, this message translates to:
  /// **'HTTP 状态'**
  String get httpStatus;

  /// No description provided for @finishReason.
  ///
  /// In zh, this message translates to:
  /// **'结束原因'**
  String get finishReason;

  /// No description provided for @exceptionType.
  ///
  /// In zh, this message translates to:
  /// **'异常类型'**
  String get exceptionType;

  /// No description provided for @validationResult.
  ///
  /// In zh, this message translates to:
  /// **'校验结果'**
  String get validationResult;

  /// No description provided for @requestBudgetAndDiagnostics.
  ///
  /// In zh, this message translates to:
  /// **'本轮预算与诊断'**
  String get requestBudgetAndDiagnostics;

  /// No description provided for @connectionDiagnostics.
  ///
  /// In zh, this message translates to:
  /// **'连接诊断'**
  String get connectionDiagnostics;

  /// No description provided for @requestRecordsForThisTurn.
  ///
  /// In zh, this message translates to:
  /// **'本轮请求记录'**
  String get requestRecordsForThisTurn;

  /// No description provided for @closeDiagnostics.
  ///
  /// In zh, this message translates to:
  /// **'关闭连接诊断'**
  String get closeDiagnostics;

  /// No description provided for @processingStage.
  ///
  /// In zh, this message translates to:
  /// **'处理阶段'**
  String get processingStage;

  /// No description provided for @model.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get model;

  /// No description provided for @apiHost.
  ///
  /// In zh, this message translates to:
  /// **'接口主机'**
  String get apiHost;

  /// No description provided for @imageProcessing.
  ///
  /// In zh, this message translates to:
  /// **'图片处理'**
  String get imageProcessing;

  /// No description provided for @fullTextAndImageResponse.
  ///
  /// In zh, this message translates to:
  /// **'完整图文回答'**
  String get fullTextAndImageResponse;

  /// No description provided for @visionAssistantReading.
  ///
  /// In zh, this message translates to:
  /// **'视觉助手读取'**
  String get visionAssistantReading;

  /// No description provided for @batchProcessingSelectedForThisTurn.
  ///
  /// In zh, this message translates to:
  /// **'本轮选择分批'**
  String get batchProcessingSelectedForThisTurn;

  /// No description provided for @reusingPreviousAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'复用此前分析'**
  String get reusingPreviousAnalysis;

  /// No description provided for @requestsWithImages.
  ///
  /// In zh, this message translates to:
  /// **'带图请求'**
  String get requestsWithImages;

  /// MailPilot UI: lib/draft_streaming_preview.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0} 次'**
  String requestCount(int p0);

  /// No description provided for @totalImagesUploaded.
  ///
  /// In zh, this message translates to:
  /// **'累计上传图片'**
  String get totalImagesUploaded;

  /// MailPilot UI: lib/draft_streaming_preview.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0} 张'**
  String imageCount(int p0);

  /// No description provided for @reusedImages.
  ///
  /// In zh, this message translates to:
  /// **'复用图片'**
  String get reusedImages;

  /// No description provided for @batchingReason.
  ///
  /// In zh, this message translates to:
  /// **'分批原因'**
  String get batchingReason;

  /// No description provided for @estimatedInput.
  ///
  /// In zh, this message translates to:
  /// **'预计输入'**
  String get estimatedInput;

  /// No description provided for @availableInputBudget.
  ///
  /// In zh, this message translates to:
  /// **'可用输入预算'**
  String get availableInputBudget;

  /// No description provided for @configuredContext.
  ///
  /// In zh, this message translates to:
  /// **'配置上下文'**
  String get configuredContext;

  /// No description provided for @outputReserve.
  ///
  /// In zh, this message translates to:
  /// **'输出预留'**
  String get outputReserve;

  /// No description provided for @thinkingReserve.
  ///
  /// In zh, this message translates to:
  /// **'思考预留'**
  String get thinkingReserve;

  /// No description provided for @suggestedSummaryLength.
  ///
  /// In zh, this message translates to:
  /// **'建议摘要长度'**
  String get suggestedSummaryLength;

  /// No description provided for @summaryBudgetLimit.
  ///
  /// In zh, this message translates to:
  /// **'摘要可用上限'**
  String get summaryBudgetLimit;

  /// No description provided for @currentSummaryEstimate.
  ///
  /// In zh, this message translates to:
  /// **'当前摘要估算'**
  String get currentSummaryEstimate;

  /// No description provided for @localEstimatesMayDifferFromProviderMetering.
  ///
  /// In zh, this message translates to:
  /// **'本地估算，不等同于厂商计量。95% 触发整理，60% 为整理目标。'**
  String get localEstimatesMayDifferFromProviderMetering;

  /// No description provided for @timeToFirstChunk.
  ///
  /// In zh, this message translates to:
  /// **'首包耗时'**
  String get timeToFirstChunk;

  /// No description provided for @lastChunkReceived.
  ///
  /// In zh, this message translates to:
  /// **'末包到达'**
  String get lastChunkReceived;

  /// No description provided for @requestDuration.
  ///
  /// In zh, this message translates to:
  /// **'请求用时'**
  String get requestDuration;

  /// No description provided for @technicalDetails.
  ///
  /// In zh, this message translates to:
  /// **'技术详情'**
  String get technicalDetails;

  /// No description provided for @requestIdsAndExceptionInformation.
  ///
  /// In zh, this message translates to:
  /// **'请求标识与异常信息'**
  String get requestIdsAndExceptionInformation;

  /// No description provided for @convertedToEmailBodyReviewBeforeSaving.
  ///
  /// In zh, this message translates to:
  /// **'已转换为邮件正文，请检查后保存'**
  String get convertedToEmailBodyReviewBeforeSaving;

  /// No description provided for @conversionFailedOriginalTextRetained.
  ///
  /// In zh, this message translates to:
  /// **'正文转换失败，原文已保留'**
  String get conversionFailedOriginalTextRetained;

  /// No description provided for @discardUnsavedChanges.
  ///
  /// In zh, this message translates to:
  /// **'放弃未保存的修改？'**
  String get discardUnsavedChanges;

  /// No description provided for @savedDraftsAreRetained.
  ///
  /// In zh, this message translates to:
  /// **'已保存的草稿会保留。'**
  String get savedDraftsAreRetained;

  /// No description provided for @discardChanges.
  ///
  /// In zh, this message translates to:
  /// **'放弃修改'**
  String get discardChanges;

  /// No description provided for @deleteThisLocalRecord.
  ///
  /// In zh, this message translates to:
  /// **'删除这条本地记录？'**
  String get deleteThisLocalRecord;

  /// No description provided for @serverEmailsAreRetained.
  ///
  /// In zh, this message translates to:
  /// **'服务器邮件会保留。'**
  String get serverEmailsAreRetained;

  /// No description provided for @composeEmail.
  ///
  /// In zh, this message translates to:
  /// **'写邮件'**
  String get composeEmail;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @moreEmailActions.
  ///
  /// In zh, this message translates to:
  /// **'更多邮件操作'**
  String get moreEmailActions;

  /// No description provided for @saveChangesAndRewrite.
  ///
  /// In zh, this message translates to:
  /// **'保存修改后重新拟写'**
  String get saveChangesAndRewrite;

  /// No description provided for @convertMarkdownToBodyText.
  ///
  /// In zh, this message translates to:
  /// **'将 Markdown 转为正文'**
  String get convertMarkdownToBodyText;

  /// No description provided for @sendingAccount.
  ///
  /// In zh, this message translates to:
  /// **'发件邮箱'**
  String get sendingAccount;

  /// No description provided for @subject.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get subject;

  /// No description provided for @body.
  ///
  /// In zh, this message translates to:
  /// **'正文'**
  String get body;

  /// No description provided for @sendAsThePlainTextShownHere.
  ///
  /// In zh, this message translates to:
  /// **'按此处显示的纯文本发送'**
  String get sendAsThePlainTextShownHere;

  /// No description provided for @ccBcc.
  ///
  /// In zh, this message translates to:
  /// **'抄送 / 密送'**
  String get ccBcc;

  /// MailPilot UI: lib/editor.dart
  ///
  /// In zh, this message translates to:
  /// **'移除 {p0}'**
  String remove(String p0);

  /// No description provided for @firstCheckTheServerSSentFolder.
  ///
  /// In zh, this message translates to:
  /// **'请先核对服务器的已发送记录和收件情况。'**
  String get firstCheckTheServerSSentFolder;

  /// No description provided for @verifiedThatSendingSucceeded.
  ///
  /// In zh, this message translates to:
  /// **'已经核实发送成功？'**
  String get verifiedThatSendingSucceeded;

  /// No description provided for @thisOnlyUpdatesTheLocalRecord.
  ///
  /// In zh, this message translates to:
  /// **'此操作只更新本地记录。'**
  String get thisOnlyUpdatesTheLocalRecord;

  /// No description provided for @verifiedSentSuccessfully.
  ///
  /// In zh, this message translates to:
  /// **'已核实：发送成功'**
  String get verifiedSentSuccessfully;

  /// No description provided for @confirmedThatNoRecipientsReceivedIt.
  ///
  /// In zh, this message translates to:
  /// **'确认所有收件人都未收到？'**
  String get confirmedThatNoRecipientsReceivedIt;

  /// No description provided for @restoreTheDraftToReviewAndSend.
  ///
  /// In zh, this message translates to:
  /// **'恢复草稿后可重新审核发送。若有部分收件人已收到，请先修改收件人。'**
  String get restoreTheDraftToReviewAndSend;

  /// No description provided for @restoreDraft.
  ///
  /// In zh, this message translates to:
  /// **'恢复草稿'**
  String get restoreDraft;

  /// No description provided for @verifiedNotSent.
  ///
  /// In zh, this message translates to:
  /// **'已核实：未发送'**
  String get verifiedNotSent;

  /// No description provided for @confirmSendingInChat.
  ///
  /// In zh, this message translates to:
  /// **'在聊天中确认发送'**
  String get confirmSendingInChat;

  /// No description provided for @confirmBeforeSending.
  ///
  /// In zh, this message translates to:
  /// **'发送前确认'**
  String get confirmBeforeSending;

  /// No description provided for @pleaseReviewTheFollowing.
  ///
  /// In zh, this message translates to:
  /// **'请核对以下内容'**
  String get pleaseReviewTheFollowing;

  /// No description provided for @accountDeleted.
  ///
  /// In zh, this message translates to:
  /// **'账号已删除'**
  String get accountDeleted;

  /// No description provided for @couldNotReadAttachment.
  ///
  /// In zh, this message translates to:
  /// **'附件读取失败'**
  String get couldNotReadAttachment;

  /// No description provided for @couldNotReadImagePleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'图片未能读取，请重试'**
  String get couldNotReadImagePleaseRetry;

  /// No description provided for @couldNotReadPagePleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'页面未能读取，请重试'**
  String get couldNotReadPagePleaseRetry;

  /// No description provided for @reload.
  ///
  /// In zh, this message translates to:
  /// **'重新加载'**
  String get reload;

  /// No description provided for @referencedMaterial.
  ///
  /// In zh, this message translates to:
  /// **'引用资料'**
  String get referencedMaterial;

  /// No description provided for @formattedView.
  ///
  /// In zh, this message translates to:
  /// **'排版阅读'**
  String get formattedView;

  /// No description provided for @viewOriginal.
  ///
  /// In zh, this message translates to:
  /// **'查看原文'**
  String get viewOriginal;

  /// No description provided for @theFollowingWasGeneratedByAVision.
  ///
  /// In zh, this message translates to:
  /// **'以下内容由视觉模型阅读图片后生成，可结合原图核对。'**
  String get theFollowingWasGeneratedByAVision;

  /// No description provided for @previousPage.
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get nextPage;

  /// No description provided for @loadingReferencedMaterial.
  ///
  /// In zh, this message translates to:
  /// **'正在加载引用资料…'**
  String get loadingReferencedMaterial;

  /// No description provided for @selectedImageOrPdfPagePinchTo.
  ///
  /// In zh, this message translates to:
  /// **'所选图片附件或 PDF 页面，可双指缩放'**
  String get selectedImageOrPdfPagePinchTo;

  /// No description provided for @imageUnavailableRetryOrOpenWithAnother.
  ///
  /// In zh, this message translates to:
  /// **'图片无法显示，可重试或用其他应用打开。'**
  String get imageUnavailableRetryOrOpenWithAnother;

  /// No description provided for @pinchToZoomSavingAndExternalOpening.
  ///
  /// In zh, this message translates to:
  /// **'双指缩放查看 · 保存和外部打开使用原始附件'**
  String get pinchToZoomSavingAndExternalOpening;

  /// No description provided for @mail.
  ///
  /// In zh, this message translates to:
  /// **'邮件'**
  String get mail;

  /// No description provided for @myEmails.
  ///
  /// In zh, this message translates to:
  /// **'我的邮件'**
  String get myEmails;

  /// No description provided for @draftsAndSending.
  ///
  /// In zh, this message translates to:
  /// **'草稿与发送'**
  String get draftsAndSending;

  /// No description provided for @emailAccounts.
  ///
  /// In zh, this message translates to:
  /// **'邮箱账户'**
  String get emailAccounts;

  /// No description provided for @addEmailAccount.
  ///
  /// In zh, this message translates to:
  /// **'添加邮箱'**
  String get addEmailAccount;

  /// No description provided for @modelsAndServices.
  ///
  /// In zh, this message translates to:
  /// **'模型与服务'**
  String get modelsAndServices;

  /// No description provided for @defaultModel.
  ///
  /// In zh, this message translates to:
  /// **'默认模型'**
  String get defaultModel;

  /// No description provided for @visionAssistant.
  ///
  /// In zh, this message translates to:
  /// **'视觉助手'**
  String get visionAssistant;

  /// No description provided for @addModel.
  ///
  /// In zh, this message translates to:
  /// **'添加模型'**
  String get addModel;

  /// No description provided for @automaticCurrentModelPreferred.
  ///
  /// In zh, this message translates to:
  /// **'自动选择 · 当前模型优先'**
  String get automaticCurrentModelPreferred;

  /// MailPilot UI: lib/forms.dart
  ///
  /// In zh, this message translates to:
  /// **'固定助手 · {p0}'**
  String fixedAssistant(String p0);

  /// No description provided for @configurationUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'配置已失效'**
  String get configurationUnavailable;

  /// No description provided for @chooseAutomatically.
  ///
  /// In zh, this message translates to:
  /// **'自动选择'**
  String get chooseAutomatically;

  /// No description provided for @searchAndVoice.
  ///
  /// In zh, this message translates to:
  /// **'搜索与语音'**
  String get searchAndVoice;

  /// No description provided for @webServicesAndSpeechRecognition.
  ///
  /// In zh, this message translates to:
  /// **'联网服务、语音识别'**
  String get webServicesAndSpeechRecognition;

  /// No description provided for @preferences.
  ///
  /// In zh, this message translates to:
  /// **'偏好设置'**
  String get preferences;

  /// No description provided for @contextOrganization.
  ///
  /// In zh, this message translates to:
  /// **'上下文整理'**
  String get contextOrganization;

  /// No description provided for @fastOrganizationResponseSettingsUnchanged.
  ///
  /// In zh, this message translates to:
  /// **'快速整理 · 正式回答不变'**
  String get fastOrganizationResponseSettingsUnchanged;

  /// No description provided for @followCurrentThinkingMode.
  ///
  /// In zh, this message translates to:
  /// **'跟随当前思考模式'**
  String get followCurrentThinkingMode;

  /// No description provided for @fastOrganizationNonThinkingModeOnSupported.
  ///
  /// In zh, this message translates to:
  /// **'快速整理（支持的接口使用非思考模式）'**
  String get fastOrganizationNonThinkingModeOnSupported;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearance;

  /// No description provided for @systemDefault.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get systemDefault;

  /// No description provided for @light.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get dark;

  /// No description provided for @backgroundSync.
  ///
  /// In zh, this message translates to:
  /// **'后台同步'**
  String get backgroundSync;

  /// No description provided for @off.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get off;

  /// No description provided for @hourly.
  ///
  /// In zh, this message translates to:
  /// **'每小时'**
  String get hourly;

  /// No description provided for @onceADay.
  ///
  /// In zh, this message translates to:
  /// **'每天一次'**
  String get onceADay;

  /// MailPilot UI: lib/forms.dart
  ///
  /// In zh, this message translates to:
  /// **'每 {p0} 分钟'**
  String everyMinutes(String p0);

  /// No description provided for @everyMinutes242.
  ///
  /// In zh, this message translates to:
  /// **'每 30 分钟'**
  String get everyMinutes242;

  /// No description provided for @clearCacheAndChats.
  ///
  /// In zh, this message translates to:
  /// **'清理缓存与聊天记录'**
  String get clearCacheAndChats;

  /// No description provided for @clearLocalCache.
  ///
  /// In zh, this message translates to:
  /// **'清理本地缓存？'**
  String get clearLocalCache;

  /// No description provided for @downloadedAttachmentsPagePreviewsAllChatsAnd.
  ///
  /// In zh, this message translates to:
  /// **'下载的附件、页面预览、全部聊天记录和上下文摘要会被清理。邮箱、模型配置及草稿附件会保留。'**
  String get downloadedAttachmentsPagePreviewsAllChatsAnd;

  /// MailPilot UI: lib/forms.dart
  ///
  /// In zh, this message translates to:
  /// **'MailPilot {p0}\n每次发送邮件，都由你确认。'**
  String versionAndSendConfirmation(String p0);

  /// No description provided for @custom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get custom;

  /// No description provided for @appPassword.
  ///
  /// In zh, this message translates to:
  /// **'授权码'**
  String get appPassword;

  /// No description provided for @alibabaBusiness.
  ///
  /// In zh, this message translates to:
  /// **'阿里企业'**
  String get alibabaBusiness;

  /// No description provided for @passwordSecurityPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码／安全密码'**
  String get passwordSecurityPassword;

  /// No description provided for @alibabaPersonal.
  ///
  /// In zh, this message translates to:
  /// **'阿里个人'**
  String get alibabaPersonal;

  /// No description provided for @emailPassword.
  ///
  /// In zh, this message translates to:
  /// **'邮箱密码'**
  String get emailPassword;

  /// No description provided for @passwordAppPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码／授权码'**
  String get passwordAppPassword;

  /// No description provided for @leaveBlankToKeepSavedCredentials.
  ///
  /// In zh, this message translates to:
  /// **'留空保留已保存的凭据。'**
  String get leaveBlankToKeepSavedCredentials;

  /// No description provided for @theAdministratorMustAllowThirdPartyClients.
  ///
  /// In zh, this message translates to:
  /// **'管理员需允许第三方客户端和 IMAP/SMTP。已启用安全密码时，请填写三方客户端安全密码。'**
  String get theAdministratorMustAllowThirdPartyClients;

  /// No description provided for @enterTheFullEmailAddressAndPassword.
  ///
  /// In zh, this message translates to:
  /// **'填写完整邮箱地址及邮箱密码；请确认已允许客户端访问。'**
  String get enterTheFullEmailAddressAndPassword;

  /// No description provided for @enableImapSmtpInYourEmailSettings.
  ///
  /// In zh, this message translates to:
  /// **'在邮箱设置中开启 IMAP/SMTP 后获取授权码。'**
  String get enableImapSmtpInYourEmailSettings;

  /// No description provided for @useTheEmailPasswordOrAppPassword.
  ///
  /// In zh, this message translates to:
  /// **'填写服务商要求的邮箱密码或客户端授权码。'**
  String get useTheEmailPasswordOrAppPassword;

  /// No description provided for @hideCredentials.
  ///
  /// In zh, this message translates to:
  /// **'隐藏凭据'**
  String get hideCredentials;

  /// No description provided for @showCredentials.
  ///
  /// In zh, this message translates to:
  /// **'显示凭据'**
  String get showCredentials;

  /// No description provided for @connectEmail.
  ///
  /// In zh, this message translates to:
  /// **'连接邮箱'**
  String get connectEmail;

  /// No description provided for @emailSettings.
  ///
  /// In zh, this message translates to:
  /// **'邮箱设置'**
  String get emailSettings;

  /// MailPilot UI: lib/forms.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0} 邮箱'**
  String mail263(String p0);

  /// MailPilot UI: lib/forms.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0}邮箱'**
  String mail264(String p0);

  /// No description provided for @emailAddress.
  ///
  /// In zh, this message translates to:
  /// **'邮箱地址'**
  String get emailAddress;

  /// No description provided for @senderNameOptional.
  ///
  /// In zh, this message translates to:
  /// **'发件人名称（选填）'**
  String get senderNameOptional;

  /// No description provided for @emailSetupGuide.
  ///
  /// In zh, this message translates to:
  /// **'如何配置邮箱'**
  String get emailSetupGuide;

  /// No description provided for @connectionDetailsAndInstructions.
  ///
  /// In zh, this message translates to:
  /// **'连接参数与填写说明'**
  String get connectionDetailsAndInstructions;

  /// MailPilot UI: lib/forms.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0} · 官方指引'**
  String officialGuide(String p0);

  /// No description provided for @serverAndAdvancedSettings.
  ///
  /// In zh, this message translates to:
  /// **'服务器与高级设置'**
  String get serverAndAdvancedSettings;

  /// No description provided for @accountLabel.
  ///
  /// In zh, this message translates to:
  /// **'账号备注'**
  String get accountLabel;

  /// No description provided for @loginUsername.
  ///
  /// In zh, this message translates to:
  /// **'登录用户名'**
  String get loginUsername;

  /// No description provided for @leaveBlankToUseTheFullEmail.
  ///
  /// In zh, this message translates to:
  /// **'留空使用完整邮箱地址'**
  String get leaveBlankToUseTheFullEmail;

  /// No description provided for @imapHost.
  ///
  /// In zh, this message translates to:
  /// **'IMAP 主机'**
  String get imapHost;

  /// No description provided for @imapPort.
  ///
  /// In zh, this message translates to:
  /// **'IMAP 端口'**
  String get imapPort;

  /// No description provided for @incomingEncryption.
  ///
  /// In zh, this message translates to:
  /// **'收信加密'**
  String get incomingEncryption;

  /// No description provided for @smtpHost.
  ///
  /// In zh, this message translates to:
  /// **'SMTP 主机'**
  String get smtpHost;

  /// No description provided for @smtpPort.
  ///
  /// In zh, this message translates to:
  /// **'SMTP 端口'**
  String get smtpPort;

  /// No description provided for @outgoingEncryption.
  ///
  /// In zh, this message translates to:
  /// **'发信加密'**
  String get outgoingEncryption;

  /// No description provided for @testConnection.
  ///
  /// In zh, this message translates to:
  /// **'测试连接'**
  String get testConnection;

  /// No description provided for @saveAccount.
  ///
  /// In zh, this message translates to:
  /// **'保存邮箱'**
  String get saveAccount;

  /// No description provided for @deleteThisAccount.
  ///
  /// In zh, this message translates to:
  /// **'删除这个邮箱？'**
  String get deleteThisAccount;

  /// No description provided for @localEmailsDraftsAndAnalysisForThis.
  ///
  /// In zh, this message translates to:
  /// **'此邮箱的本地邮件、草稿和分析记录会被删除，服务器邮件会保留。'**
  String get localEmailsDraftsAndAnalysisForThis;

  /// No description provided for @deleteAccount.
  ///
  /// In zh, this message translates to:
  /// **'删除邮箱'**
  String get deleteAccount;

  /// No description provided for @modelOptions.
  ///
  /// In zh, this message translates to:
  /// **'模型选项'**
  String get modelOptions;

  /// No description provided for @closeModelOptions.
  ///
  /// In zh, this message translates to:
  /// **'关闭模型选项'**
  String get closeModelOptions;

  /// No description provided for @defaultTextModel.
  ///
  /// In zh, this message translates to:
  /// **'默认文字模型'**
  String get defaultTextModel;

  /// No description provided for @forEverydayChatAndEmailDrafting.
  ///
  /// In zh, this message translates to:
  /// **'用于日常对话与邮件起草'**
  String get forEverydayChatAndEmailDrafting;

  /// No description provided for @useAsFixedVisionAssistant.
  ///
  /// In zh, this message translates to:
  /// **'固定为视觉助手'**
  String get useAsFixedVisionAssistant;

  /// No description provided for @forReadingImagesAndPdfPages.
  ///
  /// In zh, this message translates to:
  /// **'用于阅读图片与 PDF 页面'**
  String get forReadingImagesAndPdfPages;

  /// No description provided for @connectionDiagnosticsOptional.
  ///
  /// In zh, this message translates to:
  /// **'连接诊断（可选）'**
  String get connectionDiagnosticsOptional;

  /// No description provided for @sendTextStreamingToolAndImageRequests.
  ///
  /// In zh, this message translates to:
  /// **'发送文字、流式、工具及图片请求'**
  String get sendTextStreamingToolAndImageRequests;

  /// No description provided for @deleteModel.
  ///
  /// In zh, this message translates to:
  /// **'删除模型'**
  String get deleteModel;

  /// No description provided for @deleteLocalConfigurationAndKeyAfterConfirmation.
  ///
  /// In zh, this message translates to:
  /// **'删除本机配置和密钥，需要再次确认'**
  String get deleteLocalConfigurationAndKeyAfterConfirmation;

  /// No description provided for @deleteThisModel.
  ///
  /// In zh, this message translates to:
  /// **'删除这个模型？'**
  String get deleteThisModel;

  /// No description provided for @theLocalConfigurationAndKeyWillBe.
  ///
  /// In zh, this message translates to:
  /// **'本机的配置和密钥会被删除。'**
  String get theLocalConfigurationAndKeyWillBe;

  /// No description provided for @setAsFixedVisionAssistant.
  ///
  /// In zh, this message translates to:
  /// **'已固定为视觉助手'**
  String get setAsFixedVisionAssistant;

  /// No description provided for @setAsDefaultTextModel.
  ///
  /// In zh, this message translates to:
  /// **'已设为默认文字模型'**
  String get setAsDefaultTextModel;

  /// No description provided for @savedLeaveBlankToRetain.
  ///
  /// In zh, this message translates to:
  /// **'已保存 · 留空保留'**
  String get savedLeaveBlankToRetain;

  /// No description provided for @hideKey.
  ///
  /// In zh, this message translates to:
  /// **'隐藏密钥'**
  String get hideKey;

  /// No description provided for @showKey.
  ///
  /// In zh, this message translates to:
  /// **'显示密钥'**
  String get showKey;

  /// No description provided for @providerDefault.
  ///
  /// In zh, this message translates to:
  /// **'服务商默认'**
  String get providerDefault;

  /// No description provided for @enableThinking.
  ///
  /// In zh, this message translates to:
  /// **'开启思考'**
  String get enableThinking;

  /// No description provided for @disableThinking.
  ///
  /// In zh, this message translates to:
  /// **'关闭思考'**
  String get disableThinking;

  /// No description provided for @letTheModelDecide.
  ///
  /// In zh, this message translates to:
  /// **'模型自动判断'**
  String get letTheModelDecide;

  /// No description provided for @modelSettings.
  ///
  /// In zh, this message translates to:
  /// **'模型设置'**
  String get modelSettings;

  /// No description provided for @connectionConfiguration.
  ///
  /// In zh, this message translates to:
  /// **'连接配置'**
  String get connectionConfiguration;

  /// No description provided for @modelProvider.
  ///
  /// In zh, this message translates to:
  /// **'模型服务商'**
  String get modelProvider;

  /// No description provided for @autoDetect.
  ///
  /// In zh, this message translates to:
  /// **'自动识别'**
  String get autoDetect;

  /// MailPilot UI: lib/forms.dart
  ///
  /// In zh, this message translates to:
  /// **'自动识别 · {p0}'**
  String autoDetect310(String p0);

  /// No description provided for @configurationName.
  ///
  /// In zh, this message translates to:
  /// **'配置名称'**
  String get configurationName;

  /// No description provided for @apiUrl.
  ///
  /// In zh, this message translates to:
  /// **'API 地址'**
  String get apiUrl;

  /// No description provided for @modelName.
  ///
  /// In zh, this message translates to:
  /// **'模型名称'**
  String get modelName;

  /// No description provided for @selectABundledModel.
  ///
  /// In zh, this message translates to:
  /// **'选择内置型号'**
  String get selectABundledModel;

  /// No description provided for @youCanAlsoEnterTheModelName.
  ///
  /// In zh, this message translates to:
  /// **'也可以直接填写模型名称'**
  String get youCanAlsoEnterTheModelName;

  /// No description provided for @bundledModels.
  ///
  /// In zh, this message translates to:
  /// **'内置型号'**
  String get bundledModels;

  /// No description provided for @advancedParameters.
  ///
  /// In zh, this message translates to:
  /// **'高级参数'**
  String get advancedParameters;

  /// No description provided for @thinkingModeEffortAndOutputLength.
  ///
  /// In zh, this message translates to:
  /// **'思考模式、思考档位与输出长度'**
  String get thinkingModeEffortAndOutputLength;

  /// No description provided for @thinkingMode.
  ///
  /// In zh, this message translates to:
  /// **'思考模式'**
  String get thinkingMode;

  /// No description provided for @useProviderDefaultsWithoutExtraThinkingParameters.
  ///
  /// In zh, this message translates to:
  /// **'沿用服务商设置，不附加思考参数'**
  String get useProviderDefaultsWithoutExtraThinkingParameters;

  /// No description provided for @askTheModelToThinkDeeply.
  ///
  /// In zh, this message translates to:
  /// **'请求模型进行深入思考'**
  String get askTheModelToThinkDeeply;

  /// No description provided for @askTheModelToAnswerDirectly.
  ///
  /// In zh, this message translates to:
  /// **'请求模型直接回答'**
  String get askTheModelToAnswerDirectly;

  /// No description provided for @letTheModelDecideWhetherThinkingIs.
  ///
  /// In zh, this message translates to:
  /// **'由模型按问题决定是否思考'**
  String get letTheModelDecideWhetherThinkingIs;

  /// No description provided for @thinkingEffort.
  ///
  /// In zh, this message translates to:
  /// **'思考档位'**
  String get thinkingEffort;

  /// No description provided for @higherEffortUsuallyTakesLongerAndUses.
  ///
  /// In zh, this message translates to:
  /// **'档位越高，通常等待更久、消耗更多 Token。可用档位以具体模型为准。'**
  String get higherEffortUsuallyTakesLongerAndUses;

  /// No description provided for @thinkingBudgetTokens.
  ///
  /// In zh, this message translates to:
  /// **'思考预算（Token）'**
  String get thinkingBudgetTokens;

  /// No description provided for @blankOrUsesProviderDefaultsChooseEither.
  ///
  /// In zh, this message translates to:
  /// **'留空或 0 跟随服务商；预算与档位二选一。'**
  String get blankOrUsesProviderDefaultsChooseEither;

  /// No description provided for @contextSettings.
  ///
  /// In zh, this message translates to:
  /// **'上下文设置'**
  String get contextSettings;

  /// No description provided for @followModelSpecification.
  ///
  /// In zh, this message translates to:
  /// **'跟随型号'**
  String get followModelSpecification;

  /// No description provided for @officialApisUseVerifiedContextLimitsFor.
  ///
  /// In zh, this message translates to:
  /// **'官方接口自动匹配已核实型号的上下文额度'**
  String get officialApisUseVerifiedContextLimitsFor;

  /// No description provided for @setALocalBudgetWithinTheProvider.
  ///
  /// In zh, this message translates to:
  /// **'手动设置本地可用额度，不能超过厂商上限'**
  String get setALocalBudgetWithinTheProvider;

  /// MailPilot UI: lib/forms.dart
  ///
  /// In zh, this message translates to:
  /// **'当前上下文：{p0} Token。{p1}'**
  String currentContextTokens(String p0, String p1);

  /// No description provided for @planApiLimitsAreUnverifiedCurrentSettings.
  ///
  /// In zh, this message translates to:
  /// **'套餐接口限额暂未核实，保留当前配置，不套用标准接口额度。'**
  String get planApiLimitsAreUnverifiedCurrentSettings;

  /// No description provided for @thisApiOrModelIsNotIn.
  ///
  /// In zh, this message translates to:
  /// **'此接口或型号未收录，可使用自定义额度。'**
  String get thisApiOrModelIsNotIn;

  /// MailPilot UI: lib/forms.dart
  ///
  /// In zh, this message translates to:
  /// **'当前上下文：{p0} Token\n官方最大输入：{p1} Token · {p2}\n目录核实于 {p3}。实际输入还会预留输出空间。'**
  String currentContextTokensOfficialMaximumInputTokens(
    String p0,
    String p1,
    String p2,
    String p3,
  );

  /// No description provided for @nonThinking.
  ///
  /// In zh, this message translates to:
  /// **'非思考'**
  String get nonThinking;

  /// No description provided for @thinkingDefault.
  ///
  /// In zh, this message translates to:
  /// **'思考／默认'**
  String get thinkingDefault;

  /// No description provided for @contextIsOrganizedAtOfTheEffective.
  ///
  /// In zh, this message translates to:
  /// **'预计达到有效输入预算的 95% 时整理，目标降至 60%；原始记录保留。'**
  String get contextIsOrganizedAtOfTheEffective;

  /// No description provided for @maximumOutputLength.
  ///
  /// In zh, this message translates to:
  /// **'最大输出长度'**
  String get maximumOutputLength;

  /// No description provided for @useModelMaximum.
  ///
  /// In zh, this message translates to:
  /// **'跟随型号最大值'**
  String get useModelMaximum;

  /// No description provided for @useTheVerifiedMaximumOutputForThe.
  ///
  /// In zh, this message translates to:
  /// **'按实际型号使用已核实的最大输出额度'**
  String get useTheVerifiedMaximumOutputForThe;

  /// No description provided for @keepYourCustomOutputLength.
  ///
  /// In zh, this message translates to:
  /// **'保留你填写的输出长度'**
  String get keepYourCustomOutputLength;

  /// No description provided for @theMaximumOutputForThisApiIs.
  ///
  /// In zh, this message translates to:
  /// **'此接口的最大输出尚未核实，暂用 4096 Token，可切换自定义。'**
  String get theMaximumOutputForThisApiIs;

  /// MailPilot UI: lib/forms.dart
  ///
  /// In zh, this message translates to:
  /// **'型号最大输出：{p0} Token。实际请求按剩余上下文空间调整；模型可以提前结束，不会强制写满。'**
  String modelMaximumOutputTokensRequestsAdjustTo(String p0);

  /// No description provided for @contextLength.
  ///
  /// In zh, this message translates to:
  /// **'上下文长度'**
  String get contextLength;

  /// No description provided for @customOutputLength.
  ///
  /// In zh, this message translates to:
  /// **'自定义输出长度'**
  String get customOutputLength;

  /// No description provided for @lengthsAreInTokensSomeModelsCount.
  ///
  /// In zh, this message translates to:
  /// **'长度单位为 Token；部分模型会将思考计入输出。'**
  String get lengthsAreInTokensSomeModelsCount;

  /// No description provided for @outputLengthParameter.
  ///
  /// In zh, this message translates to:
  /// **'输出长度参数'**
  String get outputLengthParameter;

  /// No description provided for @standardParameter.
  ///
  /// In zh, this message translates to:
  /// **'标准参数'**
  String get standardParameter;

  /// No description provided for @completionLengthParameter.
  ///
  /// In zh, this message translates to:
  /// **'完成长度参数'**
  String get completionLengthParameter;

  /// No description provided for @chooseAccordingToTheProviderSApi.
  ///
  /// In zh, this message translates to:
  /// **'按服务商接口要求选择，不改变填写的输出长度。'**
  String get chooseAccordingToTheProviderSApi;

  /// No description provided for @notTested.
  ///
  /// In zh, this message translates to:
  /// **'尚未测试'**
  String get notTested;

  /// No description provided for @processing.
  ///
  /// In zh, this message translates to:
  /// **'处理中…'**
  String get processing;

  /// No description provided for @saveModel.
  ///
  /// In zh, this message translates to:
  /// **'保存模型'**
  String get saveModel;

  /// MailPilot UI: lib/mail_search_results.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0} 封邮件'**
  String emailCount(int p0);

  /// MailPilot UI: lib/mail_search_results.dart
  ///
  /// In zh, this message translates to:
  /// **'展开全部 {p0} 封'**
  String expandEmailCount(int p0);

  /// No description provided for @previousEmailPage.
  ///
  /// In zh, this message translates to:
  /// **'上一页邮件'**
  String get previousEmailPage;

  /// No description provided for @nextEmailPage.
  ///
  /// In zh, this message translates to:
  /// **'下一页邮件'**
  String get nextEmailPage;

  /// No description provided for @collapse.
  ///
  /// In zh, this message translates to:
  /// **'收起'**
  String get collapse;

  /// No description provided for @qqMail.
  ///
  /// In zh, this message translates to:
  /// **'QQ 邮箱'**
  String get qqMail;

  /// No description provided for @enableMailServices.
  ///
  /// In zh, this message translates to:
  /// **'开启邮箱服务'**
  String get enableMailServices;

  /// No description provided for @signInToQqMailInA.
  ///
  /// In zh, this message translates to:
  /// **'在电脑浏览器登录 QQ 邮箱，进入设置 → 账号与安全 → 安全设置，开启 POP3/IMAP/SMTP 服务。'**
  String get signInToQqMailInA;

  /// No description provided for @generateAnAppPassword.
  ///
  /// In zh, this message translates to:
  /// **'生成授权码'**
  String get generateAnAppPassword;

  /// No description provided for @completeIdentityVerificationOnTheOfficialPage.
  ///
  /// In zh, this message translates to:
  /// **'按官方页面完成身份验证，生成 16 位授权码。在本页填写授权码。'**
  String get completeIdentityVerificationOnTheOfficialPage;

  /// No description provided for @returnToAccountForm.
  ///
  /// In zh, this message translates to:
  /// **'返回填写账号'**
  String get returnToAccountForm;

  /// No description provided for @enterTheFullEmailAddressServersAre.
  ///
  /// In zh, this message translates to:
  /// **'邮箱地址填写完整地址。服务器已预填，可先测试连接，再保存。'**
  String get enterTheFullEmailAddressServersAre;

  /// No description provided for @getAndManageAppPasswords.
  ///
  /// In zh, this message translates to:
  /// **'获取与管理授权码'**
  String get getAndManageAppPasswords;

  /// No description provided for @mail368.
  ///
  /// In zh, this message translates to:
  /// **'163 邮箱'**
  String get mail368;

  /// No description provided for @enableImapSmtp.
  ///
  /// In zh, this message translates to:
  /// **'开启 IMAP/SMTP'**
  String get enableImapSmtp;

  /// No description provided for @signInToWebmailFindPopSmtp.
  ///
  /// In zh, this message translates to:
  /// **'登录 163 邮箱网页版，在设置中找到 POP3/SMTP/IMAP，开启 IMAP/SMTP 服务。'**
  String get signInToWebmailFindPopSmtp;

  /// No description provided for @getAClientAppPassword.
  ///
  /// In zh, this message translates to:
  /// **'获取客户端授权码'**
  String get getAClientAppPassword;

  /// No description provided for @completeTheVerificationAsInstructedAndEnter.
  ///
  /// In zh, this message translates to:
  /// **'按页面提示完成验证，将生成的客户端授权码填入本页。'**
  String get completeTheVerificationAsInstructedAndEnter;

  /// No description provided for @checkTheFullEmailAddress.
  ///
  /// In zh, this message translates to:
  /// **'核对完整邮箱地址'**
  String get checkTheFullEmailAddress;

  /// No description provided for @useYourFullComAddressIfYou.
  ///
  /// In zh, this message translates to:
  /// **'使用完整的 @163.com 地址；若找不到开关，可在网易官方帮助中心搜索“授权码”或“IMAP”。'**
  String get useYourFullComAddressIfYou;

  /// No description provided for @neteaseMailOfficialHelp.
  ///
  /// In zh, this message translates to:
  /// **'网易邮箱官方帮助中心'**
  String get neteaseMailOfficialHelp;

  /// No description provided for @alibabaBusinessMail.
  ///
  /// In zh, this message translates to:
  /// **'阿里企业邮箱'**
  String get alibabaBusinessMail;

  /// No description provided for @checkClientPermissions.
  ///
  /// In zh, this message translates to:
  /// **'确认客户端权限'**
  String get checkClientPermissions;

  /// No description provided for @askTheAdministratorToAllowThirdParty.
  ///
  /// In zh, this message translates to:
  /// **'请管理员为当前账号允许第三方客户端登录，并开启 IMAP/SMTP。新购企业邮箱可能默认限制第三方客户端。'**
  String get askTheAdministratorToAllowThirdParty;

  /// No description provided for @prepareASecurityPassword.
  ///
  /// In zh, this message translates to:
  /// **'准备安全密码'**
  String get prepareASecurityPassword;

  /// No description provided for @inWebmailGoToSettingsAccountAnd.
  ///
  /// In zh, this message translates to:
  /// **'在网页版设置 → 账号与安全中生成三方客户端安全密码。启用后，在本页使用该安全密码。'**
  String get inWebmailGoToSettingsAccountAnd;

  /// No description provided for @enterTheBusinessEmailAddress.
  ///
  /// In zh, this message translates to:
  /// **'填写企业邮箱地址'**
  String get enterTheBusinessEmailAddress;

  /// No description provided for @useTheFullBusinessAddressDefaultServers.
  ///
  /// In zh, this message translates to:
  /// **'使用完整的企业邮箱地址。默认使用通用服务器；香港地区或企业指定配置可在高级设置中修改。'**
  String get useTheFullBusinessAddressDefaultServers;

  /// No description provided for @allowThirdPartyClients.
  ///
  /// In zh, this message translates to:
  /// **'允许第三方客户端访问'**
  String get allowThirdPartyClients;

  /// No description provided for @generateAThirdPartyClientSecurityPassword.
  ///
  /// In zh, this message translates to:
  /// **'生成三方客户端安全密码'**
  String get generateAThirdPartyClientSecurityPassword;

  /// No description provided for @serverAddressesAndPorts.
  ///
  /// In zh, this message translates to:
  /// **'服务器地址与端口'**
  String get serverAddressesAndPorts;

  /// No description provided for @alibabaPersonalMail.
  ///
  /// In zh, this message translates to:
  /// **'阿里个人邮箱'**
  String get alibabaPersonalMail;

  /// No description provided for @checkAccountType.
  ///
  /// In zh, this message translates to:
  /// **'确认邮箱类型'**
  String get checkAccountType;

  /// No description provided for @thisPresetIsForFreeAlibabaCloud.
  ///
  /// In zh, this message translates to:
  /// **'此配置适用于阿里云免费个人邮箱。使用公司域名的企业邮箱，请选择“阿里企业”。'**
  String get thisPresetIsForFreeAlibabaCloud;

  /// No description provided for @prepareLoginDetails.
  ///
  /// In zh, this message translates to:
  /// **'准备登录信息'**
  String get prepareLoginDetails;

  /// No description provided for @enterTheFullEmailAddressAndRequired.
  ///
  /// In zh, this message translates to:
  /// **'填写完整邮箱地址及邮箱要求的登录凭据；确认账号已允许客户端访问。'**
  String get enterTheFullEmailAddressAndRequired;

  /// No description provided for @checkServers.
  ///
  /// In zh, this message translates to:
  /// **'核对服务器'**
  String get checkServers;

  /// No description provided for @useTheOfficialSslServerSettingsBelow.
  ///
  /// In zh, this message translates to:
  /// **'使用下方官方 SSL 服务器参数，可先测试连接，再保存。'**
  String get useTheOfficialSslServerSettingsBelow;

  /// No description provided for @personalMailServersAndPorts.
  ///
  /// In zh, this message translates to:
  /// **'个人邮箱服务器与端口'**
  String get personalMailServersAndPorts;

  /// No description provided for @customEmailProvider.
  ///
  /// In zh, this message translates to:
  /// **'自定义邮箱'**
  String get customEmailProvider;

  /// No description provided for @identifyYourProvider.
  ///
  /// In zh, this message translates to:
  /// **'确认服务商'**
  String get identifyYourProvider;

  /// No description provided for @aCustomDomainDoesNotIdentifyThe.
  ///
  /// In zh, this message translates to:
  /// **'自定义域名不能确定邮箱服务商，请向邮箱管理员确认。'**
  String get aCustomDomainDoesNotIdentifyThe;

  /// No description provided for @getConnectionSettings.
  ///
  /// In zh, this message translates to:
  /// **'获取连接参数'**
  String get getConnectionSettings;

  /// No description provided for @prepareImapAndSmtpHostsPortsEncryption.
  ///
  /// In zh, this message translates to:
  /// **'准备 IMAP、SMTP 主机、端口、加密方式，以及密码或客户端授权码。'**
  String get prepareImapAndSmtpHostsPortsEncryption;

  /// No description provided for @enterAndVerify.
  ///
  /// In zh, this message translates to:
  /// **'填写并验证'**
  String get enterAndVerify;

  /// No description provided for @expandServerAndAdvancedSettingsAndEnter.
  ///
  /// In zh, this message translates to:
  /// **'展开服务器与高级设置，按服务商提供的参数填写。'**
  String get expandServerAndAdvancedSettingsAndEnter;

  /// MailPilot UI: lib/mail_setup_guide.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0}配置指引'**
  String setupGuide(String p0);

  /// No description provided for @closeSetupGuide.
  ///
  /// In zh, this message translates to:
  /// **'关闭配置指引'**
  String get closeSetupGuide;

  /// No description provided for @defaultServersSsl.
  ///
  /// In zh, this message translates to:
  /// **'默认服务器 · SSL'**
  String get defaultServersSsl;

  /// MailPilot UI: lib/mail_setup_guide.dart
  ///
  /// In zh, this message translates to:
  /// **'收信  {p0}\n端口 993\n\n发信  {p1}\n端口 465'**
  String incomingPortOutgoingPort(String p0, String p1);

  /// No description provided for @officialHelp.
  ///
  /// In zh, this message translates to:
  /// **'官方帮助'**
  String get officialHelp;

  /// MailPilot UI: lib/mail_setup_guide.dart
  ///
  /// In zh, this message translates to:
  /// **'资料核对：{p0} · 官方网页将在浏览器打开'**
  String verifiedOfficialPagesOpenInYourBrowser(String p0);

  /// No description provided for @returnToForm.
  ///
  /// In zh, this message translates to:
  /// **'返回填写'**
  String get returnToForm;

  /// No description provided for @mailpilotPreview.
  ///
  /// In zh, this message translates to:
  /// **'MailPilot · 样例界面'**
  String get mailpilotPreview;

  /// No description provided for @thisLinkIsNotAValidWeb.
  ///
  /// In zh, this message translates to:
  /// **'该链接不是可打开的网页地址'**
  String get thisLinkIsNotAValidWeb;

  /// No description provided for @openWebpage.
  ///
  /// In zh, this message translates to:
  /// **'打开网页'**
  String get openWebpage;

  /// No description provided for @copyLink.
  ///
  /// In zh, this message translates to:
  /// **'复制链接'**
  String get copyLink;

  /// No description provided for @openInBrowser.
  ///
  /// In zh, this message translates to:
  /// **'在浏览器打开'**
  String get openInBrowser;

  /// MailPilot UI: lib/markdown_reply.dart
  ///
  /// In zh, this message translates to:
  /// **'[图片{p0}]'**
  String image(String p0);

  /// No description provided for @sizeUnknown.
  ///
  /// In zh, this message translates to:
  /// **'大小待确认'**
  String get sizeUnknown;

  /// No description provided for @firstPagesByDefaultPageCountPending.
  ///
  /// In zh, this message translates to:
  /// **'默认前 10 页，页数待读取'**
  String get firstPagesByDefaultPageCountPending;

  /// No description provided for @selectPdfPageNumbers.
  ///
  /// In zh, this message translates to:
  /// **'选择 PDF 页码'**
  String get selectPdfPageNumbers;

  /// MailPilot UI: lib/materials_sheet.dart
  ///
  /// In zh, this message translates to:
  /// **'第 {p0} 页'**
  String page(String p0);

  /// No description provided for @fileName.
  ///
  /// In zh, this message translates to:
  /// **'文件名'**
  String get fileName;

  /// No description provided for @deselect.
  ///
  /// In zh, this message translates to:
  /// **'取消选择'**
  String get deselect;

  /// No description provided for @select420.
  ///
  /// In zh, this message translates to:
  /// **'选择'**
  String get select420;

  /// No description provided for @materialsForThisAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'本次分析资料'**
  String get materialsForThisAnalysis;

  /// MailPilot UI: lib/materials_sheet.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0} 个附件 · {p1}{p2}'**
  String materialSummary(String p0, String p1, String p2);

  /// MailPilot UI: lib/materials_sheet.dart
  ///
  /// In zh, this message translates to:
  /// **' · {p0} 个大小待确认'**
  String withUnknownSize(String p0);

  /// No description provided for @closeMaterials.
  ///
  /// In zh, this message translates to:
  /// **'关闭资料管理'**
  String get closeMaterials;

  /// MailPilot UI: lib/materials_sheet.dart
  ///
  /// In zh, this message translates to:
  /// **'每轮最多 10 个附件、50 MB、20 张图片或 PDF 页面。\n{p0}'**
  String upToAttachmentsMbAndImagesOr(String p0);

  /// No description provided for @actualImageCountsInPdfAndOffice.
  ///
  /// In zh, this message translates to:
  /// **'PDF 与 Office 的实际图片量会在读取时检查。'**
  String get actualImageCountsInPdfAndOffice;

  /// No description provided for @selectedFilesAreReadOnlyWhenPreviewing.
  ///
  /// In zh, this message translates to:
  /// **'只在预览或提问时读取选中的文件。'**
  String get selectedFilesAreReadOnlyWhenPreviewing;

  /// No description provided for @attachmentListAwaitingSync.
  ///
  /// In zh, this message translates to:
  /// **'附件清单待同步'**
  String get attachmentListAwaitingSync;

  /// No description provided for @selectAllSupportedAttachments.
  ///
  /// In zh, this message translates to:
  /// **'全选可分析附件'**
  String get selectAllSupportedAttachments;

  /// No description provided for @keepBodyOnly.
  ///
  /// In zh, this message translates to:
  /// **'只保留正文'**
  String get keepBodyOnly;

  /// No description provided for @deviceFiles.
  ///
  /// In zh, this message translates to:
  /// **'手机文件'**
  String get deviceFiles;

  /// No description provided for @noMaterialsSelectedAddFilesOrSelect.
  ///
  /// In zh, this message translates to:
  /// **'尚未选择资料，添加文件或选择邮件即可。'**
  String get noMaterialsSelectedAddFilesOrSelect;

  /// No description provided for @materialCheckIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'资料检查未完成'**
  String get materialCheckIncomplete;

  /// No description provided for @retryWithCurrentMaterials.
  ///
  /// In zh, this message translates to:
  /// **'按当前资料重试本轮'**
  String get retryWithCurrentMaterials;

  /// No description provided for @analyzedImages.
  ///
  /// In zh, this message translates to:
  /// **'已分析的图片'**
  String get analyzedImages;

  /// No description provided for @previousAnalysisIsReusedByDefaultSelect.
  ///
  /// In zh, this message translates to:
  /// **'默认复用此前分析。需要查看新细节时，勾选重新核对；下次发送时生效。'**
  String get previousAnalysisIsReusedByDefaultSelect;

  /// No description provided for @cancelRecheck.
  ///
  /// In zh, this message translates to:
  /// **'取消重新核对'**
  String get cancelRecheck;

  /// No description provided for @recheckImages.
  ///
  /// In zh, this message translates to:
  /// **'重新核对图片'**
  String get recheckImages;

  /// No description provided for @previousVersion.
  ///
  /// In zh, this message translates to:
  /// **'上一版本'**
  String get previousVersion;

  /// MailPilot UI: lib/message_versions.dart
  ///
  /// In zh, this message translates to:
  /// **'第 {p0} 个版本，共 {p1} 个版本'**
  String messageVersionCount(String p0, String p1);

  /// No description provided for @nextVersion.
  ///
  /// In zh, this message translates to:
  /// **'下一版本'**
  String get nextVersion;

  /// No description provided for @closeMessageActions.
  ///
  /// In zh, this message translates to:
  /// **'关闭消息操作'**
  String get closeMessageActions;

  /// No description provided for @copyMessage.
  ///
  /// In zh, this message translates to:
  /// **'复制消息'**
  String get copyMessage;

  /// No description provided for @messageCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制消息'**
  String get messageCopied;

  /// MailPilot UI: lib/model_controls.dart
  ///
  /// In zh, this message translates to:
  /// **'关闭{p0}'**
  String close(String p0);

  /// No description provided for @volcengineArk.
  ///
  /// In zh, this message translates to:
  /// **'火山引擎 · 方舟'**
  String get volcengineArk;

  /// No description provided for @alibabaCloudModelStudio.
  ///
  /// In zh, this message translates to:
  /// **'阿里云 · 百炼'**
  String get alibabaCloudModelStudio;

  /// No description provided for @openaiCompatibleApi.
  ///
  /// In zh, this message translates to:
  /// **'通用兼容接口'**
  String get openaiCompatibleApi;

  /// No description provided for @minimalMinimal.
  ///
  /// In zh, this message translates to:
  /// **'极低 · minimal'**
  String get minimalMinimal;

  /// No description provided for @lowLow.
  ///
  /// In zh, this message translates to:
  /// **'低 · low'**
  String get lowLow;

  /// No description provided for @mediumMedium.
  ///
  /// In zh, this message translates to:
  /// **'中 · medium'**
  String get mediumMedium;

  /// No description provided for @highHigh.
  ///
  /// In zh, this message translates to:
  /// **'高 · high'**
  String get highHigh;

  /// No description provided for @veryHighXhigh.
  ///
  /// In zh, this message translates to:
  /// **'很高 · xhigh'**
  String get veryHighXhigh;

  /// No description provided for @maximumMax.
  ///
  /// In zh, this message translates to:
  /// **'最高 · max'**
  String get maximumMax;

  /// No description provided for @chooseImageProcessing.
  ///
  /// In zh, this message translates to:
  /// **'选择图片处理方式'**
  String get chooseImageProcessing;

  /// No description provided for @yourQuestionMaterialsAndCompletedAnalysisAre.
  ///
  /// In zh, this message translates to:
  /// **'问题、资料和已完成的分析已保留。'**
  String get yourQuestionMaterialsAndCompletedAnalysisAre;

  /// No description provided for @adjustMaterials.
  ///
  /// In zh, this message translates to:
  /// **'调整资料'**
  String get adjustMaterials;

  /// No description provided for @reduceImagesPagesOrTextAndSubmit.
  ///
  /// In zh, this message translates to:
  /// **'减少图片、页面或文字后重新提交'**
  String get reduceImagesPagesOrTextAndSubmit;

  /// No description provided for @processThisTurnInBatches.
  ///
  /// In zh, this message translates to:
  /// **'分批处理本轮'**
  String get processThisTurnInBatches;

  /// No description provided for @readUnfinishedImagesInBatchesThenSummarize.
  ///
  /// In zh, this message translates to:
  /// **'分次读取尚未完成的图片，再汇总回答'**
  String get readUnfinishedImagesInBatchesThenSummarize;

  /// No description provided for @couldNotReadThisPage.
  ///
  /// In zh, this message translates to:
  /// **'无法读取此页'**
  String get couldNotReadThisPage;

  /// No description provided for @couldNotReadThisPagePleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'无法读取此页，请重试'**
  String get couldNotReadThisPagePleaseRetry;

  /// No description provided for @closePagePreview.
  ///
  /// In zh, this message translates to:
  /// **'关闭页面预览'**
  String get closePagePreview;

  /// No description provided for @pageImageUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'此页图片无法显示'**
  String get pageImageUnavailable;

  /// No description provided for @selectPdfPages.
  ///
  /// In zh, this message translates to:
  /// **'选择 PDF 页面'**
  String get selectPdfPages;

  /// MailPilot UI: lib/pdf_picker.dart
  ///
  /// In zh, this message translates to:
  /// **' · 共 {p0} 页'**
  String pagesTotal(String p0);

  /// MailPilot UI: lib/pdf_picker.dart
  ///
  /// In zh, this message translates to:
  /// **'已选 {p0} 页 / 最多 20 页'**
  String pagesSelectedMaximum(String p0);

  /// No description provided for @selectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get selectAll;

  /// No description provided for @firstPages.
  ///
  /// In zh, this message translates to:
  /// **'前 10 页'**
  String get firstPages;

  /// No description provided for @clear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get clear;

  /// No description provided for @readingPdf.
  ///
  /// In zh, this message translates to:
  /// **'正在读取当前 PDF…'**
  String get readingPdf;

  /// No description provided for @couldNotReadPageNumbers.
  ///
  /// In zh, this message translates to:
  /// **'无法读取页码'**
  String get couldNotReadPageNumbers;

  /// No description provided for @retryReading.
  ///
  /// In zh, this message translates to:
  /// **'重试读取'**
  String get retryReading;

  /// No description provided for @selectUpToPagesPerPdf.
  ///
  /// In zh, this message translates to:
  /// **'每份 PDF 最多选择 20 页'**
  String get selectUpToPagesPerPdf;

  /// No description provided for @deselectThisAttachment.
  ///
  /// In zh, this message translates to:
  /// **'取消选择此附件'**
  String get deselectThisAttachment;

  /// MailPilot UI: lib/pdf_picker.dart
  ///
  /// In zh, this message translates to:
  /// **'确认选择 · {p0} 页'**
  String confirmSelectionPages(String p0);

  /// No description provided for @retryPreview.
  ///
  /// In zh, this message translates to:
  /// **'重试预览'**
  String get retryPreview;

  /// MailPilot UI: lib/pdf_picker.dart
  ///
  /// In zh, this message translates to:
  /// **'预览第 {p0} 页'**
  String previewPage(String p0);

  /// No description provided for @loadingPreview.
  ///
  /// In zh, this message translates to:
  /// **'正在显示预览…'**
  String get loadingPreview;

  /// MailPilot UI: lib/pdf_picker.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0}第 {p1} 页'**
  String page480(String p0, String p1);

  /// MailPilot UI: lib/reasoning_panel.dart
  ///
  /// In zh, this message translates to:
  /// **'思考 {p0}\n'**
  String reasoningSegmentHeading(String p0);

  /// No description provided for @searching.
  ///
  /// In zh, this message translates to:
  /// **'正在搜索'**
  String get searching;

  /// No description provided for @searchIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'搜索未完成'**
  String get searchIncomplete;

  /// MailPilot UI: lib/reasoning_panel.dart
  ///
  /// In zh, this message translates to:
  /// **'搜索到 {p0} 条结果'**
  String searchResultCount(int p0);

  /// No description provided for @readingWebpages.
  ///
  /// In zh, this message translates to:
  /// **'正在读取网页'**
  String get readingWebpages;

  /// MailPilot UI: lib/reasoning_panel.dart
  ///
  /// In zh, this message translates to:
  /// **'已读取 {p0} 个网页'**
  String readWebpageCount(int p0);

  /// No description provided for @webpageReadingFinished.
  ///
  /// In zh, this message translates to:
  /// **'网页读取结束'**
  String get webpageReadingFinished;

  /// No description provided for @readingMaterials.
  ///
  /// In zh, this message translates to:
  /// **'正在读取资料'**
  String get readingMaterials;

  /// No description provided for @sourceExcerptViewed.
  ///
  /// In zh, this message translates to:
  /// **'已查看来源摘录'**
  String get sourceExcerptViewed;

  /// No description provided for @materialsReused.
  ///
  /// In zh, this message translates to:
  /// **'已复用资料'**
  String get materialsReused;

  /// No description provided for @searchingEmails.
  ///
  /// In zh, this message translates to:
  /// **'正在检索邮件'**
  String get searchingEmails;

  /// No description provided for @emailsSearched.
  ///
  /// In zh, this message translates to:
  /// **'已检索邮件'**
  String get emailsSearched;

  /// No description provided for @processing493.
  ///
  /// In zh, this message translates to:
  /// **'正在处理'**
  String get processing493;

  /// No description provided for @actionCompleted.
  ///
  /// In zh, this message translates to:
  /// **'操作已完成'**
  String get actionCompleted;

  /// No description provided for @lessThanSecond.
  ///
  /// In zh, this message translates to:
  /// **'不足 1 秒'**
  String get lessThanSecond;

  /// MailPilot UI: lib/reasoning_panel.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0} 秒'**
  String elapsedSeconds(int p0);

  /// No description provided for @thinking497.
  ///
  /// In zh, this message translates to:
  /// **'正在思考'**
  String get thinking497;

  /// No description provided for @thinkingStopped.
  ///
  /// In zh, this message translates to:
  /// **'思考已停止'**
  String get thinkingStopped;

  /// No description provided for @thinkingInterrupted.
  ///
  /// In zh, this message translates to:
  /// **'思考已中断'**
  String get thinkingInterrupted;

  /// No description provided for @process.
  ///
  /// In zh, this message translates to:
  /// **'处理过程'**
  String get process;

  /// No description provided for @thought.
  ///
  /// In zh, this message translates to:
  /// **'已思考'**
  String get thought;

  /// No description provided for @reasoning.
  ///
  /// In zh, this message translates to:
  /// **'思考过程'**
  String get reasoning;

  /// No description provided for @viewReasoning.
  ///
  /// In zh, this message translates to:
  /// **'查看思考记录'**
  String get viewReasoning;

  /// No description provided for @currentAttempt.
  ///
  /// In zh, this message translates to:
  /// **'本次尝试'**
  String get currentAttempt;

  /// No description provided for @previousAttempt.
  ///
  /// In zh, this message translates to:
  /// **'上次尝试'**
  String get previousAttempt;

  /// MailPilot UI: lib/reasoning_panel.dart
  ///
  /// In zh, this message translates to:
  /// **'更早尝试 {p0}'**
  String earlierAttempt(String p0);

  /// No description provided for @viewingAPreviousAttempt.
  ///
  /// In zh, this message translates to:
  /// **'正在查看上次尝试'**
  String get viewingAPreviousAttempt;

  /// No description provided for @reasoningIsLongTheFirstCharactersHave.
  ///
  /// In zh, this message translates to:
  /// **'思考内容较长，已保留前 128000 字符。'**
  String get reasoningIsLongTheFirstCharactersHave;

  /// No description provided for @jumpToEndOfReasoning.
  ///
  /// In zh, this message translates to:
  /// **'回到思考末尾'**
  String get jumpToEndOfReasoning;

  /// No description provided for @uiPreviewSampleDataInstallAndroidTo.
  ///
  /// In zh, this message translates to:
  /// **'界面预览 · 使用样例数据，连接邮箱和模型请安装 Android 版'**
  String get uiPreviewSampleDataInstallAndroidTo;

  /// No description provided for @dismissNotice.
  ///
  /// In zh, this message translates to:
  /// **'关闭提示'**
  String get dismissNotice;

  /// No description provided for @backToHome.
  ///
  /// In zh, this message translates to:
  /// **'返回主页'**
  String get backToHome;

  /// No description provided for @backToSettings.
  ///
  /// In zh, this message translates to:
  /// **'返回设置'**
  String get backToSettings;

  /// No description provided for @backToConversation.
  ///
  /// In zh, this message translates to:
  /// **'返回对话'**
  String get backToConversation;

  /// No description provided for @openMenu.
  ///
  /// In zh, this message translates to:
  /// **'打开菜单'**
  String get openMenu;

  /// No description provided for @noVersionsAvailable.
  ///
  /// In zh, this message translates to:
  /// **'版本记录为空'**
  String get noVersionsAvailable;

  /// No description provided for @couldNotLoadVersionsPleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'版本记录暂时无法读取，请重试'**
  String get couldNotLoadVersionsPleaseRetry;

  /// No description provided for @cannotEditThisQuestion.
  ///
  /// In zh, this message translates to:
  /// **'无法修改此问题'**
  String get cannotEditThisQuestion;

  /// No description provided for @couldNotEditThisQuestionPleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'无法修改此问题，请重试'**
  String get couldNotEditThisQuestionPleaseRetry;

  /// No description provided for @editNotSubmittedPleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'修改未提交，请重试'**
  String get editNotSubmittedPleaseRetry;

  /// No description provided for @addAModelFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先添加模型'**
  String get addAModelFirst;

  /// No description provided for @materialCheckIncompletePleaseRetry.
  ///
  /// In zh, this message translates to:
  /// **'资料检查未完成，请重试'**
  String get materialCheckIncompletePleaseRetry;

  /// No description provided for @newConversation.
  ///
  /// In zh, this message translates to:
  /// **'新对话'**
  String get newConversation;

  /// No description provided for @whatSOnYourMind.
  ///
  /// In zh, this message translates to:
  /// **'有什么想聊的？'**
  String get whatSOnYourMind;

  /// No description provided for @letSMakeSenseOfYourEmails.
  ///
  /// In zh, this message translates to:
  /// **'邮件里的事，一起理清。'**
  String get letSMakeSenseOfYourEmails;

  /// No description provided for @configureAModelToChatYouCan.
  ///
  /// In zh, this message translates to:
  /// **'配置模型即可聊天，邮箱可以稍后添加。'**
  String get configureAModelToChatYouCan;

  /// No description provided for @askAQuestionOrSelectEmailsAs.
  ///
  /// In zh, this message translates to:
  /// **'直接提问，或选择邮件作为资料。'**
  String get askAQuestionOrSelectEmailsAs;

  /// No description provided for @helpMeOrganizeMyThoughts.
  ///
  /// In zh, this message translates to:
  /// **'帮我整理思路'**
  String get helpMeOrganizeMyThoughts;

  /// No description provided for @helpMeWriteSomething.
  ///
  /// In zh, this message translates to:
  /// **'帮我写段文字'**
  String get helpMeWriteSomething;

  /// No description provided for @summarizeSelectedEmails.
  ///
  /// In zh, this message translates to:
  /// **'总结所选邮件'**
  String get summarizeSelectedEmails;

  /// No description provided for @helpMeDraftAReply.
  ///
  /// In zh, this message translates to:
  /// **'帮我起草回复'**
  String get helpMeDraftAReply;

  /// No description provided for @retryWebSearch.
  ///
  /// In zh, this message translates to:
  /// **'重试联网'**
  String get retryWebSearch;

  /// No description provided for @answerWithoutSearch.
  ///
  /// In zh, this message translates to:
  /// **'关闭搜索后回答'**
  String get answerWithoutSearch;

  /// No description provided for @continueSearching.
  ///
  /// In zh, this message translates to:
  /// **'继续检索'**
  String get continueSearching;

  /// No description provided for @responseIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'回答未完成'**
  String get responseIncomplete;

  /// No description provided for @continueOrganizing.
  ///
  /// In zh, this message translates to:
  /// **'继续整理'**
  String get continueOrganizing;

  /// No description provided for @retryThisTurn.
  ///
  /// In zh, this message translates to:
  /// **'重试本轮'**
  String get retryThisTurn;

  /// No description provided for @viewBudget.
  ///
  /// In zh, this message translates to:
  /// **'查看预算'**
  String get viewBudget;

  /// No description provided for @retryWithCompatibleFormat.
  ///
  /// In zh, this message translates to:
  /// **'兼容格式重试'**
  String get retryWithCompatibleFormat;

  /// No description provided for @chooseProcessingMethod.
  ///
  /// In zh, this message translates to:
  /// **'选择处理方式'**
  String get chooseProcessingMethod;

  /// No description provided for @adjustMaterialsAndRetry.
  ///
  /// In zh, this message translates to:
  /// **'调整资料后重试'**
  String get adjustMaterialsAndRetry;

  /// No description provided for @restoreDefaultThinkingAndRetry.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认思考并重试'**
  String get restoreDefaultThinkingAndRetry;

  /// No description provided for @chooseVisionAssistant.
  ///
  /// In zh, this message translates to:
  /// **'选择视觉助手'**
  String get chooseVisionAssistant;

  /// No description provided for @editConfiguration.
  ///
  /// In zh, this message translates to:
  /// **'修改配置'**
  String get editConfiguration;

  /// MailPilot UI: lib/screens.dart
  ///
  /// In zh, this message translates to:
  /// **'读图 · {p0}'**
  String vision(String p0);

  /// MailPilot UI: lib/screens.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0} 处来源'**
  String sourceCount(int p0);

  /// No description provided for @copyResponse.
  ///
  /// In zh, this message translates to:
  /// **'复制回答'**
  String get copyResponse;

  /// No description provided for @originalMarkdownCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制 Markdown 原文'**
  String get originalMarkdownCopied;

  /// No description provided for @responseStopped.
  ///
  /// In zh, this message translates to:
  /// **'本次回答已停止'**
  String get responseStopped;

  /// No description provided for @stoppedThePartialResponseReceivedIsShown.
  ///
  /// In zh, this message translates to:
  /// **'已停止，以上是收到的部分回答'**
  String get stoppedThePartialResponseReceivedIsShown;

  /// No description provided for @reviewDraftAndSend.
  ///
  /// In zh, this message translates to:
  /// **'查看草稿并发送'**
  String get reviewDraftAndSend;

  /// No description provided for @writeAsEmail.
  ///
  /// In zh, this message translates to:
  /// **'写成邮件'**
  String get writeAsEmail;

  /// No description provided for @connectingToModel.
  ///
  /// In zh, this message translates to:
  /// **'正在连接模型…'**
  String get connectingToModel;

  /// No description provided for @viewingAnOlderVersion.
  ///
  /// In zh, this message translates to:
  /// **'正在查看历史版本'**
  String get viewingAnOlderVersion;

  /// No description provided for @backToLatest.
  ///
  /// In zh, this message translates to:
  /// **'回到最新'**
  String get backToLatest;

  /// No description provided for @textModel.
  ///
  /// In zh, this message translates to:
  /// **'文字模型'**
  String get textModel;

  /// MailPilot UI: lib/screens.dart
  ///
  /// In zh, this message translates to:
  /// **'{p0} · 点击取消同步'**
  String tapToCancelSync(String p0);

  /// No description provided for @syncLatestEmailsInEachFolder.
  ///
  /// In zh, this message translates to:
  /// **'同步各文件夹最新 50 封'**
  String get syncLatestEmailsInEachFolder;

  /// No description provided for @searchEmails.
  ///
  /// In zh, this message translates to:
  /// **'搜索邮件'**
  String get searchEmails;

  /// No description provided for @emailActions.
  ///
  /// In zh, this message translates to:
  /// **'邮件操作'**
  String get emailActions;

  /// No description provided for @syncEmailsPerFolder.
  ///
  /// In zh, this message translates to:
  /// **'同步邮件（每文件夹 50 封）'**
  String get syncEmailsPerFolder;

  /// No description provided for @showAll.
  ///
  /// In zh, this message translates to:
  /// **'显示全部'**
  String get showAll;

  /// No description provided for @showUnread.
  ///
  /// In zh, this message translates to:
  /// **'只看未读'**
  String get showUnread;

  /// No description provided for @subjectOrSender.
  ///
  /// In zh, this message translates to:
  /// **'主题或发件人'**
  String get subjectOrSender;

  /// No description provided for @runSearch.
  ///
  /// In zh, this message translates to:
  /// **'执行搜索'**
  String get runSearch;

  /// No description provided for @connectAnEmailAccountFirst.
  ///
  /// In zh, this message translates to:
  /// **'先连接一个邮箱'**
  String get connectAnEmailAccountFirst;

  /// No description provided for @supportsQqAndCustomEmailProviders.
  ///
  /// In zh, this message translates to:
  /// **'支持 QQ、163 和自定义邮箱。'**
  String get supportsQqAndCustomEmailProviders;

  /// No description provided for @noLocalEmailsYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无本地邮件'**
  String get noLocalEmailsYet;

  /// No description provided for @pullDownToSyncRecentEmailsStartup.
  ///
  /// In zh, this message translates to:
  /// **'下拉同步最新邮件，启动时不会自动同步。'**
  String get pullDownToSyncRecentEmailsStartup;

  /// MailPilot UI: lib/screens.dart
  ///
  /// In zh, this message translates to:
  /// **'分析已选的 {p0} 封邮件'**
  String analyzeSelectedEmails(String p0);

  /// No description provided for @emailDetails.
  ///
  /// In zh, this message translates to:
  /// **'邮件详情'**
  String get emailDetails;

  /// No description provided for @replyAndForward.
  ///
  /// In zh, this message translates to:
  /// **'回复与转发'**
  String get replyAndForward;

  /// No description provided for @reply.
  ///
  /// In zh, this message translates to:
  /// **'回复'**
  String get reply;

  /// No description provided for @replyAll.
  ///
  /// In zh, this message translates to:
  /// **'回复全部'**
  String get replyAll;

  /// No description provided for @forward.
  ///
  /// In zh, this message translates to:
  /// **'转发'**
  String get forward;

  /// No description provided for @recipientDetails.
  ///
  /// In zh, this message translates to:
  /// **'收件信息'**
  String get recipientDetails;

  /// MailPilot UI: lib/screens.dart
  ///
  /// In zh, this message translates to:
  /// **'收件人：{p0}\n抄送：{p1}'**
  String toCc(String p0, String p1);

  /// No description provided for @bodyAwaitingBackgroundSyncYouCanKeep.
  ///
  /// In zh, this message translates to:
  /// **'正文待后台同步，可继续浏览其他邮件。'**
  String get bodyAwaitingBackgroundSyncYouCanKeep;

  /// MailPilot UI: lib/screens.dart
  ///
  /// In zh, this message translates to:
  /// **'附件 · {p0}'**
  String attachments(String p0);

  /// No description provided for @tapAnAttachmentToPreviewSelectIt.
  ///
  /// In zh, this message translates to:
  /// **'点按附件预览，勾选用于 AI 分析'**
  String get tapAnAttachmentToPreviewSelectIt;

  /// No description provided for @askAssistant.
  ///
  /// In zh, this message translates to:
  /// **'交给助手'**
  String get askAssistant;

  /// No description provided for @noDraftsYet.
  ///
  /// In zh, this message translates to:
  /// **'还没有草稿'**
  String get noDraftsYet;

  /// No description provided for @writeYourOwnOrAskTheAssistant.
  ///
  /// In zh, this message translates to:
  /// **'自己写，或让助手帮你起草。'**
  String get writeYourOwnOrAskTheAssistant;

  /// No description provided for @configurationSaved.
  ///
  /// In zh, this message translates to:
  /// **'配置已保存'**
  String get configurationSaved;

  /// No description provided for @closeConfiguration.
  ///
  /// In zh, this message translates to:
  /// **'关闭配置'**
  String get closeConfiguration;

  /// No description provided for @actionFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败'**
  String get actionFailed;

  /// No description provided for @backToConfiguration.
  ///
  /// In zh, this message translates to:
  /// **'返回配置'**
  String get backToConfiguration;

  /// No description provided for @volcengineWebSearch.
  ///
  /// In zh, this message translates to:
  /// **'火山联网搜索'**
  String get volcengineWebSearch;

  /// No description provided for @bocha.
  ///
  /// In zh, this message translates to:
  /// **'博查'**
  String get bocha;

  /// No description provided for @systemPreferredCloudOptional.
  ///
  /// In zh, this message translates to:
  /// **'系统优先，云端可选'**
  String get systemPreferredCloudOptional;

  /// No description provided for @qwenCloudTranscription.
  ///
  /// In zh, this message translates to:
  /// **'千问云端识别'**
  String get qwenCloudTranscription;

  /// No description provided for @automaticSystemRecognitionFollowsDeviceLanguage.
  ///
  /// In zh, this message translates to:
  /// **'自动（系统识别跟随手机语言）'**
  String get automaticSystemRecognitionFollowsDeviceLanguage;

  /// No description provided for @chinese.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @searchProvider.
  ///
  /// In zh, this message translates to:
  /// **'搜索服务商'**
  String get searchProvider;

  /// No description provided for @recognitionMode.
  ///
  /// In zh, this message translates to:
  /// **'识别方式'**
  String get recognitionMode;

  /// No description provided for @speechLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语音语言'**
  String get speechLanguage;

  /// No description provided for @automatic.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get automatic;

  /// No description provided for @systemRecognitionNeedsNoApiKeyIf.
  ///
  /// In zh, this message translates to:
  /// **'系统识别不需要配置密钥。手机没有识别服务时，可使用下方千问 ASR。'**
  String get systemRecognitionNeedsNoApiKeyIf;

  /// No description provided for @usedOnlyWhenSmartSearchIsEnabled.
  ///
  /// In zh, this message translates to:
  /// **'仅在开启智能搜索并提问时使用。搜索服务只接收本轮问题提取的关键词，不接收邮件、附件或历史聊天。'**
  String get usedOnlyWhenSmartSearchIsEnabled;

  /// No description provided for @qwenAsrBaseUrl.
  ///
  /// In zh, this message translates to:
  /// **'千问 ASR Base URL'**
  String get qwenAsrBaseUrl;

  /// No description provided for @fullSearchApiUrl.
  ///
  /// In zh, this message translates to:
  /// **'完整搜索接口地址'**
  String get fullSearchApiUrl;

  /// No description provided for @leaveBlankToRetainTheSavedKey.
  ///
  /// In zh, this message translates to:
  /// **'留空保留已保存密钥'**
  String get leaveBlankToRetainTheSavedKey;

  /// No description provided for @showOrHideKey.
  ///
  /// In zh, this message translates to:
  /// **'显示或隐藏密钥'**
  String get showOrHideKey;

  /// No description provided for @asrModel.
  ///
  /// In zh, this message translates to:
  /// **'ASR 模型'**
  String get asrModel;

  /// No description provided for @forExampleQwenAsrFlash.
  ///
  /// In zh, this message translates to:
  /// **'例如 qwen3-asr-flash'**
  String get forExampleQwenAsrFlash;

  /// No description provided for @transcriptionFillsTheInputFieldOnlyReview.
  ///
  /// In zh, this message translates to:
  /// **'识别结果只填入输入框；检查后由你发送。切换云端需要重新录音，最长 60 秒。'**
  String get transcriptionFillsTheInputFieldOnlyReview;

  /// No description provided for @streamingUiStateIsOutOfSync.
  ///
  /// In zh, this message translates to:
  /// **'流式界面状态已失步，请重新打开当前对话。'**
  String get streamingUiStateIsOutOfSync;

  /// No description provided for @streamNotReceivedCompletelyReopenThisConversation.
  ///
  /// In zh, this message translates to:
  /// **'流式内容未完整接收，请重新打开当前对话。'**
  String get streamNotReceivedCompletelyReopenThisConversation;

  /// No description provided for @appLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get appLanguage;

  /// No description provided for @languageTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择语言'**
  String get languageTitle;

  /// No description provided for @languageDescription.
  ///
  /// In zh, this message translates to:
  /// **'切换界面语言，邮件与对话内容保持原文。'**
  String get languageDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
