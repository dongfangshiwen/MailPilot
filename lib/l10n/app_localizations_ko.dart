// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get switchAccount => '계정 전환';

  @override
  String get closeAccountPicker => '계정 선택 닫기';

  @override
  String switchAccountCurrent(String p0) {
    return '계정 전환, 현재: $p0';
  }

  @override
  String get openWithAnotherApp => '다른 앱으로 열기';

  @override
  String get openInAnotherApp => '다른 앱에서 열기';

  @override
  String get saveToDevice => '기기에 저장';

  @override
  String get couldNotStartRecording => '녹음을 시작할 수 없습니다';

  @override
  String get addImage => '이미지 추가';

  @override
  String get addFile => '파일 추가';

  @override
  String get selectEmails => '메일 선택';

  @override
  String get manageImportedMaterials => '가져온 자료 관리';

  @override
  String get deepThinking => '심층 사고';

  @override
  String get editInput => '입력 수정';

  @override
  String get cancelEdit => '수정 취소';

  @override
  String selectedMaterialsCount(int p0, int p1) {
    return '메일 $p0개 · 첨부 $p1개 선택됨';
  }

  @override
  String get clearSelection => '선택 해제';

  @override
  String get listeningUpToSeconds => '듣는 중 · 최대 60초';

  @override
  String get transcribing => '음성 인식 중…';

  @override
  String get startingMicrophone => '마이크 시작 중…';

  @override
  String get recordAgainInCloudMode => '클라우드 모드로 다시 녹음';

  @override
  String get cancelVoiceInput => '음성 입력 취소';

  @override
  String get askAboutSelectedMaterials => '선택한 자료에 질문하기…';

  @override
  String get messageOrUseVoiceInput => '메시지 또는 음성 입력';

  @override
  String get smartSearch => '스마트 검색';

  @override
  String get thinking => '사고';

  @override
  String get search => '검색';

  @override
  String get addAttachment => '첨부 추가';

  @override
  String get stopResponse => '응답 중지';

  @override
  String get stopRecording => '녹음 종료';

  @override
  String get sendQuestion => '질문 전송';

  @override
  String get voiceInput => '음성 입력';

  @override
  String get draftDeleted => '초안을 삭제했습니다';

  @override
  String get pleaseViewTheLatestVersion => '최신 버전을 확인하세요';

  @override
  String get from => '보낸 사람';

  @override
  String get to => '받는 사람';

  @override
  String get cc => '참조';

  @override
  String get bcc => '숨은 참조';

  @override
  String get notEntered => '미입력';

  @override
  String get noSubject => '(제목 없음)';

  @override
  String get afterReviewingConfirmSendingOrTapThe =>
      '내용을 검토한 후 전송을 확인하거나 아래 버튼을 누르세요.';

  @override
  String get confirmSend => '전송 확인';

  @override
  String get addRecipient => '받는 사람 추가';

  @override
  String get viewLatestVersion => '최신 버전 보기';

  @override
  String get reviewAndEdit => '검토 및 수정';

  @override
  String get editEmail => '메일 수정';

  @override
  String get jumpToLatestMessage => '최신 메시지로 이동';

  @override
  String get inbox => '받은편지함';

  @override
  String get sent => '보낸편지함';

  @override
  String get drafts => '초안';

  @override
  String get deleted => '삭제됨';

  @override
  String get spam => '스팸';

  @override
  String get archive => '보관함';

  @override
  String get mailFolders => '메일 폴더';

  @override
  String get refreshFolders => '폴더 새로고침';

  @override
  String couldNotRefreshFoldersLocalListRetained(String p0) {
    return '폴더를 새로고침하지 못했습니다. 로컬 목록은 유지됩니다. $p0';
  }

  @override
  String get unreadOnly => '읽지 않은 메일만';

  @override
  String get deleteThisDraft => '이 초안을 삭제할까요?';

  @override
  String get onlyTheLocalDraftIsDeletedChats =>
      '로컬 초안만 삭제됩니다. 대화와 서버 메일은 유지됩니다.';

  @override
  String get delete => '삭제';

  @override
  String get draftActions => '초안 작업';

  @override
  String get rewrite => '다시 작성';

  @override
  String get deleteDraft => '초안 삭제';

  @override
  String get recipientEmail => '수신 메일 주소';

  @override
  String get separateMultipleAddressesWithCommas => '여러 주소는 쉼표로 구분하세요';

  @override
  String get afterSavingReviewTheNewConfirmationCard =>
      '저장 후 새 확인 카드를 검토하고 전송하세요.';

  @override
  String get saveRecipients => '받는 사람 저장';

  @override
  String get draftAnswerPrompt => '현재 대화의 이 답변을 바탕으로 정식 메일을 작성해 주세요:';

  @override
  String get draftAnswerPromptSuffix => '전송 전에 검토하고 확인할 수 있도록 해 주세요.';

  @override
  String get turnThisAnswerIntoAnEmail => '이 답변으로 메일 작성';

  @override
  String get viewOriginalOfOlderVersion => '이전 버전 원문 보기';

  @override
  String get messageActions => '메시지 작업';

  @override
  String get needsVerification => '확인 필요';

  @override
  String get sending => '전송 중';

  @override
  String get sendFailed => '전송 실패';

  @override
  String get confirm => '확인';

  @override
  String get cancel => '취소';

  @override
  String attachmentCount(int p0) {
    return '첨부 $p0개';
  }

  @override
  String select(String p0) {
    return '$p0 선택';
  }

  @override
  String get emailAndModelConnectionsRequireAndroidUse =>
      '메일 및 모델 연결에는 Android가 필요합니다. 여기서는 UI 미리보기를 사용하세요.';

  @override
  String get notConnectedToTheAndroidMailService =>
      'Android 메일 서비스에 연결되지 않았습니다. 최신 APK를 완전히 닫았다가 다시 여세요. 브라우저와 Widget Preview에서는 미리보기 진입점을 사용하세요.';

  @override
  String get actionIncomplete => '작업 미완료';

  @override
  String get thisFeatureIsUnavailableInTheCurrent =>
      '현재 환경에서는 이 기능을 사용할 수 없습니다';

  @override
  String get pin => '고정';

  @override
  String get today => '오늘';

  @override
  String get yesterday => '어제';

  @override
  String get previousDays => '지난 7일';

  @override
  String get previousDays86 => '지난 30일';

  @override
  String olderConversationDate(String p0, String p1, String p2) {
    return '$p0년 $p1월 $p2일';
  }

  @override
  String get loadingConversations => '대화 불러오는 중';

  @override
  String get noMatchingConversations => '일치하는 대화가 없습니다';

  @override
  String get yourConversationsWillAppearHere => '대화가 여기에 저장됩니다';

  @override
  String get tryShorterKeywordsOrClearTheSearch =>
      '더 짧은 검색어를 사용하거나 검색을 지워 보세요.';

  @override
  String get startAChatAndComeBackAnytime => '대화를 시작한 후 언제든 이어갈 수 있습니다.';

  @override
  String get clearSearch => '검색 지우기';

  @override
  String get startAConversation => '대화 시작';

  @override
  String get couldNotLoadConversationsTapToRetry =>
      '대화를 불러오지 못했습니다. 탭하여 다시 시도하세요.';

  @override
  String get renameConversation => '대화 이름 변경';

  @override
  String get enterConversationName => '대화 이름 입력';

  @override
  String get save => '저장';

  @override
  String deleteConversationCount(int p0) {
    return '대화 $p0개를 삭제할까요?';
  }

  @override
  String get chatsSummariesAndAnalysisCachesForThese =>
      '해당 대화, 요약 및 분석 캐시가 삭제됩니다. 메일과 초안은 유지됩니다.';

  @override
  String get rename => '이름 변경';

  @override
  String get unpin => '고정 해제';

  @override
  String get selectMultiple => '여러 개 선택';

  @override
  String selectedConversationCount(int p0) {
    return '대화 $p0개 선택됨';
  }

  @override
  String get exitSelection => '선택 모드 종료';

  @override
  String get closeSidebar => '사이드바 닫기';

  @override
  String get searchConversations => '대화 내용 검색…';

  @override
  String get conversationSummary => '대화 요약';

  @override
  String get loading => '불러오는 중…';

  @override
  String get loadMore => '더 불러오기';

  @override
  String get selectConversations => '대화 선택';

  @override
  String get settings => '설정';

  @override
  String get thisConversationSSummary => '현재 대화 요약';

  @override
  String summarizedMessageCount(int p0) {
    return '이전 메시지 $p0개 요약됨';
  }

  @override
  String get closeSummary => '요약 닫기';

  @override
  String get originalMessagesAreRetainedYouCanAdd =>
      '원본 대화는 유지됩니다. 내용을 추가하거나 수정할 수 있습니다.';

  @override
  String get noSummaryForThisConversationYet => '이 대화에는 아직 요약이 없습니다.';

  @override
  String get conversationChangedPleaseReopenTheSummary =>
      '대화가 변경되었습니다. 요약을 다시 여세요.';

  @override
  String get draftingReadOnlyPreview => '초안 작성 중 · 읽기 전용 미리보기';

  @override
  String get incompleteCannotSend => '미완료 · 전송 불가';

  @override
  String get draftingEmail => '메일 초안 작성';

  @override
  String get generatingResponse => '답변 생성';

  @override
  String get readingImages => '이미지 읽기';

  @override
  String get preparingMaterials => '자료 준비';

  @override
  String get generatingContent => '내용 생성';

  @override
  String get parsingModelAction => '모델 작업 분석';

  @override
  String get organizingExistingResults => '기존 결과 정리';

  @override
  String get organizingContext => '컨텍스트 정리';

  @override
  String get webSearch => '웹 검색';

  @override
  String get currentRequest => '현재 요청';

  @override
  String get requestId => '요청 ID';

  @override
  String get serverId => '서버 ID';

  @override
  String get httpStatus => 'HTTP 상태';

  @override
  String get finishReason => '종료 사유';

  @override
  String get exceptionType => '예외 유형';

  @override
  String get validationResult => '검증 결과';

  @override
  String get requestBudgetAndDiagnostics => '현재 요청 예산 및 진단';

  @override
  String get connectionDiagnostics => '연결 진단';

  @override
  String get requestRecordsForThisTurn => '이번 턴 요청 기록';

  @override
  String get closeDiagnostics => '진단 닫기';

  @override
  String get processingStage => '처리 단계';

  @override
  String get model => '모델';

  @override
  String get apiHost => 'API 호스트';

  @override
  String get imageProcessing => '이미지 처리';

  @override
  String get fullTextAndImageResponse => '전체 이미지·텍스트 응답';

  @override
  String get visionAssistantReading => '시각 도우미로 읽기';

  @override
  String get batchProcessingSelectedForThisTurn => '이번 턴에 선택한 분할 처리';

  @override
  String get reusingPreviousAnalysis => '이전 분석 재사용';

  @override
  String get requestsWithImages => '이미지 포함 요청';

  @override
  String requestCount(int p0) {
    return '$p0회';
  }

  @override
  String get totalImagesUploaded => '총 업로드 이미지 수';

  @override
  String imageCount(int p0) {
    return '$p0장';
  }

  @override
  String get reusedImages => '재사용한 이미지';

  @override
  String get batchingReason => '분할 사유';

  @override
  String get estimatedInput => '예상 입력';

  @override
  String get availableInputBudget => '사용 가능한 입력 예산';

  @override
  String get configuredContext => '설정된 컨텍스트';

  @override
  String get outputReserve => '출력 예약량';

  @override
  String get thinkingReserve => '사고 예약량';

  @override
  String get suggestedSummaryLength => '권장 요약 길이';

  @override
  String get summaryBudgetLimit => '요약 예산 한도';

  @override
  String get currentSummaryEstimate => '현재 요약 추정량';

  @override
  String get localEstimatesMayDifferFromProviderMetering =>
      '로컬 추정치는 서비스 측정값과 다를 수 있습니다. 95%에서 정리를 시작하고 60%를 목표로 합니다.';

  @override
  String get timeToFirstChunk => '첫 청크까지 시간';

  @override
  String get lastChunkReceived => '마지막 청크 수신';

  @override
  String get requestDuration => '요청 소요 시간';

  @override
  String get technicalDetails => '기술 세부 정보';

  @override
  String get requestIdsAndExceptionInformation => '요청 ID 및 예외 정보';

  @override
  String get convertedToEmailBodyReviewBeforeSaving =>
      '메일 본문으로 변환했습니다. 검토 후 저장하세요.';

  @override
  String get conversionFailedOriginalTextRetained => '변환에 실패했습니다. 원문은 유지됩니다.';

  @override
  String get discardUnsavedChanges => '저장하지 않은 변경 사항을 버릴까요?';

  @override
  String get savedDraftsAreRetained => '저장된 초안은 유지됩니다.';

  @override
  String get discardChanges => '변경 사항 버리기';

  @override
  String get deleteThisLocalRecord => '이 로컬 기록을 삭제할까요?';

  @override
  String get serverEmailsAreRetained => '서버 메일은 유지됩니다.';

  @override
  String get composeEmail => '메일 작성';

  @override
  String get back => '뒤로';

  @override
  String get moreEmailActions => '추가 메일 작업';

  @override
  String get saveChangesAndRewrite => '변경 사항 저장 후 다시 작성';

  @override
  String get convertMarkdownToBodyText => 'Markdown을 본문으로 변환';

  @override
  String get sendingAccount => '보내는 계정';

  @override
  String get subject => '제목';

  @override
  String get body => '본문';

  @override
  String get sendAsThePlainTextShownHere => '여기 표시된 일반 텍스트로 전송';

  @override
  String get ccBcc => '참조 / 숨은 참조';

  @override
  String remove(String p0) {
    return '$p0 제거';
  }

  @override
  String get firstCheckTheServerSSentFolder => '먼저 서버의 보낸편지함과 수신 여부를 확인하세요.';

  @override
  String get verifiedThatSendingSucceeded => '전송 성공을 확인했나요?';

  @override
  String get thisOnlyUpdatesTheLocalRecord => '로컬 기록만 업데이트됩니다.';

  @override
  String get verifiedSentSuccessfully => '확인됨: 전송 성공';

  @override
  String get confirmedThatNoRecipientsReceivedIt =>
      '모든 받는 사람이 수신하지 않았음을 확인했나요?';

  @override
  String get restoreTheDraftToReviewAndSend =>
      '초안을 복원한 후 검토하고 다시 전송할 수 있습니다. 일부 수신자가 이미 받았다면 먼저 수신자를 수정하세요.';

  @override
  String get restoreDraft => '초안 복원';

  @override
  String get verifiedNotSent => '확인됨: 미전송';

  @override
  String get confirmSendingInChat => '대화에서 전송 확인';

  @override
  String get confirmBeforeSending => '전송 전 확인';

  @override
  String get pleaseReviewTheFollowing => '다음 내용을 확인하세요';

  @override
  String get accountDeleted => '계정 삭제됨';

  @override
  String get couldNotReadAttachment => '첨부를 읽을 수 없습니다';

  @override
  String get couldNotReadImagePleaseRetry => '이미지를 읽을 수 없습니다. 다시 시도하세요.';

  @override
  String get couldNotReadPagePleaseRetry => '페이지를 읽을 수 없습니다. 다시 시도하세요.';

  @override
  String get reload => '다시 불러오기';

  @override
  String get referencedMaterial => '인용 자료';

  @override
  String get formattedView => '서식 보기';

  @override
  String get viewOriginal => '원문 보기';

  @override
  String get theFollowingWasGeneratedByAVision =>
      '다음은 시각 모델이 이미지를 읽고 생성한 내용입니다. 필요하면 원본 이미지와 비교하세요.';

  @override
  String get previousPage => '이전 페이지';

  @override
  String get nextPage => '다음 페이지';

  @override
  String get loadingReferencedMaterial => '인용 자료 불러오는 중…';

  @override
  String get selectedImageOrPdfPagePinchTo =>
      '선택한 이미지 또는 PDF 페이지입니다. 두 손가락으로 확대할 수 있습니다.';

  @override
  String get imageUnavailableRetryOrOpenWithAnother =>
      '이미지를 표시할 수 없습니다. 다시 시도하거나 다른 앱으로 여세요.';

  @override
  String get pinchToZoomSavingAndExternalOpening =>
      '두 손가락으로 확대 · 저장 및 외부 열기는 원본 첨부 사용';

  @override
  String get mail => '메일';

  @override
  String get myEmails => '내 메일';

  @override
  String get draftsAndSending => '초안 및 전송';

  @override
  String get emailAccounts => '메일 계정';

  @override
  String get addEmailAccount => '메일 계정 추가';

  @override
  String get modelsAndServices => '모델 및 서비스';

  @override
  String get defaultModel => '기본 모델';

  @override
  String get visionAssistant => '시각 도우미';

  @override
  String get addModel => '모델 추가';

  @override
  String get automaticCurrentModelPreferred => '자동 선택 · 현재 모델 우선';

  @override
  String fixedAssistant(String p0) {
    return '고정 도우미 · $p0';
  }

  @override
  String get configurationUnavailable => '설정이 유효하지 않습니다';

  @override
  String get chooseAutomatically => '자동 선택';

  @override
  String get searchAndVoice => '검색 및 음성';

  @override
  String get webServicesAndSpeechRecognition => '웹 서비스, 음성 인식';

  @override
  String get preferences => '환경 설정';

  @override
  String get contextOrganization => '컨텍스트 정리';

  @override
  String get fastOrganizationResponseSettingsUnchanged => '빠른 정리 · 답변 설정 유지';

  @override
  String get followCurrentThinkingMode => '현재 사고 모드 따르기';

  @override
  String get fastOrganizationNonThinkingModeOnSupported =>
      '빠른 정리(지원 API에서 비사고 모드 사용)';

  @override
  String get appearance => '화면 스타일';

  @override
  String get systemDefault => '시스템 설정';

  @override
  String get light => '밝게';

  @override
  String get dark => '어둡게';

  @override
  String get backgroundSync => '백그라운드 동기화';

  @override
  String get off => '끄기';

  @override
  String get hourly => '매시간';

  @override
  String get onceADay => '하루 한 번';

  @override
  String everyMinutes(String p0) {
    return '$p0분마다';
  }

  @override
  String get everyMinutes242 => '30분마다';

  @override
  String get clearCacheAndChats => '캐시 및 대화 지우기';

  @override
  String get clearLocalCache => '로컬 캐시를 지울까요?';

  @override
  String get downloadedAttachmentsPagePreviewsAllChatsAnd =>
      '다운로드한 첨부, 페이지 미리보기, 모든 대화 및 요약이 삭제됩니다. 메일·모델 설정과 초안 첨부는 유지됩니다.';

  @override
  String versionAndSendConfirmation(String p0) {
    return 'MailPilot $p0\n메일은 매번 사용자가 확인한 후 전송됩니다.';
  }

  @override
  String get custom => '사용자 지정';

  @override
  String get appPassword => '앱 비밀번호';

  @override
  String get alibabaBusiness => 'Alibaba 기업';

  @override
  String get passwordSecurityPassword => '비밀번호 / 보안 비밀번호';

  @override
  String get alibabaPersonal => 'Alibaba 개인';

  @override
  String get emailPassword => '메일 비밀번호';

  @override
  String get passwordAppPassword => '비밀번호 / 앱 비밀번호';

  @override
  String get leaveBlankToKeepSavedCredentials => '저장된 인증 정보를 유지하려면 비워 두세요.';

  @override
  String get theAdministratorMustAllowThirdPartyClients =>
      '관리자가 외부 클라이언트와 IMAP/SMTP를 허용해야 합니다. 보안 비밀번호가 활성화되어 있으면 외부 클라이언트용 비밀번호를 사용하세요.';

  @override
  String get enterTheFullEmailAddressAndPassword =>
      '전체 메일 주소와 비밀번호를 입력하고 메일 클라이언트 접근을 허용하세요.';

  @override
  String get enableImapSmtpInYourEmailSettings =>
      '메일 설정에서 IMAP/SMTP를 켠 후 앱 비밀번호를 발급받으세요.';

  @override
  String get useTheEmailPasswordOrAppPassword =>
      '서비스에서 요구하는 메일 비밀번호 또는 앱 비밀번호를 사용하세요.';

  @override
  String get hideCredentials => '인증 정보 숨기기';

  @override
  String get showCredentials => '인증 정보 표시';

  @override
  String get connectEmail => '메일 연결';

  @override
  String get emailSettings => '메일 설정';

  @override
  String mail263(String p0) {
    return '$p0 메일';
  }

  @override
  String mail264(String p0) {
    return '$p0 메일';
  }

  @override
  String get emailAddress => '메일 주소';

  @override
  String get senderNameOptional => '보내는 사람 이름(선택)';

  @override
  String get emailSetupGuide => '메일 설정 안내';

  @override
  String get connectionDetailsAndInstructions => '연결 정보 및 입력 안내';

  @override
  String officialGuide(String p0) {
    return '$p0 · 공식 안내';
  }

  @override
  String get serverAndAdvancedSettings => '서버 및 고급 설정';

  @override
  String get accountLabel => '계정 표시 이름';

  @override
  String get loginUsername => '로그인 사용자 이름';

  @override
  String get leaveBlankToUseTheFullEmail => '비워 두면 전체 메일 주소 사용';

  @override
  String get imapHost => 'IMAP 호스트';

  @override
  String get imapPort => 'IMAP 포트';

  @override
  String get incomingEncryption => '수신 암호화';

  @override
  String get smtpHost => 'SMTP 호스트';

  @override
  String get smtpPort => 'SMTP 포트';

  @override
  String get outgoingEncryption => '발신 암호화';

  @override
  String get testConnection => '연결 테스트';

  @override
  String get saveAccount => '계정 저장';

  @override
  String get deleteThisAccount => '이 계정을 삭제할까요?';

  @override
  String get localEmailsDraftsAndAnalysisForThis =>
      '이 계정의 로컬 메일, 초안 및 분석이 삭제됩니다. 서버 메일은 유지됩니다.';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get modelOptions => '모델 옵션';

  @override
  String get closeModelOptions => '모델 옵션 닫기';

  @override
  String get defaultTextModel => '기본 텍스트 모델';

  @override
  String get forEverydayChatAndEmailDrafting => '일상 대화 및 메일 초안 작성에 사용';

  @override
  String get useAsFixedVisionAssistant => '고정 시각 도우미로 사용';

  @override
  String get forReadingImagesAndPdfPages => '이미지 및 PDF 페이지 읽기에 사용';

  @override
  String get connectionDiagnosticsOptional => '연결 진단(선택)';

  @override
  String get sendTextStreamingToolAndImageRequests =>
      '텍스트, 스트리밍, 도구 및 이미지 요청 전송';

  @override
  String get deleteModel => '모델 삭제';

  @override
  String get deleteLocalConfigurationAndKeyAfterConfirmation =>
      '확인 후 로컬 설정 및 키 삭제';

  @override
  String get deleteThisModel => '이 모델을 삭제할까요?';

  @override
  String get theLocalConfigurationAndKeyWillBe => '로컬 설정 및 키가 삭제됩니다.';

  @override
  String get setAsFixedVisionAssistant => '고정 시각 도우미로 설정됨';

  @override
  String get setAsDefaultTextModel => '기본 텍스트 모델로 설정됨';

  @override
  String get savedLeaveBlankToRetain => '저장됨 · 유지하려면 비워 두기';

  @override
  String get hideKey => '키 숨기기';

  @override
  String get showKey => '키 표시';

  @override
  String get providerDefault => '서비스 기본값';

  @override
  String get enableThinking => '사고 활성화';

  @override
  String get disableThinking => '사고 비활성화';

  @override
  String get letTheModelDecide => '모델이 자동 판단';

  @override
  String get modelSettings => '모델 설정';

  @override
  String get connectionConfiguration => '연결 설정';

  @override
  String get modelProvider => '모델 제공업체';

  @override
  String get autoDetect => '자동 감지';

  @override
  String autoDetect310(String p0) {
    return '자동 감지 · $p0';
  }

  @override
  String get configurationName => '설정 이름';

  @override
  String get apiUrl => 'API 주소';

  @override
  String get modelName => '모델 이름';

  @override
  String get selectABundledModel => '내장 모델 선택';

  @override
  String get youCanAlsoEnterTheModelName => '모델 이름을 직접 입력할 수도 있습니다';

  @override
  String get bundledModels => '내장 모델';

  @override
  String get advancedParameters => '고급 매개변수';

  @override
  String get thinkingModeEffortAndOutputLength => '사고 모드, 강도 및 출력 길이';

  @override
  String get thinkingMode => '사고 모드';

  @override
  String get useProviderDefaultsWithoutExtraThinkingParameters =>
      '추가 사고 매개변수 없이 서비스 기본값 사용';

  @override
  String get askTheModelToThinkDeeply => '모델에 심층 사고 요청';

  @override
  String get askTheModelToAnswerDirectly => '모델에 바로 답변 요청';

  @override
  String get letTheModelDecideWhetherThinkingIs => '사고 필요 여부를 모델이 판단';

  @override
  String get thinkingEffort => '사고 강도';

  @override
  String get higherEffortUsuallyTakesLongerAndUses =>
      '강도가 높을수록 일반적으로 시간과 토큰이 더 필요합니다. 사용 가능한 단계는 모델에 따라 다릅니다.';

  @override
  String get thinkingBudgetTokens => '사고 예산(토큰)';

  @override
  String get blankOrUsesProviderDefaultsChooseEither =>
      '비우거나 0을 입력하면 서비스 기본값을 사용합니다. 예산과 강도 중 하나만 선택하세요.';

  @override
  String get contextSettings => '컨텍스트 설정';

  @override
  String get followModelSpecification => '모델 사양 따르기';

  @override
  String get officialApisUseVerifiedContextLimitsFor =>
      '공식 API는 검증된 모델 컨텍스트 한도 사용';

  @override
  String get setALocalBudgetWithinTheProvider => '서비스 한도 내에서 로컬 예산 설정';

  @override
  String currentContextTokens(String p0, String p1) {
    return '현재 컨텍스트: $p0토큰. $p1';
  }

  @override
  String get planApiLimitsAreUnverifiedCurrentSettings =>
      '요금제 API 한도는 미검증입니다. 현재 설정을 유지하고 표준 API 한도를 적용하지 않습니다.';

  @override
  String get thisApiOrModelIsNotIn =>
      '이 API 또는 모델은 목록에 없습니다. 사용자 지정 예산을 설정할 수 있습니다.';

  @override
  String currentContextTokensOfficialMaximumInputTokens(
    String p0,
    String p1,
    String p2,
    String p3,
  ) {
    return '현재 컨텍스트: $p0토큰\n공식 최대 입력: $p1토큰 · $p2\n목록 확인일: $p3. 컨텍스트에서 출력 공간을 예약합니다.';
  }

  @override
  String get nonThinking => '비사고';

  @override
  String get thinkingDefault => '사고 / 기본값';

  @override
  String get contextIsOrganizedAtOfTheEffective =>
      '유효 입력 예산의 95%에서 정리하고 60%를 목표로 합니다. 원본 기록은 유지됩니다.';

  @override
  String get maximumOutputLength => '최대 출력 길이';

  @override
  String get useModelMaximum => '모델 최대값 사용';

  @override
  String get useTheVerifiedMaximumOutputForThe => '실제 모델의 검증된 최대 출력 사용';

  @override
  String get keepYourCustomOutputLength => '지정한 출력 길이 유지';

  @override
  String get theMaximumOutputForThisApiIs =>
      '이 API의 최대 출력은 미검증입니다. 4096토큰을 사용하며 사용자 지정 값으로 변경할 수 있습니다.';

  @override
  String modelMaximumOutputTokensRequestsAdjustTo(String p0) {
    return '모델 최대 출력: $p0토큰. 남은 컨텍스트에 맞게 조정되며 모델이 일찍 종료할 수 있습니다.';
  }

  @override
  String get contextLength => '컨텍스트 길이';

  @override
  String get customOutputLength => '사용자 지정 출력 길이';

  @override
  String get lengthsAreInTokensSomeModelsCount =>
      '단위는 토큰입니다. 일부 모델은 사고를 출력에 포함합니다.';

  @override
  String get outputLengthParameter => '출력 길이 매개변수';

  @override
  String get standardParameter => '표준 매개변수';

  @override
  String get completionLengthParameter => '완료 길이 매개변수';

  @override
  String get chooseAccordingToTheProviderSApi =>
      '서비스 API 요구 사항에 맞게 선택하세요. 입력한 출력 길이는 바뀌지 않습니다.';

  @override
  String get notTested => '미테스트';

  @override
  String get processing => '처리 중…';

  @override
  String get saveModel => '모델 저장';

  @override
  String emailCount(int p0) {
    return '메일 $p0개';
  }

  @override
  String expandEmailCount(int p0) {
    return '전체 $p0개 펼치기';
  }

  @override
  String get previousEmailPage => '이전 메일 페이지';

  @override
  String get nextEmailPage => '다음 메일 페이지';

  @override
  String get collapse => '접기';

  @override
  String get qqMail => 'QQ 메일';

  @override
  String get enableMailServices => '메일 서비스 활성화';

  @override
  String get signInToQqMailInA =>
      'PC 브라우저에서 QQ 메일에 로그인한 후 설정 → 계정 및 보안 → 보안 설정에서 POP3/IMAP/SMTP를 켜세요.';

  @override
  String get generateAnAppPassword => '앱 비밀번호 생성';

  @override
  String get completeIdentityVerificationOnTheOfficialPage =>
      '공식 페이지에서 본인 인증을 완료하고 16자리 앱 비밀번호를 생성하여 여기에 입력하세요.';

  @override
  String get returnToAccountForm => '계정 입력으로 돌아가기';

  @override
  String get enterTheFullEmailAddressServersAre =>
      '전체 메일 주소를 입력하세요. 서버는 미리 입력되어 있습니다. 저장 전에 연결을 테스트하세요.';

  @override
  String get getAndManageAppPasswords => '앱 비밀번호 발급 및 관리';

  @override
  String get mail368 => '163 메일';

  @override
  String get enableImapSmtp => 'IMAP/SMTP 활성화';

  @override
  String get signInToWebmailFindPopSmtp =>
      '163 웹메일에 로그인한 후 설정에서 POP3/SMTP/IMAP를 찾아 IMAP/SMTP를 켜세요.';

  @override
  String get getAClientAppPassword => '클라이언트 앱 비밀번호 발급';

  @override
  String get completeTheVerificationAsInstructedAndEnter =>
      '안내에 따라 인증을 완료하고 생성된 클라이언트 비밀번호를 입력하세요.';

  @override
  String get checkTheFullEmailAddress => '전체 메일 주소 확인';

  @override
  String get useYourFullComAddressIfYou =>
      '전체 @163.com 주소를 사용하세요. 설정을 찾을 수 없으면 NetEase 공식 도움말에서 “授权码” 또는 “IMAP”를 검색하세요.';

  @override
  String get neteaseMailOfficialHelp => 'NetEase 메일 공식 도움말';

  @override
  String get alibabaBusinessMail => 'Alibaba 기업 메일';

  @override
  String get checkClientPermissions => '클라이언트 권한 확인';

  @override
  String get askTheAdministratorToAllowThirdParty =>
      '관리자에게 외부 클라이언트 허용 및 IMAP/SMTP 활성화를 요청하세요. 새 기업 계정은 기본적으로 외부 클라이언트를 차단할 수 있습니다.';

  @override
  String get prepareASecurityPassword => '보안 비밀번호 준비';

  @override
  String get inWebmailGoToSettingsAccountAnd =>
      '웹메일 설정 → 계정 및 보안에서 외부 클라이언트용 보안 비밀번호를 생성하고 활성화 후 여기에 사용하세요.';

  @override
  String get enterTheBusinessEmailAddress => '기업 메일 주소 입력';

  @override
  String get useTheFullBusinessAddressDefaultServers =>
      '전체 기업 메일 주소를 사용하세요. 기본 서버가 입력되어 있으며 홍콩 지역 또는 기업 지정 설정은 고급 설정에서 변경할 수 있습니다.';

  @override
  String get allowThirdPartyClients => '외부 클라이언트 허용';

  @override
  String get generateAThirdPartyClientSecurityPassword =>
      '외부 클라이언트용 보안 비밀번호 생성';

  @override
  String get serverAddressesAndPorts => '서버 주소 및 포트';

  @override
  String get alibabaPersonalMail => 'Alibaba 개인 메일';

  @override
  String get checkAccountType => '계정 유형 확인';

  @override
  String get thisPresetIsForFreeAlibabaCloud =>
      '이 설정은 Alibaba Cloud 무료 개인 메일용입니다. 회사 도메인 계정은 Alibaba 기업을 선택하세요.';

  @override
  String get prepareLoginDetails => '로그인 정보 준비';

  @override
  String get enterTheFullEmailAddressAndRequired =>
      '전체 메일 주소와 필요한 인증 정보를 입력하고 클라이언트 접근이 허용되어 있는지 확인하세요.';

  @override
  String get checkServers => '서버 확인';

  @override
  String get useTheOfficialSslServerSettingsBelow =>
      '아래 공식 SSL 서버 설정을 사용하고 저장 전에 연결을 테스트하세요.';

  @override
  String get personalMailServersAndPorts => '개인 메일 서버 및 포트';

  @override
  String get customEmailProvider => '사용자 지정 메일';

  @override
  String get identifyYourProvider => '제공업체 확인';

  @override
  String get aCustomDomainDoesNotIdentifyThe =>
      '사용자 지정 도메인만으로는 제공업체를 알 수 없습니다. 메일 관리자에게 확인하세요.';

  @override
  String get getConnectionSettings => '연결 설정 확인';

  @override
  String get prepareImapAndSmtpHostsPortsEncryption =>
      'IMAP·SMTP 호스트, 포트, 암호화 방식 및 비밀번호 또는 앱 비밀번호를 준비하세요.';

  @override
  String get enterAndVerify => '입력 및 확인';

  @override
  String get expandServerAndAdvancedSettingsAndEnter =>
      '서버 및 고급 설정을 펼쳐 제공업체의 정보를 입력하세요.';

  @override
  String setupGuide(String p0) {
    return '$p0 설정 안내';
  }

  @override
  String get closeSetupGuide => '설정 안내 닫기';

  @override
  String get defaultServersSsl => '기본 서버 · SSL';

  @override
  String incomingPortOutgoingPort(String p0, String p1) {
    return '수신  $p0\n포트 993\n\n발신  $p1\n포트 465';
  }

  @override
  String get officialHelp => '공식 도움말';

  @override
  String verifiedOfficialPagesOpenInYourBrowser(String p0) {
    return '확인일: $p0 · 공식 페이지는 브라우저에서 열립니다';
  }

  @override
  String get returnToForm => '입력으로 돌아가기';

  @override
  String get mailpilotPreview => 'MailPilot · 미리보기';

  @override
  String get thisLinkIsNotAValidWeb => '이 링크는 유효한 웹 주소가 아닙니다';

  @override
  String get openWebpage => '웹페이지 열기';

  @override
  String get copyLink => '링크 복사';

  @override
  String get openInBrowser => '브라우저에서 열기';

  @override
  String image(String p0) {
    return '[이미지 $p0]';
  }

  @override
  String get sizeUnknown => '크기 미확인';

  @override
  String get firstPagesByDefaultPageCountPending => '기본 앞 10페이지, 페이지 수 확인 대기';

  @override
  String get selectPdfPageNumbers => 'PDF 페이지 번호 선택';

  @override
  String page(String p0) {
    return '$p0페이지';
  }

  @override
  String get fileName => '파일 이름';

  @override
  String get deselect => '선택 해제';

  @override
  String get select420 => '선택';

  @override
  String get materialsForThisAnalysis => '이번 분석 자료';

  @override
  String materialSummary(String p0, String p1, String p2) {
    return '첨부 $p0개 · $p1$p2';
  }

  @override
  String withUnknownSize(String p0) {
    return ' · 크기 미확인 $p0개';
  }

  @override
  String get closeMaterials => '자료 관리 닫기';

  @override
  String upToAttachmentsMbAndImagesOr(String p0) {
    return '턴당 최대 첨부 10개, 50 MB, 이미지 또는 PDF 20페이지.\n$p0';
  }

  @override
  String get actualImageCountsInPdfAndOffice =>
      'PDF 및 Office 파일의 실제 이미지 수는 읽을 때 확인합니다.';

  @override
  String get selectedFilesAreReadOnlyWhenPreviewing =>
      '선택한 파일은 미리보기 또는 질문할 때만 읽습니다.';

  @override
  String get attachmentListAwaitingSync => '첨부 목록 동기화 대기';

  @override
  String get selectAllSupportedAttachments => '분석 가능한 첨부 모두 선택';

  @override
  String get keepBodyOnly => '본문만 유지';

  @override
  String get deviceFiles => '기기 파일';

  @override
  String get noMaterialsSelectedAddFilesOrSelect =>
      '선택한 자료가 없습니다. 파일을 추가하거나 메일을 선택하세요.';

  @override
  String get materialCheckIncomplete => '자료 확인 미완료';

  @override
  String get retryWithCurrentMaterials => '현재 자료로 다시 시도';

  @override
  String get analyzedImages => '분석된 이미지';

  @override
  String get previousAnalysisIsReusedByDefaultSelect =>
      '기본적으로 이전 분석을 재사용합니다. 새 세부 정보가 필요하면 재확인을 선택하세요. 다음 전송 시 적용됩니다.';

  @override
  String get cancelRecheck => '재확인 취소';

  @override
  String get recheckImages => '이미지 재확인';

  @override
  String get previousVersion => '이전 버전';

  @override
  String messageVersionCount(String p0, String p1) {
    return '$p1개 중 $p0번째 버전';
  }

  @override
  String get nextVersion => '다음 버전';

  @override
  String get closeMessageActions => '메시지 작업 닫기';

  @override
  String get copyMessage => '메시지 복사';

  @override
  String get messageCopied => '메시지를 복사했습니다';

  @override
  String close(String p0) {
    return '$p0 닫기';
  }

  @override
  String get volcengineArk => 'Volcengine · Ark';

  @override
  String get alibabaCloudModelStudio => 'Alibaba Cloud · Model Studio';

  @override
  String get openaiCompatibleApi => 'OpenAI 호환 API';

  @override
  String get minimalMinimal => '최소 · minimal';

  @override
  String get lowLow => '낮음 · low';

  @override
  String get mediumMedium => '중간 · medium';

  @override
  String get highHigh => '높음 · high';

  @override
  String get veryHighXhigh => '매우 높음 · xhigh';

  @override
  String get maximumMax => '최대 · max';

  @override
  String get chooseImageProcessing => '이미지 처리 방식 선택';

  @override
  String get yourQuestionMaterialsAndCompletedAnalysisAre =>
      '질문, 자료 및 완료된 분석은 유지됩니다.';

  @override
  String get adjustMaterials => '자료 조정';

  @override
  String get reduceImagesPagesOrTextAndSubmit => '이미지, 페이지 또는 텍스트를 줄인 후 다시 제출';

  @override
  String get processThisTurnInBatches => '이번 턴 분할 처리';

  @override
  String get readUnfinishedImagesInBatchesThenSummarize =>
      '미완료 이미지를 나누어 읽은 후 요약';

  @override
  String get couldNotReadThisPage => '이 페이지를 읽을 수 없습니다';

  @override
  String get couldNotReadThisPagePleaseRetry => '이 페이지를 읽을 수 없습니다. 다시 시도하세요.';

  @override
  String get closePagePreview => '페이지 미리보기 닫기';

  @override
  String get pageImageUnavailable => '페이지 이미지를 표시할 수 없습니다';

  @override
  String get selectPdfPages => 'PDF 페이지 선택';

  @override
  String pagesTotal(String p0) {
    return ' · 총 $p0페이지';
  }

  @override
  String pagesSelectedMaximum(String p0) {
    return '$p0페이지 선택 / 최대 20페이지';
  }

  @override
  String get selectAll => '전체 선택';

  @override
  String get firstPages => '앞 10페이지';

  @override
  String get clear => '지우기';

  @override
  String get readingPdf => 'PDF 읽는 중…';

  @override
  String get couldNotReadPageNumbers => '페이지 번호를 읽을 수 없습니다';

  @override
  String get retryReading => '읽기 다시 시도';

  @override
  String get selectUpToPagesPerPdf => 'PDF당 최대 20페이지 선택';

  @override
  String get deselectThisAttachment => '이 첨부 선택 해제';

  @override
  String confirmSelectionPages(String p0) {
    return '선택 확인 · $p0페이지';
  }

  @override
  String get retryPreview => '미리보기 다시 시도';

  @override
  String previewPage(String p0) {
    return '$p0페이지 미리보기';
  }

  @override
  String get loadingPreview => '미리보기 불러오는 중…';

  @override
  String page480(String p0, String p1) {
    return '$p0, $p1페이지';
  }

  @override
  String reasoningSegmentHeading(String p0) {
    return '사고 $p0\n';
  }

  @override
  String get searching => '검색 중';

  @override
  String get searchIncomplete => '검색 미완료';

  @override
  String searchResultCount(int p0) {
    return '결과 $p0개 찾음';
  }

  @override
  String get readingWebpages => '웹페이지 읽는 중';

  @override
  String readWebpageCount(int p0) {
    return '웹페이지 $p0개 읽음';
  }

  @override
  String get webpageReadingFinished => '웹페이지 읽기 종료';

  @override
  String get readingMaterials => '자료 읽는 중';

  @override
  String get sourceExcerptViewed => '출처 발췌문 확인됨';

  @override
  String get materialsReused => '자료 재사용됨';

  @override
  String get searchingEmails => '메일 검색 중';

  @override
  String get emailsSearched => '메일 검색 완료';

  @override
  String get processing493 => '처리 중';

  @override
  String get actionCompleted => '작업 완료';

  @override
  String get lessThanSecond => '1초 미만';

  @override
  String elapsedSeconds(int p0) {
    return '$p0초';
  }

  @override
  String get thinking497 => '생각 중';

  @override
  String get thinkingStopped => '사고 중지됨';

  @override
  String get thinkingInterrupted => '사고 중단됨';

  @override
  String get process => '처리 과정';

  @override
  String get thought => '사고 완료';

  @override
  String get reasoning => '사고 과정';

  @override
  String get viewReasoning => '사고 기록 보기';

  @override
  String get currentAttempt => '현재 시도';

  @override
  String get previousAttempt => '이전 시도';

  @override
  String earlierAttempt(String p0) {
    return '이전 시도 $p0';
  }

  @override
  String get viewingAPreviousAttempt => '이전 시도 보는 중';

  @override
  String get reasoningIsLongTheFirstCharactersHave =>
      '사고 내용이 길어 앞 128000자를 보관했습니다.';

  @override
  String get jumpToEndOfReasoning => '사고 끝으로 이동';

  @override
  String get uiPreviewSampleDataInstallAndroidTo =>
      'UI 미리보기 · 예제 데이터. 메일과 모델을 연결하려면 Android 버전을 설치하세요.';

  @override
  String get dismissNotice => '알림 닫기';

  @override
  String get backToHome => '홈으로 돌아가기';

  @override
  String get backToSettings => '설정으로 돌아가기';

  @override
  String get backToConversation => '대화로 돌아가기';

  @override
  String get openMenu => '메뉴 열기';

  @override
  String get noVersionsAvailable => '버전 기록이 없습니다';

  @override
  String get couldNotLoadVersionsPleaseRetry => '버전을 불러오지 못했습니다. 다시 시도하세요.';

  @override
  String get cannotEditThisQuestion => '이 질문을 수정할 수 없습니다';

  @override
  String get couldNotEditThisQuestionPleaseRetry => '질문을 수정하지 못했습니다. 다시 시도하세요.';

  @override
  String get editNotSubmittedPleaseRetry => '수정 내용이 제출되지 않았습니다. 다시 시도하세요.';

  @override
  String get addAModelFirst => '먼저 모델을 추가하세요';

  @override
  String get materialCheckIncompletePleaseRetry =>
      '자료 확인이 완료되지 않았습니다. 다시 시도하세요.';

  @override
  String get newConversation => '새 대화';

  @override
  String get whatSOnYourMind => '어떤 이야기를 나눌까요?';

  @override
  String get letSMakeSenseOfYourEmails => '메일 내용을 함께 정리해 봐요.';

  @override
  String get configureAModelToChatYouCan =>
      '모델을 설정하면 대화할 수 있습니다. 메일은 나중에 추가해도 됩니다.';

  @override
  String get askAQuestionOrSelectEmailsAs => '바로 질문하거나 메일을 자료로 선택하세요.';

  @override
  String get helpMeOrganizeMyThoughts => '생각을 정리해 주세요';

  @override
  String get helpMeWriteSomething => '글 작성을 도와주세요';

  @override
  String get summarizeSelectedEmails => '선택한 메일 요약';

  @override
  String get helpMeDraftAReply => '답장 초안 작성';

  @override
  String get retryWebSearch => '웹 검색 다시 시도';

  @override
  String get answerWithoutSearch => '검색 없이 답변';

  @override
  String get continueSearching => '검색 계속';

  @override
  String get responseIncomplete => '답변 미완료';

  @override
  String get continueOrganizing => '정리 계속';

  @override
  String get retryThisTurn => '이번 턴 다시 시도';

  @override
  String get viewBudget => '예산 보기';

  @override
  String get retryWithCompatibleFormat => '호환 형식으로 다시 시도';

  @override
  String get chooseProcessingMethod => '처리 방식 선택';

  @override
  String get adjustMaterialsAndRetry => '자료 조정 후 다시 시도';

  @override
  String get restoreDefaultThinkingAndRetry => '기본 사고 설정 복원 후 다시 시도';

  @override
  String get chooseVisionAssistant => '시각 도우미 선택';

  @override
  String get editConfiguration => '설정 수정';

  @override
  String vision(String p0) {
    return '이미지 읽기 · $p0';
  }

  @override
  String sourceCount(int p0) {
    return '출처 $p0개';
  }

  @override
  String get copyResponse => '답변 복사';

  @override
  String get originalMarkdownCopied => 'Markdown 원문을 복사했습니다';

  @override
  String get responseStopped => '답변을 중지했습니다';

  @override
  String get stoppedThePartialResponseReceivedIsShown =>
      '중지되었습니다. 위 내용은 수신된 일부 답변입니다.';

  @override
  String get reviewDraftAndSend => '초안 검토 후 전송';

  @override
  String get writeAsEmail => '메일로 작성';

  @override
  String get connectingToModel => '모델에 연결 중…';

  @override
  String get viewingAnOlderVersion => '이전 버전 보는 중';

  @override
  String get backToLatest => '최신으로 돌아가기';

  @override
  String get textModel => '텍스트 모델';

  @override
  String tapToCancelSync(String p0) {
    return '$p0 · 탭하여 동기화 취소';
  }

  @override
  String get syncLatestEmailsInEachFolder => '폴더별 최신 메일 50개 동기화';

  @override
  String get searchEmails => '메일 검색';

  @override
  String get emailActions => '메일 작업';

  @override
  String get syncEmailsPerFolder => '메일 동기화(폴더당 50개)';

  @override
  String get showAll => '모두 표시';

  @override
  String get showUnread => '읽지 않은 메일 보기';

  @override
  String get subjectOrSender => '제목 또는 보낸 사람';

  @override
  String get runSearch => '검색 실행';

  @override
  String get connectAnEmailAccountFirst => '먼저 메일 계정을 연결하세요';

  @override
  String get supportsQqAndCustomEmailProviders => 'QQ, 163 및 사용자 지정 메일을 지원합니다.';

  @override
  String get noLocalEmailsYet => '로컬 메일이 없습니다';

  @override
  String get pullDownToSyncRecentEmailsStartup =>
      '아래로 당겨 최신 메일을 동기화하세요. 시작 시 자동 동기화하지 않습니다.';

  @override
  String analyzeSelectedEmails(String p0) {
    return '선택한 메일 $p0개 분석';
  }

  @override
  String get emailDetails => '메일 상세';

  @override
  String get replyAndForward => '답장 및 전달';

  @override
  String get reply => '답장';

  @override
  String get replyAll => '전체 답장';

  @override
  String get forward => '전달';

  @override
  String get recipientDetails => '수신자 정보';

  @override
  String toCc(String p0, String p1) {
    return '받는 사람: $p0\n참조: $p1';
  }

  @override
  String get bodyAwaitingBackgroundSyncYouCanKeep =>
      '본문은 백그라운드 동기화를 기다리고 있습니다. 다른 메일을 계속 볼 수 있습니다.';

  @override
  String attachments(String p0) {
    return '첨부 · $p0';
  }

  @override
  String get tapAnAttachmentToPreviewSelectIt => '첨부를 탭하여 미리보기, 선택하여 AI 분석';

  @override
  String get askAssistant => '도우미에게 맡기기';

  @override
  String get noDraftsYet => '아직 초안이 없습니다';

  @override
  String get writeYourOwnOrAskTheAssistant => '직접 작성하거나 도우미에게 초안을 요청하세요.';

  @override
  String get configurationSaved => '설정을 저장했습니다';

  @override
  String get closeConfiguration => '설정 닫기';

  @override
  String get actionFailed => '작업 실패';

  @override
  String get backToConfiguration => '설정으로 돌아가기';

  @override
  String get volcengineWebSearch => 'Volcengine 웹 검색';

  @override
  String get bocha => 'Bocha';

  @override
  String get systemPreferredCloudOptional => '시스템 우선, 클라우드 선택 가능';

  @override
  String get qwenCloudTranscription => 'Qwen 클라우드 음성 인식';

  @override
  String get automaticSystemRecognitionFollowsDeviceLanguage =>
      '자동(시스템 인식은 기기 언어를 따름)';

  @override
  String get chinese => '중국어';

  @override
  String get searchProvider => '검색 제공업체';

  @override
  String get recognitionMode => '인식 방식';

  @override
  String get speechLanguage => '음성 언어';

  @override
  String get automatic => '자동';

  @override
  String get systemRecognitionNeedsNoApiKeyIf =>
      '시스템 인식은 API 키가 필요하지 않습니다. 기기에 인식 서비스가 없으면 아래 Qwen ASR을 사용할 수 있습니다.';

  @override
  String get usedOnlyWhenSmartSearchIsEnabled =>
      '스마트 검색을 켜고 질문할 때만 사용합니다. 검색 서비스에는 추출한 키워드만 전달하며 메일, 첨부 및 대화 기록은 전달하지 않습니다.';

  @override
  String get qwenAsrBaseUrl => 'Qwen ASR Base URL';

  @override
  String get fullSearchApiUrl => '전체 검색 API 주소';

  @override
  String get leaveBlankToRetainTheSavedKey => '저장된 키를 유지하려면 비워 두기';

  @override
  String get showOrHideKey => '키 표시 또는 숨기기';

  @override
  String get asrModel => 'ASR 모델';

  @override
  String get forExampleQwenAsrFlash => '예: qwen3-asr-flash';

  @override
  String get transcriptionFillsTheInputFieldOnlyReview =>
      '인식 결과는 입력란에만 채워집니다. 검토 후 전송하세요. 클라우드 모드는 최대 60초의 새 녹음이 필요합니다.';

  @override
  String get streamingUiStateIsOutOfSync =>
      '스트리밍 UI 상태가 동기화되지 않았습니다. 대화를 다시 여세요.';

  @override
  String get streamNotReceivedCompletelyReopenThisConversation =>
      '스트림을 완전히 수신하지 못했습니다. 대화를 다시 여세요.';

  @override
  String get appLanguage => '언어';

  @override
  String get languageTitle => '언어 선택';

  @override
  String get languageDescription => '화면 언어를 변경합니다. 메일과 대화 내용은 원문 그대로 유지됩니다.';
}
