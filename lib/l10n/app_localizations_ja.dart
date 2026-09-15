// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get switchAccount => 'アカウントを切り替え';

  @override
  String get closeAccountPicker => 'アカウント選択を閉じる';

  @override
  String switchAccountCurrent(String p0) {
    return 'アカウント切り替え、現在：$p0';
  }

  @override
  String get openWithAnotherApp => '他のアプリで開く';

  @override
  String get openInAnotherApp => '他のアプリで開く';

  @override
  String get saveToDevice => '端末に保存';

  @override
  String get couldNotStartRecording => '録音を開始できません';

  @override
  String get addImage => '画像を追加';

  @override
  String get addFile => 'ファイルを追加';

  @override
  String get selectEmails => 'メールを選択';

  @override
  String get manageImportedMaterials => '取り込んだ資料を管理';

  @override
  String get deepThinking => '深い思考';

  @override
  String get editInput => '入力を編集';

  @override
  String get cancelEdit => '編集をキャンセル';

  @override
  String selectedMaterialsCount(int p0, int p1) {
    return 'メール $p0 件・添付 $p1 件を選択';
  }

  @override
  String get clearSelection => '選択を解除';

  @override
  String get listeningUpToSeconds => '聞き取り中・最大60秒';

  @override
  String get transcribing => '文字起こし中…';

  @override
  String get startingMicrophone => 'マイクを起動中…';

  @override
  String get recordAgainInCloudMode => 'クラウドで録音し直す';

  @override
  String get cancelVoiceInput => '音声入力をキャンセル';

  @override
  String get askAboutSelectedMaterials => '選択した資料について質問…';

  @override
  String get messageOrUseVoiceInput => 'メッセージまたは音声を入力';

  @override
  String get smartSearch => 'スマート検索';

  @override
  String get thinking => '思考';

  @override
  String get search => '検索';

  @override
  String get addAttachment => '添付を追加';

  @override
  String get stopResponse => '回答を停止';

  @override
  String get stopRecording => '録音を終了';

  @override
  String get sendQuestion => '質問を送信';

  @override
  String get voiceInput => '音声入力';

  @override
  String get draftDeleted => '下書きを削除しました';

  @override
  String get pleaseViewTheLatestVersion => '最新バージョンをご確認ください';

  @override
  String get from => '差出人';

  @override
  String get to => '宛先';

  @override
  String get cc => 'Cc';

  @override
  String get bcc => 'Bcc';

  @override
  String get notEntered => '未入力';

  @override
  String get noSubject => '（件名なし）';

  @override
  String get afterReviewingConfirmSendingOrTapThe =>
      '内容を確認し、送信を承認するか下のボタンを押してください。';

  @override
  String get confirmSend => '送信を確認';

  @override
  String get addRecipient => '宛先を追加';

  @override
  String get viewLatestVersion => '最新バージョンを表示';

  @override
  String get reviewAndEdit => '確認して編集';

  @override
  String get editEmail => 'メールを編集';

  @override
  String get jumpToLatestMessage => '最新メッセージへ';

  @override
  String get inbox => '受信トレイ';

  @override
  String get sent => '送信済み';

  @override
  String get drafts => '下書き';

  @override
  String get deleted => '削除済み';

  @override
  String get spam => '迷惑メール';

  @override
  String get archive => 'アーカイブ';

  @override
  String get mailFolders => 'メールフォルダー';

  @override
  String get refreshFolders => 'フォルダーを更新';

  @override
  String couldNotRefreshFoldersLocalListRetained(String p0) {
    return 'フォルダーを更新できません。ローカル一覧は保持されます。$p0';
  }

  @override
  String get unreadOnly => '未読のみ';

  @override
  String get deleteThisDraft => 'この下書きを削除しますか？';

  @override
  String get onlyTheLocalDraftIsDeletedChats =>
      'ローカルの下書きのみ削除します。チャットとサーバーのメールは保持されます。';

  @override
  String get delete => '削除';

  @override
  String get draftActions => '下書きの操作';

  @override
  String get rewrite => '書き直す';

  @override
  String get deleteDraft => '下書きを削除';

  @override
  String get recipientEmail => '宛先メールアドレス';

  @override
  String get separateMultipleAddressesWithCommas => '複数のアドレスは半角コンマで区切ってください';

  @override
  String get afterSavingReviewTheNewConfirmationCard =>
      '保存後、新しい確認カードを確認して送信してください。';

  @override
  String get saveRecipients => '宛先を保存';

  @override
  String get draftAnswerPrompt => 'この会話の回答に基づいて正式なメールを作成してください：';

  @override
  String get draftAnswerPromptSuffix => '確認して送信を承認できるようにしてください。';

  @override
  String get turnThisAnswerIntoAnEmail => 'この回答をメールにする';

  @override
  String get viewOriginalOfOlderVersion => '旧バージョンの原文を表示';

  @override
  String get messageActions => 'メッセージ操作';

  @override
  String get needsVerification => '要確認';

  @override
  String get sending => '送信中';

  @override
  String get sendFailed => '送信失敗';

  @override
  String get confirm => '確認';

  @override
  String get cancel => 'キャンセル';

  @override
  String attachmentCount(int p0) {
    return '添付 $p0 件';
  }

  @override
  String select(String p0) {
    return '$p0を選択';
  }

  @override
  String get emailAndModelConnectionsRequireAndroidUse =>
      'メールとモデルの接続にはAndroidが必要です。ここではUIプレビューをご利用ください。';

  @override
  String get notConnectedToTheAndroidMailService =>
      'Androidメールサービスに未接続です。最新版APKを完全に閉じて再度開いてください。ブラウザーやWidget Previewではプレビュー入口をご利用ください。';

  @override
  String get actionIncomplete => '操作が未完了です';

  @override
  String get thisFeatureIsUnavailableInTheCurrent => '現在の環境ではこの機能を使用できません';

  @override
  String get pin => '固定';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get previousDays => '過去7日間';

  @override
  String get previousDays86 => '過去30日間';

  @override
  String olderConversationDate(String p0, String p1, String p2) {
    return '$p0年$p1月$p2日';
  }

  @override
  String get loadingConversations => '会話を読み込み中';

  @override
  String get noMatchingConversations => '該当する会話がありません';

  @override
  String get yourConversationsWillAppearHere => '会話はここに保存されます';

  @override
  String get tryShorterKeywordsOrClearTheSearch => '短いキーワードで試すか、検索をクリアしてください。';

  @override
  String get startAChatAndComeBackAnytime => '会話を始めると、いつでも続きから再開できます。';

  @override
  String get clearSearch => '検索をクリア';

  @override
  String get startAConversation => '会話を始める';

  @override
  String get couldNotLoadConversationsTapToRetry =>
      '会話を読み込めません。タップして再試行してください。';

  @override
  String get renameConversation => '会話の名前を変更';

  @override
  String get enterConversationName => '会話名を入力';

  @override
  String get save => '保存';

  @override
  String deleteConversationCount(int p0) {
    return '$p0 件の会話を削除しますか？';
  }

  @override
  String get chatsSummariesAndAnalysisCachesForThese =>
      '対象の会話、要約、分析キャッシュを削除します。メールと下書きは保持されます。';

  @override
  String get rename => '名前を変更';

  @override
  String get unpin => '固定を解除';

  @override
  String get selectMultiple => '複数選択';

  @override
  String selectedConversationCount(int p0) {
    return '$p0 件の会話を選択';
  }

  @override
  String get exitSelection => '選択を終了';

  @override
  String get closeSidebar => 'サイドバーを閉じる';

  @override
  String get searchConversations => '会話内容を検索…';

  @override
  String get conversationSummary => '会話の要約';

  @override
  String get loading => '読み込み中…';

  @override
  String get loadMore => 'さらに読み込む';

  @override
  String get selectConversations => '会話を複数選択';

  @override
  String get settings => '設定';

  @override
  String get thisConversationSSummary => 'この会話の要約';

  @override
  String summarizedMessageCount(int p0) {
    return '以前のメッセージ $p0 件を要約済み';
  }

  @override
  String get closeSummary => '要約を閉じる';

  @override
  String get originalMessagesAreRetainedYouCanAdd =>
      '元のチャットは保持されます。情報の追加や訂正ができます。';

  @override
  String get noSummaryForThisConversationYet => 'この会話にはまだ要約がありません。';

  @override
  String get conversationChangedPleaseReopenTheSummary =>
      '会話が切り替わりました。要約を開き直してください。';

  @override
  String get draftingReadOnlyPreview => '起草中・読み取り専用プレビュー';

  @override
  String get incompleteCannotSend => '未完了・送信できません';

  @override
  String get draftingEmail => 'メールを起草';

  @override
  String get generatingResponse => '回答を生成';

  @override
  String get readingImages => '画像を読み取り';

  @override
  String get preparingMaterials => '資料を準備';

  @override
  String get generatingContent => '内容を生成';

  @override
  String get parsingModelAction => 'モデル操作を解析';

  @override
  String get organizingExistingResults => '既存の結果を整理';

  @override
  String get organizingContext => 'コンテキストを整理';

  @override
  String get webSearch => 'ウェブ検索';

  @override
  String get currentRequest => '今回のリクエスト';

  @override
  String get requestId => 'リクエストID';

  @override
  String get serverId => 'サーバーID';

  @override
  String get httpStatus => 'HTTPステータス';

  @override
  String get finishReason => '終了理由';

  @override
  String get exceptionType => '例外の種類';

  @override
  String get validationResult => '検証結果';

  @override
  String get requestBudgetAndDiagnostics => '今回の予算と診断';

  @override
  String get connectionDiagnostics => '接続診断';

  @override
  String get requestRecordsForThisTurn => 'このターンのリクエスト記録';

  @override
  String get closeDiagnostics => '診断を閉じる';

  @override
  String get processingStage => '処理段階';

  @override
  String get model => 'モデル';

  @override
  String get apiHost => 'APIホスト';

  @override
  String get imageProcessing => '画像処理';

  @override
  String get fullTextAndImageResponse => '画像とテキストを一括回答';

  @override
  String get visionAssistantReading => '視覚アシスタントで読み取り';

  @override
  String get batchProcessingSelectedForThisTurn => '今回選択した分割処理';

  @override
  String get reusingPreviousAnalysis => '以前の分析を再利用';

  @override
  String get requestsWithImages => '画像付きリクエスト';

  @override
  String requestCount(int p0) {
    return '$p0 回';
  }

  @override
  String get totalImagesUploaded => '画像の累計アップロード数';

  @override
  String imageCount(int p0) {
    return '$p0 枚';
  }

  @override
  String get reusedImages => '再利用した画像';

  @override
  String get batchingReason => '分割理由';

  @override
  String get estimatedInput => '推定入力';

  @override
  String get availableInputBudget => '利用可能な入力予算';

  @override
  String get configuredContext => '設定されたコンテキスト';

  @override
  String get outputReserve => '出力の予約枠';

  @override
  String get thinkingReserve => '思考の予約枠';

  @override
  String get suggestedSummaryLength => '推奨要約長';

  @override
  String get summaryBudgetLimit => '要約の利用可能上限';

  @override
  String get currentSummaryEstimate => '現在の要約の推定量';

  @override
  String get localEstimatesMayDifferFromProviderMetering =>
      'ローカル推定値はサービス側の計量と異なる場合があります。95%で整理を開始し、60%を目標とします。';

  @override
  String get timeToFirstChunk => '最初の受信まで';

  @override
  String get lastChunkReceived => '最終受信';

  @override
  String get requestDuration => 'リクエスト所要時間';

  @override
  String get technicalDetails => '技術詳細';

  @override
  String get requestIdsAndExceptionInformation => 'リクエストIDと例外情報';

  @override
  String get convertedToEmailBodyReviewBeforeSaving =>
      'メール本文に変換しました。確認してから保存してください。';

  @override
  String get conversionFailedOriginalTextRetained => '変換に失敗しました。原文は保持されます。';

  @override
  String get discardUnsavedChanges => '未保存の変更を破棄しますか？';

  @override
  String get savedDraftsAreRetained => '保存済みの下書きは保持されます。';

  @override
  String get discardChanges => '変更を破棄';

  @override
  String get deleteThisLocalRecord => 'このローカル記録を削除しますか？';

  @override
  String get serverEmailsAreRetained => 'サーバーのメールは保持されます。';

  @override
  String get composeEmail => 'メールを作成';

  @override
  String get back => '戻る';

  @override
  String get moreEmailActions => 'その他のメール操作';

  @override
  String get saveChangesAndRewrite => '変更を保存して書き直す';

  @override
  String get convertMarkdownToBodyText => 'Markdownを本文に変換';

  @override
  String get sendingAccount => '送信元アカウント';

  @override
  String get subject => '件名';

  @override
  String get body => '本文';

  @override
  String get sendAsThePlainTextShownHere => '表示されたプレーンテキストで送信';

  @override
  String get ccBcc => 'Cc / Bcc';

  @override
  String remove(String p0) {
    return '$p0を削除';
  }

  @override
  String get firstCheckTheServerSSentFolder => 'サーバーの送信済み記録と宛先の受信状況をご確認ください。';

  @override
  String get verifiedThatSendingSucceeded => '送信成功を確認しましたか？';

  @override
  String get thisOnlyUpdatesTheLocalRecord => 'この操作はローカル記録のみ更新します。';

  @override
  String get verifiedSentSuccessfully => '確認済み：送信成功';

  @override
  String get confirmedThatNoRecipientsReceivedIt => 'すべての宛先が未受信であることを確認しましたか？';

  @override
  String get restoreTheDraftToReviewAndSend =>
      '下書きを復元すると再確認して送信できます。一部の宛先が受信済みの場合、先に宛先を変更してください。';

  @override
  String get restoreDraft => '下書きを復元';

  @override
  String get verifiedNotSent => '確認済み：未送信';

  @override
  String get confirmSendingInChat => 'チャットで送信を確認';

  @override
  String get confirmBeforeSending => '送信前の確認';

  @override
  String get pleaseReviewTheFollowing => '以下をご確認ください';

  @override
  String get accountDeleted => 'アカウント削除済み';

  @override
  String get couldNotReadAttachment => '添付を読み取れません';

  @override
  String get couldNotReadImagePleaseRetry => '画像を読み取れません。再試行してください。';

  @override
  String get couldNotReadPagePleaseRetry => 'ページを読み取れません。再試行してください。';

  @override
  String get reload => '再読み込み';

  @override
  String get referencedMaterial => '引用資料';

  @override
  String get formattedView => '整形表示';

  @override
  String get viewOriginal => '原文を表示';

  @override
  String get theFollowingWasGeneratedByAVision =>
      '以下は視覚モデルが画像を読み取って生成した内容です。必要に応じて原画像と照合してください。';

  @override
  String get previousPage => '前のページ';

  @override
  String get nextPage => '次のページ';

  @override
  String get loadingReferencedMaterial => '引用資料を読み込み中…';

  @override
  String get selectedImageOrPdfPagePinchTo => '選択した画像またはPDFページ。ピンチで拡大できます。';

  @override
  String get imageUnavailableRetryOrOpenWithAnother =>
      '画像を表示できません。再試行するか他のアプリで開いてください。';

  @override
  String get pinchToZoomSavingAndExternalOpening => 'ピンチで拡大・保存や外部アプリでは元の添付を使用';

  @override
  String get mail => 'メール';

  @override
  String get myEmails => '自分のメール';

  @override
  String get draftsAndSending => '下書きと送信';

  @override
  String get emailAccounts => 'メールアカウント';

  @override
  String get addEmailAccount => 'メールアカウントを追加';

  @override
  String get modelsAndServices => 'モデルとサービス';

  @override
  String get defaultModel => '既定のモデル';

  @override
  String get visionAssistant => '視覚アシスタント';

  @override
  String get addModel => 'モデルを追加';

  @override
  String get automaticCurrentModelPreferred => '自動選択・現在のモデルを優先';

  @override
  String fixedAssistant(String p0) {
    return '固定アシスタント・$p0';
  }

  @override
  String get configurationUnavailable => '設定が無効です';

  @override
  String get chooseAutomatically => '自動選択';

  @override
  String get searchAndVoice => '検索と音声';

  @override
  String get webServicesAndSpeechRecognition => 'ウェブサービス、音声認識';

  @override
  String get preferences => '環境設定';

  @override
  String get contextOrganization => 'コンテキスト整理';

  @override
  String get fastOrganizationResponseSettingsUnchanged => '高速整理・回答設定は維持';

  @override
  String get followCurrentThinkingMode => '現在の思考モードに従う';

  @override
  String get fastOrganizationNonThinkingModeOnSupported =>
      '高速整理（対応APIでは非思考モード）';

  @override
  String get appearance => '外観';

  @override
  String get systemDefault => 'システムに従う';

  @override
  String get light => 'ライト';

  @override
  String get dark => 'ダーク';

  @override
  String get backgroundSync => 'バックグラウンド同期';

  @override
  String get off => 'オフ';

  @override
  String get hourly => '毎時';

  @override
  String get onceADay => '1日1回';

  @override
  String everyMinutes(String p0) {
    return '$p0 分ごと';
  }

  @override
  String get everyMinutes242 => '30分ごと';

  @override
  String get clearCacheAndChats => 'キャッシュとチャットを削除';

  @override
  String get clearLocalCache => 'ローカルキャッシュを削除しますか？';

  @override
  String get downloadedAttachmentsPagePreviewsAllChatsAnd =>
      'ダウンロード済み添付、プレビュー、全チャットと要約を削除します。メールとモデルの設定、下書きの添付は保持されます。';

  @override
  String versionAndSendConfirmation(String p0) {
    return 'MailPilot $p0\nメールの送信には毎回あなたの確認が必要です。';
  }

  @override
  String get custom => 'カスタム';

  @override
  String get appPassword => 'アプリパスワード';

  @override
  String get alibabaBusiness => 'Alibaba法人';

  @override
  String get passwordSecurityPassword => 'パスワード／安全パスワード';

  @override
  String get alibabaPersonal => 'Alibaba個人';

  @override
  String get emailPassword => 'メールパスワード';

  @override
  String get passwordAppPassword => 'パスワード／アプリパスワード';

  @override
  String get leaveBlankToKeepSavedCredentials => '保存済みの認証情報を維持する場合は空欄にしてください。';

  @override
  String get theAdministratorMustAllowThirdPartyClients =>
      '管理者による外部クライアントとIMAP/SMTPの許可が必要です。安全パスワードが有効な場合は専用のパスワードを入力してください。';

  @override
  String get enterTheFullEmailAddressAndPassword =>
      '完全なメールアドレスとパスワードを入力し、クライアントアクセスを許可してください。';

  @override
  String get enableImapSmtpInYourEmailSettings =>
      'メール設定でIMAP/SMTPを有効にし、アプリパスワードを取得してください。';

  @override
  String get useTheEmailPasswordOrAppPassword =>
      'サービス指定のメールパスワードまたはアプリパスワードを入力してください。';

  @override
  String get hideCredentials => '認証情報を隠す';

  @override
  String get showCredentials => '認証情報を表示';

  @override
  String get connectEmail => 'メールを接続';

  @override
  String get emailSettings => 'メール設定';

  @override
  String mail263(String p0) {
    return '$p0メール';
  }

  @override
  String mail264(String p0) {
    return '$p0メール';
  }

  @override
  String get emailAddress => 'メールアドレス';

  @override
  String get senderNameOptional => '差出人名（任意）';

  @override
  String get emailSetupGuide => 'メール設定ガイド';

  @override
  String get connectionDetailsAndInstructions => '接続情報と入力方法';

  @override
  String officialGuide(String p0) {
    return '$p0・公式ガイド';
  }

  @override
  String get serverAndAdvancedSettings => 'サーバーと詳細設定';

  @override
  String get accountLabel => 'アカウント名';

  @override
  String get loginUsername => 'ログインユーザー名';

  @override
  String get leaveBlankToUseTheFullEmail => '空欄の場合は完全なメールアドレスを使用';

  @override
  String get imapHost => 'IMAPホスト';

  @override
  String get imapPort => 'IMAPポート';

  @override
  String get incomingEncryption => '受信暗号化';

  @override
  String get smtpHost => 'SMTPホスト';

  @override
  String get smtpPort => 'SMTPポート';

  @override
  String get outgoingEncryption => '送信暗号化';

  @override
  String get testConnection => '接続をテスト';

  @override
  String get saveAccount => 'アカウントを保存';

  @override
  String get deleteThisAccount => 'このアカウントを削除しますか？';

  @override
  String get localEmailsDraftsAndAnalysisForThis =>
      'このアカウントのローカルメール、下書き、分析を削除します。サーバーのメールは保持されます。';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get modelOptions => 'モデルのオプション';

  @override
  String get closeModelOptions => 'モデルのオプションを閉じる';

  @override
  String get defaultTextModel => '既定のテキストモデル';

  @override
  String get forEverydayChatAndEmailDrafting => '日常の会話とメール起草に使用';

  @override
  String get useAsFixedVisionAssistant => '固定の視覚アシスタントにする';

  @override
  String get forReadingImagesAndPdfPages => '画像とPDFページの読み取りに使用';

  @override
  String get connectionDiagnosticsOptional => '接続診断（任意）';

  @override
  String get sendTextStreamingToolAndImageRequests =>
      'テキスト、ストリーミング、ツール、画像のリクエストを送信';

  @override
  String get deleteModel => 'モデルを削除';

  @override
  String get deleteLocalConfigurationAndKeyAfterConfirmation =>
      '確認後に端末の設定とキーを削除';

  @override
  String get deleteThisModel => 'このモデルを削除しますか？';

  @override
  String get theLocalConfigurationAndKeyWillBe => '端末の設定とキーを削除します。';

  @override
  String get setAsFixedVisionAssistant => '固定の視覚アシスタントに設定済み';

  @override
  String get setAsDefaultTextModel => '既定のテキストモデルに設定済み';

  @override
  String get savedLeaveBlankToRetain => '保存済み・維持する場合は空欄';

  @override
  String get hideKey => 'キーを隠す';

  @override
  String get showKey => 'キーを表示';

  @override
  String get providerDefault => 'サービス既定';

  @override
  String get enableThinking => '思考を有効化';

  @override
  String get disableThinking => '思考を無効化';

  @override
  String get letTheModelDecide => 'モデルが自動判断';

  @override
  String get modelSettings => 'モデル設定';

  @override
  String get connectionConfiguration => '接続設定';

  @override
  String get modelProvider => 'モデルサービス';

  @override
  String get autoDetect => '自動検出';

  @override
  String autoDetect310(String p0) {
    return '自動検出・$p0';
  }

  @override
  String get configurationName => '設定名';

  @override
  String get apiUrl => 'APIアドレス';

  @override
  String get modelName => 'モデル名';

  @override
  String get selectABundledModel => '内蔵モデルを選択';

  @override
  String get youCanAlsoEnterTheModelName => 'モデル名を直接入力することもできます';

  @override
  String get bundledModels => '内蔵モデル';

  @override
  String get advancedParameters => '詳細パラメーター';

  @override
  String get thinkingModeEffortAndOutputLength => '思考モード、強度、出力長';

  @override
  String get thinkingMode => '思考モード';

  @override
  String get useProviderDefaultsWithoutExtraThinkingParameters =>
      '追加の思考パラメーターなしでサービス既定を使用';

  @override
  String get askTheModelToThinkDeeply => 'モデルに深い思考を要求';

  @override
  String get askTheModelToAnswerDirectly => 'モデルに直接回答を要求';

  @override
  String get letTheModelDecideWhetherThinkingIs => '思考の必要性をモデルが判断';

  @override
  String get thinkingEffort => '思考の強度';

  @override
  String get higherEffortUsuallyTakesLongerAndUses =>
      '強度が高いほど通常は時間とTokenを消費します。利用可能な段階はモデルによって異なります。';

  @override
  String get thinkingBudgetTokens => '思考予算（Token）';

  @override
  String get blankOrUsesProviderDefaultsChooseEither =>
      '空欄または0はサービス既定です。予算と強度はどちらか一方を選択してください。';

  @override
  String get contextSettings => 'コンテキスト設定';

  @override
  String get followModelSpecification => 'モデル仕様に従う';

  @override
  String get officialApisUseVerifiedContextLimitsFor =>
      '公式APIでは確認済みモデルのコンテキスト上限を使用';

  @override
  String get setALocalBudgetWithinTheProvider => 'サービスの上限内でローカル予算を設定';

  @override
  String currentContextTokens(String p0, String p1) {
    return '現在のコンテキスト：$p0 Token。$p1';
  }

  @override
  String get planApiLimitsAreUnverifiedCurrentSettings =>
      'プランAPIの上限は未確認です。現在の設定を保持し、標準APIの上限は適用しません。';

  @override
  String get thisApiOrModelIsNotIn => 'このAPIまたはモデルは未収録です。カスタム予算を設定できます。';

  @override
  String currentContextTokensOfficialMaximumInputTokens(
    String p0,
    String p1,
    String p2,
    String p3,
  ) {
    return '現在のコンテキスト：$p0 Token\n公式最大入力：$p1 Token・$p2\n確認日：$p3。コンテキストから出力枠を予約します。';
  }

  @override
  String get nonThinking => '非思考';

  @override
  String get thinkingDefault => '思考／既定';

  @override
  String get contextIsOrganizedAtOfTheEffective =>
      '有効な入力予算の95%で整理し、60%を目標とします。元の記録は保持されます。';

  @override
  String get maximumOutputLength => '最大出力長';

  @override
  String get useModelMaximum => 'モデルの最大値を使用';

  @override
  String get useTheVerifiedMaximumOutputForThe => '実際のモデルの確認済み最大出力を使用';

  @override
  String get keepYourCustomOutputLength => '入力した出力長を維持';

  @override
  String get theMaximumOutputForThisApiIs =>
      'このAPIの最大出力は未確認です。暫定で4096 Tokenを使用します。カスタム値に変更できます。';

  @override
  String modelMaximumOutputTokensRequestsAdjustTo(String p0) {
    return 'モデルの最大出力：$p0 Token。リクエストは残りのコンテキストに合わせて調整され、モデルは早く終了することもあります。';
  }

  @override
  String get contextLength => 'コンテキスト長';

  @override
  String get customOutputLength => 'カスタム出力長';

  @override
  String get lengthsAreInTokensSomeModelsCount =>
      '単位はTokenです。一部のモデルは思考を出力に含めます。';

  @override
  String get outputLengthParameter => '出力長パラメーター';

  @override
  String get standardParameter => '標準パラメーター';

  @override
  String get completionLengthParameter => '完了長パラメーター';

  @override
  String get chooseAccordingToTheProviderSApi =>
      'サービスのAPI仕様に合わせて選択してください。入力した出力長は変わりません。';

  @override
  String get notTested => '未テスト';

  @override
  String get processing => '処理中…';

  @override
  String get saveModel => 'モデルを保存';

  @override
  String emailCount(int p0) {
    return 'メール $p0 件';
  }

  @override
  String expandEmailCount(int p0) {
    return '全 $p0 件を表示';
  }

  @override
  String get previousEmailPage => '前のメールページ';

  @override
  String get nextEmailPage => '次のメールページ';

  @override
  String get collapse => '折りたたむ';

  @override
  String get qqMail => 'QQメール';

  @override
  String get enableMailServices => 'メールサービスを有効化';

  @override
  String get signInToQqMailInA =>
      'PCブラウザーでQQメールにログインし、設定 → アカウントとセキュリティ → セキュリティ設定でPOP3/IMAP/SMTPを有効にします。';

  @override
  String get generateAnAppPassword => 'アプリパスワードを生成';

  @override
  String get completeIdentityVerificationOnTheOfficialPage =>
      '公式ページで本人確認を行い、16文字のアプリパスワードを生成してここに入力します。';

  @override
  String get returnToAccountForm => 'アカウント入力に戻る';

  @override
  String get enterTheFullEmailAddressServersAre =>
      '完全なメールアドレスを入力します。サーバーは入力済みです。保存前に接続をテストできます。';

  @override
  String get getAndManageAppPasswords => 'アプリパスワードの取得と管理';

  @override
  String get mail368 => '163メール';

  @override
  String get enableImapSmtp => 'IMAP/SMTPを有効化';

  @override
  String get signInToWebmailFindPopSmtp =>
      '163ウェブメールにログインし、設定のPOP3/SMTP/IMAPからIMAP/SMTPを有効にします。';

  @override
  String get getAClientAppPassword => 'クライアント用パスワードを取得';

  @override
  String get completeTheVerificationAsInstructedAndEnter =>
      'ページの指示に従って認証し、生成されたクライアント用パスワードを入力します。';

  @override
  String get checkTheFullEmailAddress => '完全なメールアドレスを確認';

  @override
  String get useYourFullComAddressIfYou =>
      '完全な@163.comアドレスを使用します。設定が見つからない場合はNetEase公式ヘルプで「授权码」または「IMAP」を検索してください。';

  @override
  String get neteaseMailOfficialHelp => 'NetEaseメール公式ヘルプ';

  @override
  String get alibabaBusinessMail => 'Alibaba法人メール';

  @override
  String get checkClientPermissions => 'クライアント権限を確認';

  @override
  String get askTheAdministratorToAllowThirdParty =>
      '管理者に外部クライアントの許可とIMAP/SMTPの有効化を依頼してください。新規法人アカウントでは既定で制限されている場合があります。';

  @override
  String get prepareASecurityPassword => '安全パスワードを準備';

  @override
  String get inWebmailGoToSettingsAccountAnd =>
      'ウェブメールの設定 → アカウントとセキュリティで外部クライアント用安全パスワードを生成し、有効化後にここで使用します。';

  @override
  String get enterTheBusinessEmailAddress => '法人メールアドレスを入力';

  @override
  String get useTheFullBusinessAddressDefaultServers =>
      '完全な法人アドレスを使用します。既定サーバーは入力済みです。香港地域や企業指定の設定は詳細設定で変更できます。';

  @override
  String get allowThirdPartyClients => '外部クライアントを許可';

  @override
  String get generateAThirdPartyClientSecurityPassword => '外部クライアント用安全パスワードを生成';

  @override
  String get serverAddressesAndPorts => 'サーバーアドレスとポート';

  @override
  String get alibabaPersonalMail => 'Alibaba個人メール';

  @override
  String get checkAccountType => 'アカウントの種類を確認';

  @override
  String get thisPresetIsForFreeAlibabaCloud =>
      'この設定はAlibaba Cloud無料個人メール用です。企業ドメインのアカウントはAlibaba法人を選択してください。';

  @override
  String get prepareLoginDetails => 'ログイン情報を準備';

  @override
  String get enterTheFullEmailAddressAndRequired =>
      '完全なメールアドレスと必要な認証情報を入力し、クライアントアクセスが許可されていることを確認してください。';

  @override
  String get checkServers => 'サーバーを確認';

  @override
  String get useTheOfficialSslServerSettingsBelow =>
      '下記の公式SSLサーバー設定を使用し、保存前に接続をテストしてください。';

  @override
  String get personalMailServersAndPorts => '個人メールのサーバーとポート';

  @override
  String get customEmailProvider => 'カスタムメール';

  @override
  String get identifyYourProvider => 'サービス提供元を確認';

  @override
  String get aCustomDomainDoesNotIdentifyThe =>
      '独自ドメインだけでは提供元は特定できません。メール管理者に確認してください。';

  @override
  String get getConnectionSettings => '接続設定を取得';

  @override
  String get prepareImapAndSmtpHostsPortsEncryption =>
      'IMAPとSMTPのホスト、ポート、暗号化方式、パスワードまたはアプリパスワードを準備してください。';

  @override
  String get enterAndVerify => '入力して確認';

  @override
  String get expandServerAndAdvancedSettingsAndEnter =>
      'サーバーと詳細設定を開き、サービス指定の情報を入力してください。';

  @override
  String setupGuide(String p0) {
    return '$p0設定ガイド';
  }

  @override
  String get closeSetupGuide => '設定ガイドを閉じる';

  @override
  String get defaultServersSsl => '既定サーバー・SSL';

  @override
  String incomingPortOutgoingPort(String p0, String p1) {
    return '受信  $p0\nポート993\n\n送信  $p1\nポート465';
  }

  @override
  String get officialHelp => '公式ヘルプ';

  @override
  String verifiedOfficialPagesOpenInYourBrowser(String p0) {
    return '確認日：$p0・公式ページはブラウザーで開きます';
  }

  @override
  String get returnToForm => '入力に戻る';

  @override
  String get mailpilotPreview => 'MailPilot・プレビュー';

  @override
  String get thisLinkIsNotAValidWeb => 'このリンクは開けるウェブアドレスではありません';

  @override
  String get openWebpage => 'ウェブページを開く';

  @override
  String get copyLink => 'リンクをコピー';

  @override
  String get openInBrowser => 'ブラウザーで開く';

  @override
  String image(String p0) {
    return '[画像$p0]';
  }

  @override
  String get sizeUnknown => 'サイズ未確認';

  @override
  String get firstPagesByDefaultPageCountPending => '既定で先頭10ページ、ページ数は未確認';

  @override
  String get selectPdfPageNumbers => 'PDFのページ番号を選択';

  @override
  String page(String p0) {
    return '$p0 ページ';
  }

  @override
  String get fileName => 'ファイル名';

  @override
  String get deselect => '選択を解除';

  @override
  String get select420 => '選択';

  @override
  String get materialsForThisAnalysis => '今回の分析資料';

  @override
  String materialSummary(String p0, String p1, String p2) {
    return '添付 $p0 件・$p1$p2';
  }

  @override
  String withUnknownSize(String p0) {
    return '・サイズ未確認 $p0 件';
  }

  @override
  String get closeMaterials => '資料管理を閉じる';

  @override
  String upToAttachmentsMbAndImagesOr(String p0) {
    return '1ターン最大10添付、50 MB、画像またはPDFページ20枚。\n$p0';
  }

  @override
  String get actualImageCountsInPdfAndOffice =>
      'PDFやOfficeの実際の画像数は読み取り時に確認します。';

  @override
  String get selectedFilesAreReadOnlyWhenPreviewing =>
      '選択したファイルはプレビューや質問時にのみ読み取ります。';

  @override
  String get attachmentListAwaitingSync => '添付一覧の同期待ち';

  @override
  String get selectAllSupportedAttachments => '分析可能な添付をすべて選択';

  @override
  String get keepBodyOnly => '本文のみ保持';

  @override
  String get deviceFiles => '端末のファイル';

  @override
  String get noMaterialsSelectedAddFilesOrSelect =>
      '資料が未選択です。ファイルを追加するかメールを選択してください。';

  @override
  String get materialCheckIncomplete => '資料確認が未完了';

  @override
  String get retryWithCurrentMaterials => '現在の資料で再試行';

  @override
  String get analyzedImages => '分析済みの画像';

  @override
  String get previousAnalysisIsReusedByDefaultSelect =>
      '既定では以前の分析を再利用します。新しい詳細が必要なら再確認を選択してください。次の送信時に適用されます。';

  @override
  String get cancelRecheck => '再確認をキャンセル';

  @override
  String get recheckImages => '画像を再確認';

  @override
  String get previousVersion => '前のバージョン';

  @override
  String messageVersionCount(String p0, String p1) {
    return '$p1 件中 $p0 番目のバージョン';
  }

  @override
  String get nextVersion => '次のバージョン';

  @override
  String get closeMessageActions => 'メッセージ操作を閉じる';

  @override
  String get copyMessage => 'メッセージをコピー';

  @override
  String get messageCopied => 'メッセージをコピーしました';

  @override
  String close(String p0) {
    return '$p0を閉じる';
  }

  @override
  String get volcengineArk => 'Volcengine・Ark';

  @override
  String get alibabaCloudModelStudio => 'Alibaba Cloud・Model Studio';

  @override
  String get openaiCompatibleApi => 'OpenAI互換API';

  @override
  String get minimalMinimal => '最小・minimal';

  @override
  String get lowLow => '低・low';

  @override
  String get mediumMedium => '中・medium';

  @override
  String get highHigh => '高・high';

  @override
  String get veryHighXhigh => '非常に高い・xhigh';

  @override
  String get maximumMax => '最大・max';

  @override
  String get chooseImageProcessing => '画像処理方法を選択';

  @override
  String get yourQuestionMaterialsAndCompletedAnalysisAre =>
      '質問、資料、完了済みの分析は保持されます。';

  @override
  String get adjustMaterials => '資料を調整';

  @override
  String get reduceImagesPagesOrTextAndSubmit => '画像、ページ、テキストを減らして再送信';

  @override
  String get processThisTurnInBatches => '今回を分割処理';

  @override
  String get readUnfinishedImagesInBatchesThenSummarize =>
      '未完了の画像を分割して読み取り、回答をまとめる';

  @override
  String get couldNotReadThisPage => 'このページを読み取れません';

  @override
  String get couldNotReadThisPagePleaseRetry => 'このページを読み取れません。再試行してください。';

  @override
  String get closePagePreview => 'ページプレビューを閉じる';

  @override
  String get pageImageUnavailable => 'ページ画像を表示できません';

  @override
  String get selectPdfPages => 'PDFページを選択';

  @override
  String pagesTotal(String p0) {
    return '・全 $p0 ページ';
  }

  @override
  String pagesSelectedMaximum(String p0) {
    return '$p0 ページ選択／最大20ページ';
  }

  @override
  String get selectAll => 'すべて選択';

  @override
  String get firstPages => '先頭10ページ';

  @override
  String get clear => 'クリア';

  @override
  String get readingPdf => 'PDFを読み取り中…';

  @override
  String get couldNotReadPageNumbers => 'ページ番号を読み取れません';

  @override
  String get retryReading => '読み取りを再試行';

  @override
  String get selectUpToPagesPerPdf => 'PDFごとに最大20ページ選択可能';

  @override
  String get deselectThisAttachment => 'この添付の選択を解除';

  @override
  String confirmSelectionPages(String p0) {
    return '選択を確認・$p0 ページ';
  }

  @override
  String get retryPreview => 'プレビューを再試行';

  @override
  String previewPage(String p0) {
    return '$p0 ページをプレビュー';
  }

  @override
  String get loadingPreview => 'プレビューを読み込み中…';

  @override
  String page480(String p0, String p1) {
    return '$p0・$p1 ページ';
  }

  @override
  String reasoningSegmentHeading(String p0) {
    return '思考 $p0\n';
  }

  @override
  String get searching => '検索中';

  @override
  String get searchIncomplete => '検索未完了';

  @override
  String searchResultCount(int p0) {
    return '$p0 件の結果が見つかりました';
  }

  @override
  String get readingWebpages => 'ウェブページを読み取り中';

  @override
  String readWebpageCount(int p0) {
    return '$p0 ページを読み取り済み';
  }

  @override
  String get webpageReadingFinished => 'ウェブページ読み取り終了';

  @override
  String get readingMaterials => '資料を読み取り中';

  @override
  String get sourceExcerptViewed => '出典の抜粋を確認済み';

  @override
  String get materialsReused => '資料を再利用済み';

  @override
  String get searchingEmails => 'メールを検索中';

  @override
  String get emailsSearched => 'メール検索完了';

  @override
  String get processing493 => '処理中';

  @override
  String get actionCompleted => '操作完了';

  @override
  String get lessThanSecond => '1秒未満';

  @override
  String elapsedSeconds(int p0) {
    return '$p0 秒';
  }

  @override
  String get thinking497 => '思考中';

  @override
  String get thinkingStopped => '思考を停止しました';

  @override
  String get thinkingInterrupted => '思考が中断されました';

  @override
  String get process => '処理の経過';

  @override
  String get thought => '思考済み';

  @override
  String get reasoning => '思考過程';

  @override
  String get viewReasoning => '思考記録を表示';

  @override
  String get currentAttempt => '今回の試行';

  @override
  String get previousAttempt => '前回の試行';

  @override
  String earlierAttempt(String p0) {
    return '以前の試行 $p0';
  }

  @override
  String get viewingAPreviousAttempt => '前回の試行を表示中';

  @override
  String get reasoningIsLongTheFirstCharactersHave =>
      '思考内容が長いため、先頭128000文字を保持しました。';

  @override
  String get jumpToEndOfReasoning => '思考の末尾へ';

  @override
  String get uiPreviewSampleDataInstallAndroidTo =>
      'UIプレビュー・サンプルデータ。メールとモデルの接続にはAndroid版をインストールしてください。';

  @override
  String get dismissNotice => '通知を閉じる';

  @override
  String get backToHome => 'ホームに戻る';

  @override
  String get backToSettings => '設定に戻る';

  @override
  String get backToConversation => '会話に戻る';

  @override
  String get openMenu => 'メニューを開く';

  @override
  String get noVersionsAvailable => 'バージョン記録がありません';

  @override
  String get couldNotLoadVersionsPleaseRetry => 'バージョンを読み込めません。再試行してください。';

  @override
  String get cannotEditThisQuestion => 'この質問は編集できません';

  @override
  String get couldNotEditThisQuestionPleaseRetry => '質問を編集できませんでした。再試行してください。';

  @override
  String get editNotSubmittedPleaseRetry => '編集が送信されていません。再試行してください。';

  @override
  String get addAModelFirst => '先にモデルを追加してください';

  @override
  String get materialCheckIncompletePleaseRetry => '資料確認が未完了です。再試行してください。';

  @override
  String get newConversation => '新しい会話';

  @override
  String get whatSOnYourMind => '何を話しましょうか？';

  @override
  String get letSMakeSenseOfYourEmails => 'メールの内容を一緒に整理しましょう。';

  @override
  String get configureAModelToChatYouCan => 'モデルを設定すれば会話できます。メールは後から追加できます。';

  @override
  String get askAQuestionOrSelectEmailsAs => '直接質問するか、資料としてメールを選択してください。';

  @override
  String get helpMeOrganizeMyThoughts => '考えを整理したい';

  @override
  String get helpMeWriteSomething => '文章を書きたい';

  @override
  String get summarizeSelectedEmails => '選択したメールを要約';

  @override
  String get helpMeDraftAReply => '返信の下書きを作成';

  @override
  String get retryWebSearch => 'ウェブ検索を再試行';

  @override
  String get answerWithoutSearch => '検索せず回答';

  @override
  String get continueSearching => '検索を続ける';

  @override
  String get responseIncomplete => '回答未完了';

  @override
  String get continueOrganizing => '整理を続ける';

  @override
  String get retryThisTurn => 'このターンを再試行';

  @override
  String get viewBudget => '予算を表示';

  @override
  String get retryWithCompatibleFormat => '互換形式で再試行';

  @override
  String get chooseProcessingMethod => '処理方法を選択';

  @override
  String get adjustMaterialsAndRetry => '資料を調整して再試行';

  @override
  String get restoreDefaultThinkingAndRetry => '既定の思考に戻して再試行';

  @override
  String get chooseVisionAssistant => '視覚アシスタントを選択';

  @override
  String get editConfiguration => '設定を変更';

  @override
  String vision(String p0) {
    return '画像読み取り・$p0';
  }

  @override
  String sourceCount(int p0) {
    return '出典 $p0 件';
  }

  @override
  String get copyResponse => '回答をコピー';

  @override
  String get originalMarkdownCopied => 'Markdown原文をコピーしました';

  @override
  String get responseStopped => '回答を停止しました';

  @override
  String get stoppedThePartialResponseReceivedIsShown =>
      '停止しました。上記は受信済みの回答の一部です。';

  @override
  String get reviewDraftAndSend => '下書きを確認して送信';

  @override
  String get writeAsEmail => 'メールにする';

  @override
  String get connectingToModel => 'モデルに接続中…';

  @override
  String get viewingAnOlderVersion => '旧バージョンを表示中';

  @override
  String get backToLatest => '最新に戻る';

  @override
  String get textModel => 'テキストモデル';

  @override
  String tapToCancelSync(String p0) {
    return '$p0・タップで同期をキャンセル';
  }

  @override
  String get syncLatestEmailsInEachFolder => '各フォルダーの最新50件を同期';

  @override
  String get searchEmails => 'メールを検索';

  @override
  String get emailActions => 'メール操作';

  @override
  String get syncEmailsPerFolder => 'メールを同期（各フォルダー50件）';

  @override
  String get showAll => 'すべて表示';

  @override
  String get showUnread => '未読のみ表示';

  @override
  String get subjectOrSender => '件名または差出人';

  @override
  String get runSearch => '検索を実行';

  @override
  String get connectAnEmailAccountFirst => '先にメールアカウントを接続';

  @override
  String get supportsQqAndCustomEmailProviders => 'QQ、163、カスタムメールに対応。';

  @override
  String get noLocalEmailsYet => 'ローカルメールがありません';

  @override
  String get pullDownToSyncRecentEmailsStartup =>
      '下に引いて最新メールを同期します。起動時の自動同期は行いません。';

  @override
  String analyzeSelectedEmails(String p0) {
    return '選択した $p0 件のメールを分析';
  }

  @override
  String get emailDetails => 'メールの詳細';

  @override
  String get replyAndForward => '返信と転送';

  @override
  String get reply => '返信';

  @override
  String get replyAll => '全員に返信';

  @override
  String get forward => '転送';

  @override
  String get recipientDetails => '宛先情報';

  @override
  String toCc(String p0, String p1) {
    return '宛先：$p0\nCc：$p1';
  }

  @override
  String get bodyAwaitingBackgroundSyncYouCanKeep =>
      '本文はバックグラウンド同期待ちです。他のメールの閲覧を続けられます。';

  @override
  String attachments(String p0) {
    return '添付・$p0';
  }

  @override
  String get tapAnAttachmentToPreviewSelectIt => '添付をタップしてプレビュー、選択してAI分析';

  @override
  String get askAssistant => 'アシスタントに渡す';

  @override
  String get noDraftsYet => '下書きはまだありません';

  @override
  String get writeYourOwnOrAskTheAssistant => '自分で書くか、アシスタントに下書きを依頼できます。';

  @override
  String get configurationSaved => '設定を保存しました';

  @override
  String get closeConfiguration => '設定を閉じる';

  @override
  String get actionFailed => '操作に失敗しました';

  @override
  String get backToConfiguration => '設定に戻る';

  @override
  String get volcengineWebSearch => 'Volcengineウェブ検索';

  @override
  String get bocha => 'Bocha';

  @override
  String get systemPreferredCloudOptional => 'システム優先、クラウドは任意';

  @override
  String get qwenCloudTranscription => 'Qwenクラウド音声認識';

  @override
  String get automaticSystemRecognitionFollowsDeviceLanguage =>
      '自動（システム認識は端末言語に従う）';

  @override
  String get chinese => '中国語';

  @override
  String get searchProvider => '検索サービス';

  @override
  String get recognitionMode => '認識方法';

  @override
  String get speechLanguage => '音声言語';

  @override
  String get automatic => '自動';

  @override
  String get systemRecognitionNeedsNoApiKeyIf =>
      'システム音声認識にAPIキーは不要です。端末に認識サービスがない場合は下記のQwen ASRを利用できます。';

  @override
  String get usedOnlyWhenSmartSearchIsEnabled =>
      'スマート検索を有効にして質問した時のみ使用します。検索サービスには抽出したキーワードを送り、メール、添付、会話履歴は送りません。';

  @override
  String get qwenAsrBaseUrl => 'Qwen ASRのBase URL';

  @override
  String get fullSearchApiUrl => '検索APIの完全なURL';

  @override
  String get leaveBlankToRetainTheSavedKey => '保存済みキーを保持するには空欄';

  @override
  String get showOrHideKey => 'キーを表示／非表示';

  @override
  String get asrModel => 'ASRモデル';

  @override
  String get forExampleQwenAsrFlash => '例：qwen3-asr-flash';

  @override
  String get transcriptionFillsTheInputFieldOnlyReview =>
      '認識結果は入力欄にのみ入ります。確認してから送信してください。クラウドへの切り替え時は最大60秒の録音をやり直します。';

  @override
  String get streamingUiStateIsOutOfSync =>
      'ストリーミング表示の同期が失われました。この会話を開き直してください。';

  @override
  String get streamNotReceivedCompletelyReopenThisConversation =>
      'ストリームを最後まで受信できませんでした。この会話を開き直してください。';

  @override
  String get appLanguage => '言語';

  @override
  String get languageTitle => '言語を選択';

  @override
  String get languageDescription => '表示言語を変更します。メールと会話の内容は原文のままです。';
}
