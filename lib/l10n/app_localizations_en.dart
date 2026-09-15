// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get switchAccount => 'Switch account';

  @override
  String get closeAccountPicker => 'Close account picker';

  @override
  String switchAccountCurrent(String p0) {
    return 'Switch account, current: $p0';
  }

  @override
  String get openWithAnotherApp => 'Open with another app';

  @override
  String get openInAnotherApp => 'Open in another app';

  @override
  String get saveToDevice => 'Save to device';

  @override
  String get couldNotStartRecording => 'Could not start recording';

  @override
  String get addImage => 'Add image';

  @override
  String get addFile => 'Add file';

  @override
  String get selectEmails => 'Select emails';

  @override
  String get manageImportedMaterials => 'Manage imported materials';

  @override
  String get deepThinking => 'Deep thinking';

  @override
  String get editInput => 'Edit input';

  @override
  String get cancelEdit => 'Cancel edit';

  @override
  String selectedMaterialsCount(int p0, int p1) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 emails',
      one: '1 email',
    );
    String _temp1 = intl.Intl.pluralLogic(
      p1,
      locale: localeName,
      other: '$p1 attachments',
      one: '1 attachment',
    );
    return '$_temp0 · $_temp1 selected';
  }

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get listeningUpToSeconds => 'Listening · up to 60 seconds';

  @override
  String get transcribing => 'Transcribing…';

  @override
  String get startingMicrophone => 'Starting microphone…';

  @override
  String get recordAgainInCloudMode => 'Record again in cloud mode';

  @override
  String get cancelVoiceInput => 'Cancel voice input';

  @override
  String get askAboutSelectedMaterials => 'Ask about selected materials…';

  @override
  String get messageOrUseVoiceInput => 'Message or use voice input';

  @override
  String get smartSearch => 'Smart search';

  @override
  String get thinking => 'Thinking';

  @override
  String get search => 'Search';

  @override
  String get addAttachment => 'Add attachment';

  @override
  String get stopResponse => 'Stop response';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get sendQuestion => 'Send question';

  @override
  String get voiceInput => 'Voice input';

  @override
  String get draftDeleted => 'Draft deleted';

  @override
  String get pleaseViewTheLatestVersion => 'Please view the latest version';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get cc => 'Cc';

  @override
  String get bcc => 'Bcc';

  @override
  String get notEntered => 'Not entered';

  @override
  String get noSubject => '(No subject)';

  @override
  String get afterReviewingConfirmSendingOrTapThe =>
      'After reviewing, confirm sending or tap the button below.';

  @override
  String get confirmSend => 'Confirm send';

  @override
  String get addRecipient => 'Add recipient';

  @override
  String get viewLatestVersion => 'View latest version';

  @override
  String get reviewAndEdit => 'Review and edit';

  @override
  String get editEmail => 'Edit email';

  @override
  String get jumpToLatestMessage => 'Jump to latest message';

  @override
  String get inbox => 'Inbox';

  @override
  String get sent => 'Sent';

  @override
  String get drafts => 'Drafts';

  @override
  String get deleted => 'Deleted';

  @override
  String get spam => 'Spam';

  @override
  String get archive => 'Archive';

  @override
  String get mailFolders => 'Mail folders';

  @override
  String get refreshFolders => 'Refresh folders';

  @override
  String couldNotRefreshFoldersLocalListRetained(String p0) {
    return 'Could not refresh folders. Local list retained. $p0';
  }

  @override
  String get unreadOnly => 'Unread only';

  @override
  String get deleteThisDraft => 'Delete this draft?';

  @override
  String get onlyTheLocalDraftIsDeletedChats =>
      'Only the local draft is deleted. Chats and server emails are retained.';

  @override
  String get delete => 'Delete';

  @override
  String get draftActions => 'Draft actions';

  @override
  String get rewrite => 'Rewrite';

  @override
  String get deleteDraft => 'Delete draft';

  @override
  String get recipientEmail => 'Recipient email';

  @override
  String get separateMultipleAddressesWithCommas =>
      'Separate multiple addresses with commas';

  @override
  String get afterSavingReviewTheNewConfirmationCard =>
      'After saving, review the new confirmation card before sending.';

  @override
  String get saveRecipients => 'Save recipients';

  @override
  String get draftAnswerPrompt =>
      'Write a formal email based on this answer in the current conversation:';

  @override
  String get draftAnswerPromptSuffix =>
      'For me to review and confirm before sending.';

  @override
  String get turnThisAnswerIntoAnEmail => 'Turn this answer into an email';

  @override
  String get viewOriginalOfOlderVersion => 'View original of older version';

  @override
  String get messageActions => 'Message actions';

  @override
  String get needsVerification => 'Needs verification';

  @override
  String get sending => 'Sending';

  @override
  String get sendFailed => 'Send failed';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String attachmentCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 attachments',
      one: '1 attachment',
    );
    return '$_temp0';
  }

  @override
  String select(String p0) {
    return 'Select $p0';
  }

  @override
  String get emailAndModelConnectionsRequireAndroidUse =>
      'Email and model connections require Android. Use the UI preview here.';

  @override
  String get notConnectedToTheAndroidMailService =>
      'Not connected to the Android mail service. Fully close and reopen the latest APK. Use the preview entry point in browsers and Widget Preview.';

  @override
  String get actionIncomplete => 'Action incomplete';

  @override
  String get thisFeatureIsUnavailableInTheCurrent =>
      'This feature is unavailable in the current environment';

  @override
  String get pin => 'Pin';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get previousDays => 'Previous 7 days';

  @override
  String get previousDays86 => 'Previous 30 days';

  @override
  String olderConversationDate(String p0, String p1, String p2) {
    return '$p0-$p1-$p2';
  }

  @override
  String get loadingConversations => 'Loading conversations';

  @override
  String get noMatchingConversations => 'No matching conversations';

  @override
  String get yourConversationsWillAppearHere =>
      'Your conversations will appear here';

  @override
  String get tryShorterKeywordsOrClearTheSearch =>
      'Try shorter keywords or clear the search.';

  @override
  String get startAChatAndComeBackAnytime =>
      'Start a chat and come back anytime.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get startAConversation => 'Start a conversation';

  @override
  String get couldNotLoadConversationsTapToRetry =>
      'Could not load conversations. Tap to retry.';

  @override
  String get renameConversation => 'Rename conversation';

  @override
  String get enterConversationName => 'Enter conversation name';

  @override
  String get save => 'Save';

  @override
  String deleteConversationCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: 'Delete $p0 conversations?',
      one: 'Delete 1 conversation?',
    );
    return '$_temp0';
  }

  @override
  String get chatsSummariesAndAnalysisCachesForThese =>
      'Chats, summaries and analysis caches for these conversations will be deleted. Emails and drafts are retained.';

  @override
  String get rename => 'Rename';

  @override
  String get unpin => 'Unpin';

  @override
  String get selectMultiple => 'Select multiple';

  @override
  String selectedConversationCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 conversations selected',
      one: '1 conversation selected',
    );
    return '$_temp0';
  }

  @override
  String get exitSelection => 'Exit selection';

  @override
  String get closeSidebar => 'Close sidebar';

  @override
  String get searchConversations => 'Search conversations…';

  @override
  String get conversationSummary => 'Conversation summary';

  @override
  String get loading => 'Loading…';

  @override
  String get loadMore => 'Load more';

  @override
  String get selectConversations => 'Select conversations';

  @override
  String get settings => 'Settings';

  @override
  String get thisConversationSSummary => 'This conversation’s summary';

  @override
  String summarizedMessageCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 earlier messages summarized',
      one: '1 earlier message summarized',
    );
    return '$_temp0';
  }

  @override
  String get closeSummary => 'Close summary';

  @override
  String get originalMessagesAreRetainedYouCanAdd =>
      'Original messages are retained. You can add information or corrections.';

  @override
  String get noSummaryForThisConversationYet =>
      'No summary for this conversation yet.';

  @override
  String get conversationChangedPleaseReopenTheSummary =>
      'Conversation changed. Please reopen the summary.';

  @override
  String get draftingReadOnlyPreview => 'Drafting · read-only preview';

  @override
  String get incompleteCannotSend => 'Incomplete · cannot send';

  @override
  String get draftingEmail => 'Drafting email';

  @override
  String get generatingResponse => 'Generating response';

  @override
  String get readingImages => 'Reading images';

  @override
  String get preparingMaterials => 'Preparing materials';

  @override
  String get generatingContent => 'Generating content';

  @override
  String get parsingModelAction => 'Parsing model action';

  @override
  String get organizingExistingResults => 'Organizing existing results';

  @override
  String get organizingContext => 'Organizing context';

  @override
  String get webSearch => 'Web search';

  @override
  String get currentRequest => 'Current request';

  @override
  String get requestId => 'Request ID';

  @override
  String get serverId => 'Server ID';

  @override
  String get httpStatus => 'HTTP status';

  @override
  String get finishReason => 'Finish reason';

  @override
  String get exceptionType => 'Exception type';

  @override
  String get validationResult => 'Validation result';

  @override
  String get requestBudgetAndDiagnostics => 'Request budget and diagnostics';

  @override
  String get connectionDiagnostics => 'Connection diagnostics';

  @override
  String get requestRecordsForThisTurn => 'Request records for this turn';

  @override
  String get closeDiagnostics => 'Close diagnostics';

  @override
  String get processingStage => 'Processing stage';

  @override
  String get model => 'Model';

  @override
  String get apiHost => 'API host';

  @override
  String get imageProcessing => 'Image processing';

  @override
  String get fullTextAndImageResponse => 'Full text and image response';

  @override
  String get visionAssistantReading => 'Vision assistant reading';

  @override
  String get batchProcessingSelectedForThisTurn =>
      'Batch processing selected for this turn';

  @override
  String get reusingPreviousAnalysis => 'Reusing previous analysis';

  @override
  String get requestsWithImages => 'Requests with images';

  @override
  String requestCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 requests',
      one: '1 request',
    );
    return '$_temp0';
  }

  @override
  String get totalImagesUploaded => 'Total images uploaded';

  @override
  String imageCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 images',
      one: '1 image',
    );
    return '$_temp0';
  }

  @override
  String get reusedImages => 'Reused images';

  @override
  String get batchingReason => 'Batching reason';

  @override
  String get estimatedInput => 'Estimated input';

  @override
  String get availableInputBudget => 'Available input budget';

  @override
  String get configuredContext => 'Configured context';

  @override
  String get outputReserve => 'Output reserve';

  @override
  String get thinkingReserve => 'Thinking reserve';

  @override
  String get suggestedSummaryLength => 'Suggested summary length';

  @override
  String get summaryBudgetLimit => 'Summary budget limit';

  @override
  String get currentSummaryEstimate => 'Current summary estimate';

  @override
  String get localEstimatesMayDifferFromProviderMetering =>
      'Local estimates may differ from provider metering. Organization starts at 95% and targets 60%.';

  @override
  String get timeToFirstChunk => 'Time to first chunk';

  @override
  String get lastChunkReceived => 'Last chunk received';

  @override
  String get requestDuration => 'Request duration';

  @override
  String get technicalDetails => 'Technical details';

  @override
  String get requestIdsAndExceptionInformation =>
      'Request IDs and exception information';

  @override
  String get convertedToEmailBodyReviewBeforeSaving =>
      'Converted to email body. Review before saving.';

  @override
  String get conversionFailedOriginalTextRetained =>
      'Conversion failed. Original text retained.';

  @override
  String get discardUnsavedChanges => 'Discard unsaved changes?';

  @override
  String get savedDraftsAreRetained => 'Saved drafts are retained.';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String get deleteThisLocalRecord => 'Delete this local record?';

  @override
  String get serverEmailsAreRetained => 'Server emails are retained.';

  @override
  String get composeEmail => 'Compose email';

  @override
  String get back => 'Back';

  @override
  String get moreEmailActions => 'More email actions';

  @override
  String get saveChangesAndRewrite => 'Save changes and rewrite';

  @override
  String get convertMarkdownToBodyText => 'Convert Markdown to body text';

  @override
  String get sendingAccount => 'Sending account';

  @override
  String get subject => 'Subject';

  @override
  String get body => 'Body';

  @override
  String get sendAsThePlainTextShownHere => 'Send as the plain text shown here';

  @override
  String get ccBcc => 'Cc / Bcc';

  @override
  String remove(String p0) {
    return 'Remove $p0';
  }

  @override
  String get firstCheckTheServerSSentFolder =>
      'First check the server’s sent folder and whether recipients received the email.';

  @override
  String get verifiedThatSendingSucceeded => 'Verified that sending succeeded?';

  @override
  String get thisOnlyUpdatesTheLocalRecord =>
      'This only updates the local record.';

  @override
  String get verifiedSentSuccessfully => 'Verified: sent successfully';

  @override
  String get confirmedThatNoRecipientsReceivedIt =>
      'Confirmed that no recipients received it?';

  @override
  String get restoreTheDraftToReviewAndSend =>
      'Restore the draft to review and send again. If some recipients already received it, edit the recipients first.';

  @override
  String get restoreDraft => 'Restore draft';

  @override
  String get verifiedNotSent => 'Verified: not sent';

  @override
  String get confirmSendingInChat => 'Confirm sending in chat';

  @override
  String get confirmBeforeSending => 'Confirm before sending';

  @override
  String get pleaseReviewTheFollowing => 'Please review the following';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get couldNotReadAttachment => 'Could not read attachment';

  @override
  String get couldNotReadImagePleaseRetry =>
      'Could not read image. Please retry.';

  @override
  String get couldNotReadPagePleaseRetry =>
      'Could not read page. Please retry.';

  @override
  String get reload => 'Reload';

  @override
  String get referencedMaterial => 'Referenced material';

  @override
  String get formattedView => 'Formatted view';

  @override
  String get viewOriginal => 'View original';

  @override
  String get theFollowingWasGeneratedByAVision =>
      'The following was generated by a vision model. Compare it with the original image if needed.';

  @override
  String get previousPage => 'Previous page';

  @override
  String get nextPage => 'Next page';

  @override
  String get loadingReferencedMaterial => 'Loading referenced material…';

  @override
  String get selectedImageOrPdfPagePinchTo =>
      'Selected image or PDF page. Pinch to zoom.';

  @override
  String get imageUnavailableRetryOrOpenWithAnother =>
      'Image unavailable. Retry or open with another app.';

  @override
  String get pinchToZoomSavingAndExternalOpening =>
      'Pinch to zoom · saving and external opening use the original attachment';

  @override
  String get mail => 'Mail';

  @override
  String get myEmails => 'My emails';

  @override
  String get draftsAndSending => 'Drafts and sending';

  @override
  String get emailAccounts => 'Email accounts';

  @override
  String get addEmailAccount => 'Add email account';

  @override
  String get modelsAndServices => 'Models and services';

  @override
  String get defaultModel => 'Default model';

  @override
  String get visionAssistant => 'Vision assistant';

  @override
  String get addModel => 'Add model';

  @override
  String get automaticCurrentModelPreferred =>
      'Automatic · current model preferred';

  @override
  String fixedAssistant(String p0) {
    return 'Fixed assistant · $p0';
  }

  @override
  String get configurationUnavailable => 'Configuration unavailable';

  @override
  String get chooseAutomatically => 'Choose automatically';

  @override
  String get searchAndVoice => 'Search and voice';

  @override
  String get webServicesAndSpeechRecognition =>
      'Web services and speech recognition';

  @override
  String get preferences => 'Preferences';

  @override
  String get contextOrganization => 'Context organization';

  @override
  String get fastOrganizationResponseSettingsUnchanged =>
      'Fast organization · response settings unchanged';

  @override
  String get followCurrentThinkingMode => 'Follow current thinking mode';

  @override
  String get fastOrganizationNonThinkingModeOnSupported =>
      'Fast organization (non-thinking mode on supported APIs)';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemDefault => 'System default';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get backgroundSync => 'Background sync';

  @override
  String get off => 'Off';

  @override
  String get hourly => 'Hourly';

  @override
  String get onceADay => 'Once a day';

  @override
  String everyMinutes(String p0) {
    return 'Every $p0 minutes';
  }

  @override
  String get everyMinutes242 => 'Every 30 minutes';

  @override
  String get clearCacheAndChats => 'Clear cache and chats';

  @override
  String get clearLocalCache => 'Clear local cache?';

  @override
  String get downloadedAttachmentsPagePreviewsAllChatsAnd =>
      'Downloaded attachments, page previews, all chats and context summaries will be cleared. Email and model settings and draft attachments are retained.';

  @override
  String versionAndSendConfirmation(String p0) {
    return 'MailPilot $p0\nEvery email is sent only with your confirmation.';
  }

  @override
  String get custom => 'Custom';

  @override
  String get appPassword => 'App password';

  @override
  String get alibabaBusiness => 'Alibaba Business';

  @override
  String get passwordSecurityPassword => 'Password / security password';

  @override
  String get alibabaPersonal => 'Alibaba Personal';

  @override
  String get emailPassword => 'Email password';

  @override
  String get passwordAppPassword => 'Password / app password';

  @override
  String get leaveBlankToKeepSavedCredentials =>
      'Leave blank to keep saved credentials.';

  @override
  String get theAdministratorMustAllowThirdPartyClients =>
      'The administrator must allow third-party clients and IMAP/SMTP. If security passwords are enabled, use the third-party client security password.';

  @override
  String get enterTheFullEmailAddressAndPassword =>
      'Enter the full email address and password, and allow mail client access.';

  @override
  String get enableImapSmtpInYourEmailSettings =>
      'Enable IMAP/SMTP in your email settings, then obtain an app password.';

  @override
  String get useTheEmailPasswordOrAppPassword =>
      'Use the email password or app password required by your provider.';

  @override
  String get hideCredentials => 'Hide credentials';

  @override
  String get showCredentials => 'Show credentials';

  @override
  String get connectEmail => 'Connect email';

  @override
  String get emailSettings => 'Email settings';

  @override
  String mail263(String p0) {
    return '$p0 Mail';
  }

  @override
  String mail264(String p0) {
    return '$p0 Mail';
  }

  @override
  String get emailAddress => 'Email address';

  @override
  String get senderNameOptional => 'Sender name (optional)';

  @override
  String get emailSetupGuide => 'Email setup guide';

  @override
  String get connectionDetailsAndInstructions =>
      'Connection details and instructions';

  @override
  String officialGuide(String p0) {
    return '$p0 · official guide';
  }

  @override
  String get serverAndAdvancedSettings => 'Server and advanced settings';

  @override
  String get accountLabel => 'Account label';

  @override
  String get loginUsername => 'Login username';

  @override
  String get leaveBlankToUseTheFullEmail =>
      'Leave blank to use the full email address';

  @override
  String get imapHost => 'IMAP host';

  @override
  String get imapPort => 'IMAP port';

  @override
  String get incomingEncryption => 'Incoming encryption';

  @override
  String get smtpHost => 'SMTP host';

  @override
  String get smtpPort => 'SMTP port';

  @override
  String get outgoingEncryption => 'Outgoing encryption';

  @override
  String get testConnection => 'Test connection';

  @override
  String get saveAccount => 'Save account';

  @override
  String get deleteThisAccount => 'Delete this account?';

  @override
  String get localEmailsDraftsAndAnalysisForThis =>
      'Local emails, drafts and analysis for this account will be deleted. Server emails are retained.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get modelOptions => 'Model options';

  @override
  String get closeModelOptions => 'Close model options';

  @override
  String get defaultTextModel => 'Default text model';

  @override
  String get forEverydayChatAndEmailDrafting =>
      'For everyday chat and email drafting';

  @override
  String get useAsFixedVisionAssistant => 'Use as fixed vision assistant';

  @override
  String get forReadingImagesAndPdfPages => 'For reading images and PDF pages';

  @override
  String get connectionDiagnosticsOptional =>
      'Connection diagnostics (optional)';

  @override
  String get sendTextStreamingToolAndImageRequests =>
      'Send text, streaming, tool and image requests';

  @override
  String get deleteModel => 'Delete model';

  @override
  String get deleteLocalConfigurationAndKeyAfterConfirmation =>
      'Delete local configuration and key after confirmation';

  @override
  String get deleteThisModel => 'Delete this model?';

  @override
  String get theLocalConfigurationAndKeyWillBe =>
      'The local configuration and key will be deleted.';

  @override
  String get setAsFixedVisionAssistant => 'Set as fixed vision assistant';

  @override
  String get setAsDefaultTextModel => 'Set as default text model';

  @override
  String get savedLeaveBlankToRetain => 'Saved · leave blank to retain';

  @override
  String get hideKey => 'Hide key';

  @override
  String get showKey => 'Show key';

  @override
  String get providerDefault => 'Provider default';

  @override
  String get enableThinking => 'Enable thinking';

  @override
  String get disableThinking => 'Disable thinking';

  @override
  String get letTheModelDecide => 'Let the model decide';

  @override
  String get modelSettings => 'Model settings';

  @override
  String get connectionConfiguration => 'Connection configuration';

  @override
  String get modelProvider => 'Model provider';

  @override
  String get autoDetect => 'Auto-detect';

  @override
  String autoDetect310(String p0) {
    return 'Auto-detect · $p0';
  }

  @override
  String get configurationName => 'Configuration name';

  @override
  String get apiUrl => 'API URL';

  @override
  String get modelName => 'Model name';

  @override
  String get selectABundledModel => 'Select a bundled model';

  @override
  String get youCanAlsoEnterTheModelName =>
      'You can also enter the model name directly';

  @override
  String get bundledModels => 'Bundled models';

  @override
  String get advancedParameters => 'Advanced parameters';

  @override
  String get thinkingModeEffortAndOutputLength =>
      'Thinking mode, effort and output length';

  @override
  String get thinkingMode => 'Thinking mode';

  @override
  String get useProviderDefaultsWithoutExtraThinkingParameters =>
      'Use provider defaults without extra thinking parameters';

  @override
  String get askTheModelToThinkDeeply => 'Ask the model to think deeply';

  @override
  String get askTheModelToAnswerDirectly => 'Ask the model to answer directly';

  @override
  String get letTheModelDecideWhetherThinkingIs =>
      'Let the model decide whether thinking is needed';

  @override
  String get thinkingEffort => 'Thinking effort';

  @override
  String get higherEffortUsuallyTakesLongerAndUses =>
      'Higher effort usually takes longer and uses more tokens. Available levels depend on the model.';

  @override
  String get thinkingBudgetTokens => 'Thinking budget (tokens)';

  @override
  String get blankOrUsesProviderDefaultsChooseEither =>
      'Blank or 0 uses provider defaults. Choose either a budget or an effort level.';

  @override
  String get contextSettings => 'Context settings';

  @override
  String get followModelSpecification => 'Follow model specification';

  @override
  String get officialApisUseVerifiedContextLimitsFor =>
      'Official APIs use verified context limits for the model';

  @override
  String get setALocalBudgetWithinTheProvider =>
      'Set a local budget within the provider’s limit';

  @override
  String currentContextTokens(String p0, String p1) {
    return 'Current context: $p0 tokens. $p1';
  }

  @override
  String get planApiLimitsAreUnverifiedCurrentSettings =>
      'Plan API limits are unverified. Current settings are retained; standard API limits are not applied.';

  @override
  String get thisApiOrModelIsNotIn =>
      'This API or model is not in the catalog. You can set a custom budget.';

  @override
  String currentContextTokensOfficialMaximumInputTokens(
    String p0,
    String p1,
    String p2,
    String p3,
  ) {
    return 'Current context: $p0 tokens\nOfficial maximum input: $p1 tokens · $p2\nCatalog verified on $p3. Output space is reserved from the context.';
  }

  @override
  String get nonThinking => 'Non-thinking';

  @override
  String get thinkingDefault => 'Thinking / default';

  @override
  String get contextIsOrganizedAtOfTheEffective =>
      'Context is organized at 95% of the effective input budget, targeting 60%. Original records are retained.';

  @override
  String get maximumOutputLength => 'Maximum output length';

  @override
  String get useModelMaximum => 'Use model maximum';

  @override
  String get useTheVerifiedMaximumOutputForThe =>
      'Use the verified maximum output for the actual model';

  @override
  String get keepYourCustomOutputLength => 'Keep your custom output length';

  @override
  String get theMaximumOutputForThisApiIs =>
      'The maximum output for this API is unverified. Using 4096 tokens; you can choose a custom value.';

  @override
  String modelMaximumOutputTokensRequestsAdjustTo(String p0) {
    return 'Model maximum output: $p0 tokens. Requests adjust to remaining context; the model may finish earlier.';
  }

  @override
  String get contextLength => 'Context length';

  @override
  String get customOutputLength => 'Custom output length';

  @override
  String get lengthsAreInTokensSomeModelsCount =>
      'Lengths are in tokens. Some models count thinking as output.';

  @override
  String get outputLengthParameter => 'Output length parameter';

  @override
  String get standardParameter => 'Standard parameter';

  @override
  String get completionLengthParameter => 'Completion length parameter';

  @override
  String get chooseAccordingToTheProviderSApi =>
      'Choose according to the provider’s API. This does not change the entered output length.';

  @override
  String get notTested => 'Not tested';

  @override
  String get processing => 'Processing…';

  @override
  String get saveModel => 'Save model';

  @override
  String emailCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 emails',
      one: '1 email',
    );
    return '$_temp0';
  }

  @override
  String expandEmailCount(int p0) {
    return 'Show all $p0';
  }

  @override
  String get previousEmailPage => 'Previous email page';

  @override
  String get nextEmailPage => 'Next email page';

  @override
  String get collapse => 'Collapse';

  @override
  String get qqMail => 'QQ Mail';

  @override
  String get enableMailServices => 'Enable mail services';

  @override
  String get signInToQqMailInA =>
      'Sign in to QQ Mail in a desktop browser. Under Settings → Account and security → Security, enable POP3/IMAP/SMTP.';

  @override
  String get generateAnAppPassword => 'Generate an app password';

  @override
  String get completeIdentityVerificationOnTheOfficialPage =>
      'Complete identity verification on the official page, generate a 16-character app password and enter it here.';

  @override
  String get returnToAccountForm => 'Return to account form';

  @override
  String get enterTheFullEmailAddressServersAre =>
      'Enter the full email address. Servers are prefilled. Test the connection before saving.';

  @override
  String get getAndManageAppPasswords => 'Get and manage app passwords';

  @override
  String get mail368 => '163 Mail';

  @override
  String get enableImapSmtp => 'Enable IMAP/SMTP';

  @override
  String get signInToWebmailFindPopSmtp =>
      'Sign in to 163 webmail. Find POP3/SMTP/IMAP in settings and enable IMAP/SMTP.';

  @override
  String get getAClientAppPassword => 'Get a client app password';

  @override
  String get completeTheVerificationAsInstructedAndEnter =>
      'Complete the verification as instructed and enter the generated client password here.';

  @override
  String get checkTheFullEmailAddress => 'Check the full email address';

  @override
  String get useYourFullComAddressIfYou =>
      'Use your full @163.com address. If you cannot find the setting, search for “授权码” or “IMAP” in NetEase’s official help center.';

  @override
  String get neteaseMailOfficialHelp => 'NetEase Mail official help';

  @override
  String get alibabaBusinessMail => 'Alibaba Business Mail';

  @override
  String get checkClientPermissions => 'Check client permissions';

  @override
  String get askTheAdministratorToAllowThirdParty =>
      'Ask the administrator to allow third-party clients and enable IMAP/SMTP for this account. New business accounts may block third-party clients by default.';

  @override
  String get prepareASecurityPassword => 'Prepare a security password';

  @override
  String get inWebmailGoToSettingsAccountAnd =>
      'In webmail, go to Settings → Account and security and generate a third-party client security password. Use it here once enabled.';

  @override
  String get enterTheBusinessEmailAddress => 'Enter the business email address';

  @override
  String get useTheFullBusinessAddressDefaultServers =>
      'Use the full business address. Default servers are prefilled; change them in advanced settings for Hong Kong or company-specific configurations.';

  @override
  String get allowThirdPartyClients => 'Allow third-party clients';

  @override
  String get generateAThirdPartyClientSecurityPassword =>
      'Generate a third-party client security password';

  @override
  String get serverAddressesAndPorts => 'Server addresses and ports';

  @override
  String get alibabaPersonalMail => 'Alibaba Personal Mail';

  @override
  String get checkAccountType => 'Check account type';

  @override
  String get thisPresetIsForFreeAlibabaCloud =>
      'This preset is for free Alibaba Cloud personal mail. For accounts using a company domain, choose Alibaba Business.';

  @override
  String get prepareLoginDetails => 'Prepare login details';

  @override
  String get enterTheFullEmailAddressAndRequired =>
      'Enter the full email address and required credentials. Ensure mail client access is allowed.';

  @override
  String get checkServers => 'Check servers';

  @override
  String get useTheOfficialSslServerSettingsBelow =>
      'Use the official SSL server settings below. Test the connection before saving.';

  @override
  String get personalMailServersAndPorts => 'Personal mail servers and ports';

  @override
  String get customEmailProvider => 'Custom email provider';

  @override
  String get identifyYourProvider => 'Identify your provider';

  @override
  String get aCustomDomainDoesNotIdentifyThe =>
      'A custom domain does not identify the email provider. Check with your email administrator.';

  @override
  String get getConnectionSettings => 'Get connection settings';

  @override
  String get prepareImapAndSmtpHostsPortsEncryption =>
      'Prepare IMAP and SMTP hosts, ports, encryption and a password or app password.';

  @override
  String get enterAndVerify => 'Enter and verify';

  @override
  String get expandServerAndAdvancedSettingsAndEnter =>
      'Expand Server and advanced settings and enter the details from your provider.';

  @override
  String setupGuide(String p0) {
    return '$p0 setup guide';
  }

  @override
  String get closeSetupGuide => 'Close setup guide';

  @override
  String get defaultServersSsl => 'Default servers · SSL';

  @override
  String incomingPortOutgoingPort(String p0, String p1) {
    return 'Incoming  $p0\nPort 993\n\nOutgoing  $p1\nPort 465';
  }

  @override
  String get officialHelp => 'Official help';

  @override
  String verifiedOfficialPagesOpenInYourBrowser(String p0) {
    return 'Verified: $p0 · official pages open in your browser';
  }

  @override
  String get returnToForm => 'Return to form';

  @override
  String get mailpilotPreview => 'MailPilot · Preview';

  @override
  String get thisLinkIsNotAValidWeb => 'This link is not a valid web address';

  @override
  String get openWebpage => 'Open webpage';

  @override
  String get copyLink => 'Copy link';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String image(String p0) {
    return '[Image $p0]';
  }

  @override
  String get sizeUnknown => 'Size unknown';

  @override
  String get firstPagesByDefaultPageCountPending =>
      'First 10 pages by default; page count pending';

  @override
  String get selectPdfPageNumbers => 'Select PDF page numbers';

  @override
  String page(String p0) {
    return 'Page $p0';
  }

  @override
  String get fileName => 'File name';

  @override
  String get deselect => 'Deselect';

  @override
  String get select420 => 'Select';

  @override
  String get materialsForThisAnalysis => 'Materials for this analysis';

  @override
  String materialSummary(String p0, String p1, String p2) {
    return '$p0 attachments · $p1$p2';
  }

  @override
  String withUnknownSize(String p0) {
    return ' · $p0 with unknown size';
  }

  @override
  String get closeMaterials => 'Close materials';

  @override
  String upToAttachmentsMbAndImagesOr(String p0) {
    return 'Up to 10 attachments, 50 MB and 20 images or PDF pages per turn.\n$p0';
  }

  @override
  String get actualImageCountsInPdfAndOffice =>
      'Actual image counts in PDF and Office files are checked when reading.';

  @override
  String get selectedFilesAreReadOnlyWhenPreviewing =>
      'Selected files are read only when previewing or asking a question.';

  @override
  String get attachmentListAwaitingSync => 'Attachment list awaiting sync';

  @override
  String get selectAllSupportedAttachments =>
      'Select all supported attachments';

  @override
  String get keepBodyOnly => 'Keep body only';

  @override
  String get deviceFiles => 'Device files';

  @override
  String get noMaterialsSelectedAddFilesOrSelect =>
      'No materials selected. Add files or select emails.';

  @override
  String get materialCheckIncomplete => 'Material check incomplete';

  @override
  String get retryWithCurrentMaterials => 'Retry with current materials';

  @override
  String get analyzedImages => 'Analyzed images';

  @override
  String get previousAnalysisIsReusedByDefaultSelect =>
      'Previous analysis is reused by default. Select recheck for new details; it applies to the next message.';

  @override
  String get cancelRecheck => 'Cancel recheck';

  @override
  String get recheckImages => 'Recheck images';

  @override
  String get previousVersion => 'Previous version';

  @override
  String messageVersionCount(String p0, String p1) {
    return 'Version $p0 of $p1';
  }

  @override
  String get nextVersion => 'Next version';

  @override
  String get closeMessageActions => 'Close message actions';

  @override
  String get copyMessage => 'Copy message';

  @override
  String get messageCopied => 'Message copied';

  @override
  String close(String p0) {
    return 'Close $p0';
  }

  @override
  String get volcengineArk => 'Volcengine · Ark';

  @override
  String get alibabaCloudModelStudio => 'Alibaba Cloud · Model Studio';

  @override
  String get openaiCompatibleApi => 'OpenAI-compatible API';

  @override
  String get minimalMinimal => 'Minimal · minimal';

  @override
  String get lowLow => 'Low · low';

  @override
  String get mediumMedium => 'Medium · medium';

  @override
  String get highHigh => 'High · high';

  @override
  String get veryHighXhigh => 'Very high · xhigh';

  @override
  String get maximumMax => 'Maximum · max';

  @override
  String get chooseImageProcessing => 'Choose image processing';

  @override
  String get yourQuestionMaterialsAndCompletedAnalysisAre =>
      'Your question, materials and completed analysis are retained.';

  @override
  String get adjustMaterials => 'Adjust materials';

  @override
  String get reduceImagesPagesOrTextAndSubmit =>
      'Reduce images, pages or text and submit again';

  @override
  String get processThisTurnInBatches => 'Process this turn in batches';

  @override
  String get readUnfinishedImagesInBatchesThenSummarize =>
      'Read unfinished images in batches, then summarize';

  @override
  String get couldNotReadThisPage => 'Could not read this page';

  @override
  String get couldNotReadThisPagePleaseRetry =>
      'Could not read this page. Please retry.';

  @override
  String get closePagePreview => 'Close page preview';

  @override
  String get pageImageUnavailable => 'Page image unavailable';

  @override
  String get selectPdfPages => 'Select PDF pages';

  @override
  String pagesTotal(String p0) {
    return ' · $p0 pages total';
  }

  @override
  String pagesSelectedMaximum(String p0) {
    return '$p0 pages selected / maximum 20';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get firstPages => 'First 10 pages';

  @override
  String get clear => 'Clear';

  @override
  String get readingPdf => 'Reading PDF…';

  @override
  String get couldNotReadPageNumbers => 'Could not read page numbers';

  @override
  String get retryReading => 'Retry reading';

  @override
  String get selectUpToPagesPerPdf => 'Select up to 20 pages per PDF';

  @override
  String get deselectThisAttachment => 'Deselect this attachment';

  @override
  String confirmSelectionPages(String p0) {
    return 'Confirm selection · $p0 pages';
  }

  @override
  String get retryPreview => 'Retry preview';

  @override
  String previewPage(String p0) {
    return 'Preview page $p0';
  }

  @override
  String get loadingPreview => 'Loading preview…';

  @override
  String page480(String p0, String p1) {
    return '$p0, page $p1';
  }

  @override
  String reasoningSegmentHeading(String p0) {
    return 'Thinking $p0\n';
  }

  @override
  String get searching => 'Searching';

  @override
  String get searchIncomplete => 'Search incomplete';

  @override
  String searchResultCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: 'Found $p0 results',
      one: 'Found 1 result',
    );
    return '$_temp0';
  }

  @override
  String get readingWebpages => 'Reading webpages';

  @override
  String readWebpageCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: 'Read $p0 webpages',
      one: 'Read 1 webpage',
    );
    return '$_temp0';
  }

  @override
  String get webpageReadingFinished => 'Webpage reading finished';

  @override
  String get readingMaterials => 'Reading materials';

  @override
  String get sourceExcerptViewed => 'Source excerpt viewed';

  @override
  String get materialsReused => 'Materials reused';

  @override
  String get searchingEmails => 'Searching emails';

  @override
  String get emailsSearched => 'Emails searched';

  @override
  String get processing493 => 'Processing';

  @override
  String get actionCompleted => 'Action completed';

  @override
  String get lessThanSecond => 'Less than 1 second';

  @override
  String elapsedSeconds(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String get thinking497 => 'Thinking';

  @override
  String get thinkingStopped => 'Thinking stopped';

  @override
  String get thinkingInterrupted => 'Thinking interrupted';

  @override
  String get process => 'Process';

  @override
  String get thought => 'Thought';

  @override
  String get reasoning => 'Reasoning';

  @override
  String get viewReasoning => 'View reasoning';

  @override
  String get currentAttempt => 'Current attempt';

  @override
  String get previousAttempt => 'Previous attempt';

  @override
  String earlierAttempt(String p0) {
    return 'Earlier attempt $p0';
  }

  @override
  String get viewingAPreviousAttempt => 'Viewing a previous attempt';

  @override
  String get reasoningIsLongTheFirstCharactersHave =>
      'Reasoning is long. The first 128000 characters have been retained.';

  @override
  String get jumpToEndOfReasoning => 'Jump to end of reasoning';

  @override
  String get uiPreviewSampleDataInstallAndroidTo =>
      'UI preview · sample data. Install Android to connect email and models.';

  @override
  String get dismissNotice => 'Dismiss notice';

  @override
  String get backToHome => 'Back to home';

  @override
  String get backToSettings => 'Back to settings';

  @override
  String get backToConversation => 'Back to conversation';

  @override
  String get openMenu => 'Open menu';

  @override
  String get noVersionsAvailable => 'No versions available';

  @override
  String get couldNotLoadVersionsPleaseRetry =>
      'Could not load versions. Please retry.';

  @override
  String get cannotEditThisQuestion => 'Cannot edit this question';

  @override
  String get couldNotEditThisQuestionPleaseRetry =>
      'Could not edit this question. Please retry.';

  @override
  String get editNotSubmittedPleaseRetry => 'Edit not submitted. Please retry.';

  @override
  String get addAModelFirst => 'Add a model first';

  @override
  String get materialCheckIncompletePleaseRetry =>
      'Material check incomplete. Please retry.';

  @override
  String get newConversation => 'New conversation';

  @override
  String get whatSOnYourMind => 'What’s on your mind?';

  @override
  String get letSMakeSenseOfYourEmails => 'Let’s make sense of your emails.';

  @override
  String get configureAModelToChatYouCan =>
      'Configure a model to chat. You can add email later.';

  @override
  String get askAQuestionOrSelectEmailsAs =>
      'Ask a question or select emails as context.';

  @override
  String get helpMeOrganizeMyThoughts => 'Help me organize my thoughts';

  @override
  String get helpMeWriteSomething => 'Help me write something';

  @override
  String get summarizeSelectedEmails => 'Summarize selected emails';

  @override
  String get helpMeDraftAReply => 'Help me draft a reply';

  @override
  String get retryWebSearch => 'Retry web search';

  @override
  String get answerWithoutSearch => 'Answer without search';

  @override
  String get continueSearching => 'Continue searching';

  @override
  String get responseIncomplete => 'Response incomplete';

  @override
  String get continueOrganizing => 'Continue organizing';

  @override
  String get retryThisTurn => 'Retry this turn';

  @override
  String get viewBudget => 'View budget';

  @override
  String get retryWithCompatibleFormat => 'Retry with compatible format';

  @override
  String get chooseProcessingMethod => 'Choose processing method';

  @override
  String get adjustMaterialsAndRetry => 'Adjust materials and retry';

  @override
  String get restoreDefaultThinkingAndRetry =>
      'Restore default thinking and retry';

  @override
  String get chooseVisionAssistant => 'Choose vision assistant';

  @override
  String get editConfiguration => 'Edit configuration';

  @override
  String vision(String p0) {
    return 'Vision · $p0';
  }

  @override
  String sourceCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 sources',
      one: '1 source',
    );
    return '$_temp0';
  }

  @override
  String get copyResponse => 'Copy response';

  @override
  String get originalMarkdownCopied => 'Original Markdown copied';

  @override
  String get responseStopped => 'Response stopped';

  @override
  String get stoppedThePartialResponseReceivedIsShown =>
      'Stopped. The partial response received is shown above.';

  @override
  String get reviewDraftAndSend => 'Review draft and send';

  @override
  String get writeAsEmail => 'Write as email';

  @override
  String get connectingToModel => 'Connecting to model…';

  @override
  String get viewingAnOlderVersion => 'Viewing an older version';

  @override
  String get backToLatest => 'Back to latest';

  @override
  String get textModel => 'Text model';

  @override
  String tapToCancelSync(String p0) {
    return '$p0 · tap to cancel sync';
  }

  @override
  String get syncLatestEmailsInEachFolder =>
      'Sync latest 50 emails in each folder';

  @override
  String get searchEmails => 'Search emails';

  @override
  String get emailActions => 'Email actions';

  @override
  String get syncEmailsPerFolder => 'Sync emails (50 per folder)';

  @override
  String get showAll => 'Show all';

  @override
  String get showUnread => 'Show unread';

  @override
  String get subjectOrSender => 'Subject or sender';

  @override
  String get runSearch => 'Run search';

  @override
  String get connectAnEmailAccountFirst => 'Connect an email account first';

  @override
  String get supportsQqAndCustomEmailProviders =>
      'Supports QQ, 163 and custom email providers.';

  @override
  String get noLocalEmailsYet => 'No local emails yet';

  @override
  String get pullDownToSyncRecentEmailsStartup =>
      'Pull down to sync recent emails. Startup does not sync automatically.';

  @override
  String analyzeSelectedEmails(String p0) {
    return 'Analyze $p0 selected emails';
  }

  @override
  String get emailDetails => 'Email details';

  @override
  String get replyAndForward => 'Reply and forward';

  @override
  String get reply => 'Reply';

  @override
  String get replyAll => 'Reply all';

  @override
  String get forward => 'Forward';

  @override
  String get recipientDetails => 'Recipient details';

  @override
  String toCc(String p0, String p1) {
    return 'To: $p0\nCc: $p1';
  }

  @override
  String get bodyAwaitingBackgroundSyncYouCanKeep =>
      'Body awaiting background sync. You can keep browsing other emails.';

  @override
  String attachments(String p0) {
    return 'Attachments · $p0';
  }

  @override
  String get tapAnAttachmentToPreviewSelectIt =>
      'Tap an attachment to preview; select it for AI analysis';

  @override
  String get askAssistant => 'Ask assistant';

  @override
  String get noDraftsYet => 'No drafts yet';

  @override
  String get writeYourOwnOrAskTheAssistant =>
      'Write your own or ask the assistant for a draft.';

  @override
  String get configurationSaved => 'Configuration saved';

  @override
  String get closeConfiguration => 'Close configuration';

  @override
  String get actionFailed => 'Action failed';

  @override
  String get backToConfiguration => 'Back to configuration';

  @override
  String get volcengineWebSearch => 'Volcengine web search';

  @override
  String get bocha => 'Bocha';

  @override
  String get systemPreferredCloudOptional => 'System preferred, cloud optional';

  @override
  String get qwenCloudTranscription => 'Qwen cloud transcription';

  @override
  String get automaticSystemRecognitionFollowsDeviceLanguage =>
      'Automatic (system recognition follows device language)';

  @override
  String get chinese => 'Chinese';

  @override
  String get searchProvider => 'Search provider';

  @override
  String get recognitionMode => 'Recognition mode';

  @override
  String get speechLanguage => 'Speech language';

  @override
  String get automatic => 'Automatic';

  @override
  String get systemRecognitionNeedsNoApiKeyIf =>
      'System recognition needs no API key. If your device has no recognition service, you can use Qwen ASR below.';

  @override
  String get usedOnlyWhenSmartSearchIsEnabled =>
      'Used only when smart search is enabled and you ask a question. The search service receives extracted keywords, not emails, attachments or chat history.';

  @override
  String get qwenAsrBaseUrl => 'Qwen ASR base URL';

  @override
  String get fullSearchApiUrl => 'Full search API URL';

  @override
  String get leaveBlankToRetainTheSavedKey =>
      'Leave blank to retain the saved key';

  @override
  String get showOrHideKey => 'Show or hide key';

  @override
  String get asrModel => 'ASR model';

  @override
  String get forExampleQwenAsrFlash => 'For example, qwen3-asr-flash';

  @override
  String get transcriptionFillsTheInputFieldOnlyReview =>
      'Transcription fills the input field only; review it before sending. Cloud mode requires a new recording, up to 60 seconds.';

  @override
  String get streamingUiStateIsOutOfSync =>
      'Streaming UI state is out of sync. Reopen this conversation.';

  @override
  String get streamNotReceivedCompletelyReopenThisConversation =>
      'Stream not received completely. Reopen this conversation.';

  @override
  String get appLanguage => 'Language';

  @override
  String get languageTitle => 'Choose language';

  @override
  String get languageDescription =>
      'Change interface language. Emails and conversations keep their original content.';
}
