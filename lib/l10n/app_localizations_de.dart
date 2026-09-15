// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get switchAccount => 'Konto wechseln';

  @override
  String get closeAccountPicker => 'Kontoauswahl schließen';

  @override
  String switchAccountCurrent(String p0) {
    return 'Konto wechseln, aktuell: $p0';
  }

  @override
  String get openWithAnotherApp => 'Mit anderer App öffnen';

  @override
  String get openInAnotherApp => 'In anderer App öffnen';

  @override
  String get saveToDevice => 'Auf Gerät speichern';

  @override
  String get couldNotStartRecording => 'Aufnahme konnte nicht gestartet werden';

  @override
  String get addImage => 'Bild hinzufügen';

  @override
  String get addFile => 'Datei hinzufügen';

  @override
  String get selectEmails => 'E-Mails auswählen';

  @override
  String get manageImportedMaterials => 'Importierte Materialien verwalten';

  @override
  String get deepThinking => 'Intensives Nachdenken';

  @override
  String get editInput => 'Eingabe bearbeiten';

  @override
  String get cancelEdit => 'Bearbeitung abbrechen';

  @override
  String selectedMaterialsCount(int p0, int p1) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 E-Mails',
      one: '1 E-Mail',
    );
    String _temp1 = intl.Intl.pluralLogic(
      p1,
      locale: localeName,
      other: '$p1 Anhänge',
      one: '1 Anhang',
    );
    return '$_temp0 · $_temp1 ausgewählt';
  }

  @override
  String get clearSelection => 'Auswahl aufheben';

  @override
  String get listeningUpToSeconds => 'Hört zu · bis zu 60 Sekunden';

  @override
  String get transcribing => 'Transkription läuft…';

  @override
  String get startingMicrophone => 'Mikrofon wird gestartet…';

  @override
  String get recordAgainInCloudMode => 'Erneut im Cloud-Modus aufnehmen';

  @override
  String get cancelVoiceInput => 'Spracheingabe abbrechen';

  @override
  String get askAboutSelectedMaterials => 'Zu ausgewählten Materialien fragen…';

  @override
  String get messageOrUseVoiceInput => 'Nachricht oder Spracheingabe';

  @override
  String get smartSearch => 'Intelligente Suche';

  @override
  String get thinking => 'Nachdenken';

  @override
  String get search => 'Suchen';

  @override
  String get addAttachment => 'Anhang hinzufügen';

  @override
  String get stopResponse => 'Antwort stoppen';

  @override
  String get stopRecording => 'Aufnahme beenden';

  @override
  String get sendQuestion => 'Frage senden';

  @override
  String get voiceInput => 'Spracheingabe';

  @override
  String get draftDeleted => 'Entwurf gelöscht';

  @override
  String get pleaseViewTheLatestVersion => 'Bitte neueste Version ansehen';

  @override
  String get from => 'Von';

  @override
  String get to => 'An';

  @override
  String get cc => 'Cc';

  @override
  String get bcc => 'Bcc';

  @override
  String get notEntered => 'Nicht angegeben';

  @override
  String get noSubject => '(Kein Betreff)';

  @override
  String get afterReviewingConfirmSendingOrTapThe =>
      'Prüfen Sie den Inhalt und bestätigen Sie das Senden oder tippen Sie auf die Schaltfläche unten.';

  @override
  String get confirmSend => 'Senden bestätigen';

  @override
  String get addRecipient => 'Empfänger ergänzen';

  @override
  String get viewLatestVersion => 'Neueste Version anzeigen';

  @override
  String get reviewAndEdit => 'Prüfen und bearbeiten';

  @override
  String get editEmail => 'E-Mail bearbeiten';

  @override
  String get jumpToLatestMessage => 'Zur neuesten Nachricht';

  @override
  String get inbox => 'Posteingang';

  @override
  String get sent => 'Gesendet';

  @override
  String get drafts => 'Entwürfe';

  @override
  String get deleted => 'Gelöscht';

  @override
  String get spam => 'Spam';

  @override
  String get archive => 'Archiv';

  @override
  String get mailFolders => 'E-Mail-Ordner';

  @override
  String get refreshFolders => 'Ordner aktualisieren';

  @override
  String couldNotRefreshFoldersLocalListRetained(String p0) {
    return 'Ordner konnten nicht aktualisiert werden. Lokale Liste bleibt erhalten. $p0';
  }

  @override
  String get unreadOnly => 'Nur ungelesene';

  @override
  String get deleteThisDraft => 'Diesen Entwurf löschen?';

  @override
  String get onlyTheLocalDraftIsDeletedChats =>
      'Nur der lokale Entwurf wird gelöscht. Chats und E-Mails auf dem Server bleiben erhalten.';

  @override
  String get delete => 'Löschen';

  @override
  String get draftActions => 'Entwurfsaktionen';

  @override
  String get rewrite => 'Neu verfassen';

  @override
  String get deleteDraft => 'Entwurf löschen';

  @override
  String get recipientEmail => 'Empfängeradresse';

  @override
  String get separateMultipleAddressesWithCommas =>
      'Mehrere Adressen durch Kommas trennen';

  @override
  String get afterSavingReviewTheNewConfirmationCard =>
      'Nach dem Speichern die neue Bestätigungskarte vor dem Senden prüfen.';

  @override
  String get saveRecipients => 'Empfänger speichern';

  @override
  String get draftAnswerPrompt =>
      'Verfasse eine formelle E-Mail auf Grundlage dieser Antwort:';

  @override
  String get draftAnswerPromptSuffix =>
      'Damit ich sie vor dem Senden prüfen und bestätigen kann.';

  @override
  String get turnThisAnswerIntoAnEmail => 'Diese Antwort als E-Mail verfassen';

  @override
  String get viewOriginalOfOlderVersion =>
      'Original der früheren Version ansehen';

  @override
  String get messageActions => 'Nachrichtenaktionen';

  @override
  String get needsVerification => 'Prüfung erforderlich';

  @override
  String get sending => 'Wird gesendet';

  @override
  String get sendFailed => 'Senden fehlgeschlagen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String attachmentCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 Anhänge',
      one: '1 Anhang',
    );
    return '$_temp0';
  }

  @override
  String select(String p0) {
    return '$p0 auswählen';
  }

  @override
  String get emailAndModelConnectionsRequireAndroidUse =>
      'E-Mail- und Modellverbindungen erfordern Android. Hier die UI-Vorschau verwenden.';

  @override
  String get notConnectedToTheAndroidMailService =>
      'Keine Verbindung zum Android-Maildienst. Neueste APK vollständig schließen und erneut öffnen. Im Browser und Widget Preview den Vorschau-Einstieg verwenden.';

  @override
  String get actionIncomplete => 'Aktion unvollständig';

  @override
  String get thisFeatureIsUnavailableInTheCurrent =>
      'Diese Funktion ist in dieser Umgebung nicht verfügbar';

  @override
  String get pin => 'Anheften';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get previousDays => 'Letzte 7 Tage';

  @override
  String get previousDays86 => 'Letzte 30 Tage';

  @override
  String olderConversationDate(String p0, String p1, String p2) {
    return '$p2.$p1.$p0';
  }

  @override
  String get loadingConversations => 'Gespräche werden geladen';

  @override
  String get noMatchingConversations => 'Keine passenden Gespräche';

  @override
  String get yourConversationsWillAppearHere =>
      'Ihre Gespräche erscheinen hier';

  @override
  String get tryShorterKeywordsOrClearTheSearch =>
      'Kürzere Suchbegriffe versuchen oder Suche löschen.';

  @override
  String get startAChatAndComeBackAnytime =>
      'Chat beginnen und jederzeit fortsetzen.';

  @override
  String get clearSearch => 'Suche löschen';

  @override
  String get startAConversation => 'Gespräch beginnen';

  @override
  String get couldNotLoadConversationsTapToRetry =>
      'Gespräche konnten nicht geladen werden. Zum Wiederholen tippen.';

  @override
  String get renameConversation => 'Gespräch umbenennen';

  @override
  String get enterConversationName => 'Gesprächsnamen eingeben';

  @override
  String get save => 'Speichern';

  @override
  String deleteConversationCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 Gespräche löschen?',
      one: '1 Gespräch löschen?',
    );
    return '$_temp0';
  }

  @override
  String get chatsSummariesAndAnalysisCachesForThese =>
      'Chats, Zusammenfassungen und Analyse-Caches dieser Gespräche werden gelöscht. E-Mails und Entwürfe bleiben erhalten.';

  @override
  String get rename => 'Umbenennen';

  @override
  String get unpin => 'Loslösen';

  @override
  String get selectMultiple => 'Mehrfachauswahl';

  @override
  String selectedConversationCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 Gespräche ausgewählt',
      one: '1 Gespräch ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get exitSelection => 'Auswahl beenden';

  @override
  String get closeSidebar => 'Seitenleiste schließen';

  @override
  String get searchConversations => 'Gespräche durchsuchen…';

  @override
  String get conversationSummary => 'Gesprächszusammenfassung';

  @override
  String get loading => 'Wird geladen…';

  @override
  String get loadMore => 'Mehr laden';

  @override
  String get selectConversations => 'Gespräche auswählen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get thisConversationSSummary => 'Zusammenfassung dieses Gesprächs';

  @override
  String summarizedMessageCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 frühere Nachrichten zusammengefasst',
      one: '1 frühere Nachricht zusammengefasst',
    );
    return '$_temp0';
  }

  @override
  String get closeSummary => 'Zusammenfassung schließen';

  @override
  String get originalMessagesAreRetainedYouCanAdd =>
      'Originalnachrichten bleiben erhalten. Informationen oder Korrekturen können ergänzt werden.';

  @override
  String get noSummaryForThisConversationYet =>
      'Für dieses Gespräch liegt noch keine Zusammenfassung vor.';

  @override
  String get conversationChangedPleaseReopenTheSummary =>
      'Gespräch gewechselt. Zusammenfassung erneut öffnen.';

  @override
  String get draftingReadOnlyPreview =>
      'Entwurf wird erstellt · schreibgeschützte Vorschau';

  @override
  String get incompleteCannotSend => 'Unvollständig · Senden nicht möglich';

  @override
  String get draftingEmail => 'E-Mail verfassen';

  @override
  String get generatingResponse => 'Antwort wird erstellt';

  @override
  String get readingImages => 'Bilder werden gelesen';

  @override
  String get preparingMaterials => 'Materialien werden vorbereitet';

  @override
  String get generatingContent => 'Inhalt wird erstellt';

  @override
  String get parsingModelAction => 'Modellaktion wird ausgewertet';

  @override
  String get organizingExistingResults =>
      'Vorhandene Ergebnisse werden geordnet';

  @override
  String get organizingContext => 'Kontext wird geordnet';

  @override
  String get webSearch => 'Websuche';

  @override
  String get currentRequest => 'Aktuelle Anfrage';

  @override
  String get requestId => 'Anfrage-ID';

  @override
  String get serverId => 'Server-ID';

  @override
  String get httpStatus => 'HTTP-Status';

  @override
  String get finishReason => 'Beendigungsgrund';

  @override
  String get exceptionType => 'Ausnahmetyp';

  @override
  String get validationResult => 'Prüfergebnis';

  @override
  String get requestBudgetAndDiagnostics => 'Anfragebudget und Diagnose';

  @override
  String get connectionDiagnostics => 'Verbindungsdiagnose';

  @override
  String get requestRecordsForThisTurn => 'Anfrageprotokolle dieser Runde';

  @override
  String get closeDiagnostics => 'Diagnose schließen';

  @override
  String get processingStage => 'Verarbeitungsschritt';

  @override
  String get model => 'Modell';

  @override
  String get apiHost => 'API-Host';

  @override
  String get imageProcessing => 'Bildverarbeitung';

  @override
  String get fullTextAndImageResponse => 'Vollständige Text-Bild-Antwort';

  @override
  String get visionAssistantReading => 'Lesen durch visuellen Assistenten';

  @override
  String get batchProcessingSelectedForThisTurn =>
      'Für diese Runde gewählte Stapelverarbeitung';

  @override
  String get reusingPreviousAnalysis =>
      'Vorherige Analyse wird wiederverwendet';

  @override
  String get requestsWithImages => 'Anfragen mit Bildern';

  @override
  String requestCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 Anfragen',
      one: '1 Anfrage',
    );
    return '$_temp0';
  }

  @override
  String get totalImagesUploaded => 'Insgesamt hochgeladene Bilder';

  @override
  String imageCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 Bilder',
      one: '1 Bild',
    );
    return '$_temp0';
  }

  @override
  String get reusedImages => 'Wiederverwendete Bilder';

  @override
  String get batchingReason => 'Grund für Stapelverarbeitung';

  @override
  String get estimatedInput => 'Geschätzte Eingabe';

  @override
  String get availableInputBudget => 'Verfügbares Eingabebudget';

  @override
  String get configuredContext => 'Konfigurierter Kontext';

  @override
  String get outputReserve => 'Ausgabereserve';

  @override
  String get thinkingReserve => 'Denkreserve';

  @override
  String get suggestedSummaryLength => 'Empfohlene Zusammenfassungslänge';

  @override
  String get summaryBudgetLimit => 'Budgetgrenze der Zusammenfassung';

  @override
  String get currentSummaryEstimate => 'Aktuelle Zusammenfassungsschätzung';

  @override
  String get localEstimatesMayDifferFromProviderMetering =>
      'Lokale Schätzungen können von der Anbieterzählung abweichen. Aufbereitung beginnt bei 95 % und zielt auf 60 %.';

  @override
  String get timeToFirstChunk => 'Zeit bis zum ersten Paket';

  @override
  String get lastChunkReceived => 'Letztes Paket empfangen';

  @override
  String get requestDuration => 'Anfragedauer';

  @override
  String get technicalDetails => 'Technische Details';

  @override
  String get requestIdsAndExceptionInformation =>
      'Anfrage-IDs und Ausnahmeinformationen';

  @override
  String get convertedToEmailBodyReviewBeforeSaving =>
      'In E-Mail-Text umgewandelt. Vor dem Speichern prüfen.';

  @override
  String get conversionFailedOriginalTextRetained =>
      'Umwandlung fehlgeschlagen. Originaltext bleibt erhalten.';

  @override
  String get discardUnsavedChanges => 'Ungespeicherte Änderungen verwerfen?';

  @override
  String get savedDraftsAreRetained =>
      'Gespeicherte Entwürfe bleiben erhalten.';

  @override
  String get discardChanges => 'Änderungen verwerfen';

  @override
  String get deleteThisLocalRecord => 'Diesen lokalen Eintrag löschen?';

  @override
  String get serverEmailsAreRetained =>
      'E-Mails auf dem Server bleiben erhalten.';

  @override
  String get composeEmail => 'E-Mail schreiben';

  @override
  String get back => 'Zurück';

  @override
  String get moreEmailActions => 'Weitere E-Mail-Aktionen';

  @override
  String get saveChangesAndRewrite => 'Änderungen speichern und neu verfassen';

  @override
  String get convertMarkdownToBodyText =>
      'Markdown in Nachrichtentext umwandeln';

  @override
  String get sendingAccount => 'Absenderkonto';

  @override
  String get subject => 'Betreff';

  @override
  String get body => 'Nachrichtentext';

  @override
  String get sendAsThePlainTextShownHere =>
      'Als hier angezeigten Klartext senden';

  @override
  String get ccBcc => 'Cc / Bcc';

  @override
  String remove(String p0) {
    return '$p0 entfernen';
  }

  @override
  String get firstCheckTheServerSSentFolder =>
      'Zuerst den Gesendet-Ordner des Servers und den Empfang bei den Empfängern prüfen.';

  @override
  String get verifiedThatSendingSucceeded => 'Erfolgreiches Senden geprüft?';

  @override
  String get thisOnlyUpdatesTheLocalRecord =>
      'Dies aktualisiert nur den lokalen Eintrag.';

  @override
  String get verifiedSentSuccessfully => 'Geprüft: erfolgreich gesendet';

  @override
  String get confirmedThatNoRecipientsReceivedIt =>
      'Bestätigt, dass kein Empfänger sie erhalten hat?';

  @override
  String get restoreTheDraftToReviewAndSend =>
      'Entwurf wiederherstellen, prüfen und erneut senden. Falls einige Empfänger sie bereits erhalten haben, zuerst die Empfängerliste bearbeiten.';

  @override
  String get restoreDraft => 'Entwurf wiederherstellen';

  @override
  String get verifiedNotSent => 'Geprüft: nicht gesendet';

  @override
  String get confirmSendingInChat => 'Senden im Chat bestätigen';

  @override
  String get confirmBeforeSending => 'Bestätigung vor dem Senden';

  @override
  String get pleaseReviewTheFollowing => 'Bitte Folgendes prüfen';

  @override
  String get accountDeleted => 'Konto gelöscht';

  @override
  String get couldNotReadAttachment => 'Anhang konnte nicht gelesen werden';

  @override
  String get couldNotReadImagePleaseRetry =>
      'Bild konnte nicht gelesen werden. Bitte erneut versuchen.';

  @override
  String get couldNotReadPagePleaseRetry =>
      'Seite konnte nicht gelesen werden. Bitte erneut versuchen.';

  @override
  String get reload => 'Neu laden';

  @override
  String get referencedMaterial => 'Zitiertes Material';

  @override
  String get formattedView => 'Formatierte Ansicht';

  @override
  String get viewOriginal => 'Original anzeigen';

  @override
  String get theFollowingWasGeneratedByAVision =>
      'Folgendes wurde von einem visuellen Modell erstellt. Bei Bedarf mit dem Originalbild abgleichen.';

  @override
  String get previousPage => 'Vorherige Seite';

  @override
  String get nextPage => 'Nächste Seite';

  @override
  String get loadingReferencedMaterial => 'Zitiertes Material wird geladen…';

  @override
  String get selectedImageOrPdfPagePinchTo =>
      'Ausgewähltes Bild oder PDF-Seite. Zum Zoomen zwei Finger verwenden.';

  @override
  String get imageUnavailableRetryOrOpenWithAnother =>
      'Bild nicht verfügbar. Erneut versuchen oder mit anderer App öffnen.';

  @override
  String get pinchToZoomSavingAndExternalOpening =>
      'Mit zwei Fingern zoomen · Speichern und externes Öffnen verwenden den Originalanhang';

  @override
  String get mail => 'E-Mail';

  @override
  String get myEmails => 'Meine E-Mails';

  @override
  String get draftsAndSending => 'Entwürfe und Versand';

  @override
  String get emailAccounts => 'E-Mail-Konten';

  @override
  String get addEmailAccount => 'E-Mail-Konto hinzufügen';

  @override
  String get modelsAndServices => 'Modelle und Dienste';

  @override
  String get defaultModel => 'Standardmodell';

  @override
  String get visionAssistant => 'Visueller Assistent';

  @override
  String get addModel => 'Modell hinzufügen';

  @override
  String get automaticCurrentModelPreferred =>
      'Automatisch · aktuelles Modell bevorzugt';

  @override
  String fixedAssistant(String p0) {
    return 'Fester Assistent · $p0';
  }

  @override
  String get configurationUnavailable => 'Konfiguration nicht verfügbar';

  @override
  String get chooseAutomatically => 'Automatisch auswählen';

  @override
  String get searchAndVoice => 'Suche und Sprache';

  @override
  String get webServicesAndSpeechRecognition =>
      'Webdienste und Spracherkennung';

  @override
  String get preferences => 'Voreinstellungen';

  @override
  String get contextOrganization => 'Kontextaufbereitung';

  @override
  String get fastOrganizationResponseSettingsUnchanged =>
      'Schnelle Aufbereitung · Antwortoptionen unverändert';

  @override
  String get followCurrentThinkingMode => 'Aktuellen Denkmodus verwenden';

  @override
  String get fastOrganizationNonThinkingModeOnSupported =>
      'Schnelle Aufbereitung (ohne Denkmodus bei unterstützten APIs)';

  @override
  String get appearance => 'Darstellung';

  @override
  String get systemDefault => 'Systemeinstellung';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get backgroundSync => 'Hintergrundsynchronisierung';

  @override
  String get off => 'Aus';

  @override
  String get hourly => 'Stündlich';

  @override
  String get onceADay => 'Einmal täglich';

  @override
  String everyMinutes(String p0) {
    return 'Alle $p0 Minuten';
  }

  @override
  String get everyMinutes242 => 'Alle 30 Minuten';

  @override
  String get clearCacheAndChats => 'Cache und Chats löschen';

  @override
  String get clearLocalCache => 'Lokalen Cache löschen?';

  @override
  String get downloadedAttachmentsPagePreviewsAllChatsAnd =>
      'Heruntergeladene Anhänge, Vorschauen, alle Chats und Zusammenfassungen werden gelöscht. E-Mail- und Modelleinstellungen sowie Entwurfsanhänge bleiben erhalten.';

  @override
  String versionAndSendConfirmation(String p0) {
    return 'MailPilot $p0\nJede E-Mail wird nur mit Ihrer Bestätigung gesendet.';
  }

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String get appPassword => 'App-Passwort';

  @override
  String get alibabaBusiness => 'Alibaba Business';

  @override
  String get passwordSecurityPassword => 'Passwort / Sicherheitspasswort';

  @override
  String get alibabaPersonal => 'Alibaba Privat';

  @override
  String get emailPassword => 'E-Mail-Passwort';

  @override
  String get passwordAppPassword => 'Passwort / App-Passwort';

  @override
  String get leaveBlankToKeepSavedCredentials =>
      'Leer lassen, um gespeicherte Zugangsdaten zu behalten.';

  @override
  String get theAdministratorMustAllowThirdPartyClients =>
      'Der Administrator muss Drittanbieter-Clients und IMAP/SMTP zulassen. Falls Sicherheitspasswörter aktiviert sind, das Passwort für Drittanbieter-Clients verwenden.';

  @override
  String get enterTheFullEmailAddressAndPassword =>
      'Vollständige E-Mail-Adresse und Passwort eingeben und Clientzugriff erlauben.';

  @override
  String get enableImapSmtpInYourEmailSettings =>
      'IMAP/SMTP in den E-Mail-Einstellungen aktivieren und ein App-Passwort erstellen.';

  @override
  String get useTheEmailPasswordOrAppPassword =>
      'Das vom Anbieter verlangte E-Mail- oder App-Passwort verwenden.';

  @override
  String get hideCredentials => 'Zugangsdaten ausblenden';

  @override
  String get showCredentials => 'Zugangsdaten anzeigen';

  @override
  String get connectEmail => 'E-Mail verbinden';

  @override
  String get emailSettings => 'E-Mail-Einstellungen';

  @override
  String mail263(String p0) {
    return '$p0 Mail';
  }

  @override
  String mail264(String p0) {
    return '$p0 Mail';
  }

  @override
  String get emailAddress => 'E-Mail-Adresse';

  @override
  String get senderNameOptional => 'Absendername (optional)';

  @override
  String get emailSetupGuide => 'Anleitung zur E-Mail-Einrichtung';

  @override
  String get connectionDetailsAndInstructions =>
      'Verbindungsdaten und Anleitung';

  @override
  String officialGuide(String p0) {
    return '$p0 · offizielle Anleitung';
  }

  @override
  String get serverAndAdvancedSettings => 'Server und erweiterte Einstellungen';

  @override
  String get accountLabel => 'Kontobezeichnung';

  @override
  String get loginUsername => 'Anmeldename';

  @override
  String get leaveBlankToUseTheFullEmail =>
      'Leer lassen für vollständige E-Mail-Adresse';

  @override
  String get imapHost => 'IMAP-Host';

  @override
  String get imapPort => 'IMAP-Port';

  @override
  String get incomingEncryption => 'Verschlüsselung für Empfang';

  @override
  String get smtpHost => 'SMTP-Host';

  @override
  String get smtpPort => 'SMTP-Port';

  @override
  String get outgoingEncryption => 'Verschlüsselung für Versand';

  @override
  String get testConnection => 'Verbindung testen';

  @override
  String get saveAccount => 'Konto speichern';

  @override
  String get deleteThisAccount => 'Dieses Konto löschen?';

  @override
  String get localEmailsDraftsAndAnalysisForThis =>
      'Lokale E-Mails, Entwürfe und Analysen dieses Kontos werden gelöscht. Server-E-Mails bleiben erhalten.';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get modelOptions => 'Modelloptionen';

  @override
  String get closeModelOptions => 'Modelloptionen schließen';

  @override
  String get defaultTextModel => 'Standard-Textmodell';

  @override
  String get forEverydayChatAndEmailDrafting => 'Für Chats und E-Mail-Entwürfe';

  @override
  String get useAsFixedVisionAssistant =>
      'Als festen visuellen Assistenten verwenden';

  @override
  String get forReadingImagesAndPdfPages =>
      'Zum Lesen von Bildern und PDF-Seiten';

  @override
  String get connectionDiagnosticsOptional => 'Verbindungsdiagnose (optional)';

  @override
  String get sendTextStreamingToolAndImageRequests =>
      'Text-, Streaming-, Werkzeug- und Bildanfragen senden';

  @override
  String get deleteModel => 'Modell löschen';

  @override
  String get deleteLocalConfigurationAndKeyAfterConfirmation =>
      'Lokale Konfiguration und Schlüssel nach Bestätigung löschen';

  @override
  String get deleteThisModel => 'Dieses Modell löschen?';

  @override
  String get theLocalConfigurationAndKeyWillBe =>
      'Die lokale Konfiguration und der Schlüssel werden gelöscht.';

  @override
  String get setAsFixedVisionAssistant =>
      'Als fester visueller Assistent festgelegt';

  @override
  String get setAsDefaultTextModel => 'Als Standard-Textmodell festgelegt';

  @override
  String get savedLeaveBlankToRetain =>
      'Gespeichert · leer lassen zum Beibehalten';

  @override
  String get hideKey => 'Schlüssel ausblenden';

  @override
  String get showKey => 'Schlüssel anzeigen';

  @override
  String get providerDefault => 'Anbieterstandard';

  @override
  String get enableThinking => 'Nachdenken aktivieren';

  @override
  String get disableThinking => 'Nachdenken deaktivieren';

  @override
  String get letTheModelDecide => 'Modell entscheiden lassen';

  @override
  String get modelSettings => 'Modelleinstellungen';

  @override
  String get connectionConfiguration => 'Verbindungskonfiguration';

  @override
  String get modelProvider => 'Modellanbieter';

  @override
  String get autoDetect => 'Automatisch erkennen';

  @override
  String autoDetect310(String p0) {
    return 'Automatisch erkennen · $p0';
  }

  @override
  String get configurationName => 'Konfigurationsname';

  @override
  String get apiUrl => 'API-URL';

  @override
  String get modelName => 'Modellname';

  @override
  String get selectABundledModel => 'Mitgeliefertes Modell auswählen';

  @override
  String get youCanAlsoEnterTheModelName =>
      'Der Modellname kann auch direkt eingegeben werden';

  @override
  String get bundledModels => 'Mitgelieferte Modelle';

  @override
  String get advancedParameters => 'Erweiterte Parameter';

  @override
  String get thinkingModeEffortAndOutputLength =>
      'Denkmodus, Intensität und Ausgabelänge';

  @override
  String get thinkingMode => 'Denkmodus';

  @override
  String get useProviderDefaultsWithoutExtraThinkingParameters =>
      'Anbieterstandard ohne zusätzliche Denkparameter verwenden';

  @override
  String get askTheModelToThinkDeeply =>
      'Modell um intensives Nachdenken bitten';

  @override
  String get askTheModelToAnswerDirectly => 'Modell um direkte Antwort bitten';

  @override
  String get letTheModelDecideWhetherThinkingIs =>
      'Modell entscheiden lassen, ob Nachdenken nötig ist';

  @override
  String get thinkingEffort => 'Denkintensität';

  @override
  String get higherEffortUsuallyTakesLongerAndUses =>
      'Höhere Intensität benötigt meist mehr Zeit und Tokens. Verfügbare Stufen hängen vom Modell ab.';

  @override
  String get thinkingBudgetTokens => 'Denkbudget (Tokens)';

  @override
  String get blankOrUsesProviderDefaultsChooseEither =>
      'Leer oder 0 verwendet den Anbieterstandard. Budget oder Intensitätsstufe wählen, nicht beides.';

  @override
  String get contextSettings => 'Kontexteinstellungen';

  @override
  String get followModelSpecification => 'Modellspezifikation verwenden';

  @override
  String get officialApisUseVerifiedContextLimitsFor =>
      'Offizielle APIs verwenden geprüfte Kontextgrenzen des Modells';

  @override
  String get setALocalBudgetWithinTheProvider =>
      'Lokales Budget innerhalb der Anbietergrenze festlegen';

  @override
  String currentContextTokens(String p0, String p1) {
    return 'Aktueller Kontext: $p0 Tokens. $p1';
  }

  @override
  String get planApiLimitsAreUnverifiedCurrentSettings =>
      'Grenzen der Tarif-API sind ungeprüft. Aktuelle Einstellungen bleiben erhalten; Standard-API-Grenzen werden nicht angewendet.';

  @override
  String get thisApiOrModelIsNotIn =>
      'Diese API oder dieses Modell ist nicht im Katalog. Ein eigenes Budget kann festgelegt werden.';

  @override
  String currentContextTokensOfficialMaximumInputTokens(
    String p0,
    String p1,
    String p2,
    String p3,
  ) {
    return 'Aktueller Kontext: $p0 Tokens\nOffizielle maximale Eingabe: $p1 Tokens · $p2\nKatalog geprüft am $p3. Platz für die Ausgabe wird reserviert.';
  }

  @override
  String get nonThinking => 'Ohne Nachdenken';

  @override
  String get thinkingDefault => 'Nachdenken / Standard';

  @override
  String get contextIsOrganizedAtOfTheEffective =>
      'Der Kontext wird bei 95 % des effektiven Eingabebudgets aufbereitet, Ziel sind 60 %. Originaleinträge bleiben erhalten.';

  @override
  String get maximumOutputLength => 'Maximale Ausgabelänge';

  @override
  String get useModelMaximum => 'Modellmaximum verwenden';

  @override
  String get useTheVerifiedMaximumOutputForThe =>
      'Geprüfte maximale Ausgabe des tatsächlichen Modells verwenden';

  @override
  String get keepYourCustomOutputLength => 'Eigene Ausgabelänge beibehalten';

  @override
  String get theMaximumOutputForThisApiIs =>
      'Die maximale Ausgabe dieser API ist ungeprüft. Es werden 4096 Tokens verwendet; ein eigener Wert ist möglich.';

  @override
  String modelMaximumOutputTokensRequestsAdjustTo(String p0) {
    return 'Maximale Modellausgabe: $p0 Tokens. Anfragen passen sich dem verbleibenden Kontext an; das Modell kann früher enden.';
  }

  @override
  String get contextLength => 'Kontextlänge';

  @override
  String get customOutputLength => 'Eigene Ausgabelänge';

  @override
  String get lengthsAreInTokensSomeModelsCount =>
      'Längen werden in Tokens angegeben. Einige Modelle zählen Nachdenken zur Ausgabe.';

  @override
  String get outputLengthParameter => 'Parameter für Ausgabelänge';

  @override
  String get standardParameter => 'Standardparameter';

  @override
  String get completionLengthParameter => 'Parameter für Fertigstellungslänge';

  @override
  String get chooseAccordingToTheProviderSApi =>
      'Gemäß Anbieter-API wählen. Die eingegebene Ausgabelänge wird dadurch nicht geändert.';

  @override
  String get notTested => 'Nicht getestet';

  @override
  String get processing => 'Wird verarbeitet…';

  @override
  String get saveModel => 'Modell speichern';

  @override
  String emailCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 E-Mails',
      one: '1 E-Mail',
    );
    return '$_temp0';
  }

  @override
  String expandEmailCount(int p0) {
    return 'Alle $p0 anzeigen';
  }

  @override
  String get previousEmailPage => 'Vorherige E-Mail-Seite';

  @override
  String get nextEmailPage => 'Nächste E-Mail-Seite';

  @override
  String get collapse => 'Einklappen';

  @override
  String get qqMail => 'QQ Mail';

  @override
  String get enableMailServices => 'Maildienste aktivieren';

  @override
  String get signInToQqMailInA =>
      'Im Desktop-Browser bei QQ Mail anmelden. Unter Einstellungen → Konto und Sicherheit → Sicherheit POP3/IMAP/SMTP aktivieren.';

  @override
  String get generateAnAppPassword => 'App-Passwort erstellen';

  @override
  String get completeIdentityVerificationOnTheOfficialPage =>
      'Auf der offiziellen Seite die Identität bestätigen, ein 16-stelliges App-Passwort erstellen und hier eingeben.';

  @override
  String get returnToAccountForm => 'Zur Kontoeingabe zurück';

  @override
  String get enterTheFullEmailAddressServersAre =>
      'Vollständige E-Mail-Adresse eingeben. Server sind vorausgefüllt. Verbindung vor dem Speichern testen.';

  @override
  String get getAndManageAppPasswords =>
      'App-Passwörter erhalten und verwalten';

  @override
  String get mail368 => '163 Mail';

  @override
  String get enableImapSmtp => 'IMAP/SMTP aktivieren';

  @override
  String get signInToWebmailFindPopSmtp =>
      'Bei 163-Webmail anmelden. In den Einstellungen POP3/SMTP/IMAP suchen und IMAP/SMTP aktivieren.';

  @override
  String get getAClientAppPassword => 'Client-App-Passwort erhalten';

  @override
  String get completeTheVerificationAsInstructedAndEnter =>
      'Verifizierung gemäß Anleitung abschließen und das erstellte Client-Passwort hier eingeben.';

  @override
  String get checkTheFullEmailAddress => 'Vollständige E-Mail-Adresse prüfen';

  @override
  String get useYourFullComAddressIfYou =>
      'Vollständige @163.com-Adresse verwenden. Falls die Einstellung fehlt, in der offiziellen NetEase-Hilfe nach „授权码“ oder „IMAP“ suchen.';

  @override
  String get neteaseMailOfficialHelp => 'Offizielle NetEase-Mail-Hilfe';

  @override
  String get alibabaBusinessMail => 'Alibaba Business Mail';

  @override
  String get checkClientPermissions => 'Clientberechtigungen prüfen';

  @override
  String get askTheAdministratorToAllowThirdParty =>
      'Administrator um Erlaubnis für Drittanbieter-Clients und Aktivierung von IMAP/SMTP bitten. Neue Geschäftskonten können Drittanbieter-Clients standardmäßig sperren.';

  @override
  String get prepareASecurityPassword => 'Sicherheitspasswort vorbereiten';

  @override
  String get inWebmailGoToSettingsAccountAnd =>
      'Im Webmail unter Einstellungen → Konto und Sicherheit ein Sicherheitspasswort für Drittanbieter-Clients erstellen und nach Aktivierung hier verwenden.';

  @override
  String get enterTheBusinessEmailAddress =>
      'Geschäftliche E-Mail-Adresse eingeben';

  @override
  String get useTheFullBusinessAddressDefaultServers =>
      'Vollständige Geschäftsadresse verwenden. Standardserver sind vorausgefüllt; für Hongkong oder Firmeneinstellungen unter den erweiterten Einstellungen ändern.';

  @override
  String get allowThirdPartyClients => 'Drittanbieter-Clients zulassen';

  @override
  String get generateAThirdPartyClientSecurityPassword =>
      'Sicherheitspasswort für Drittanbieter-Clients erstellen';

  @override
  String get serverAddressesAndPorts => 'Serveradressen und Ports';

  @override
  String get alibabaPersonalMail => 'Alibaba Privatmail';

  @override
  String get checkAccountType => 'Kontotyp prüfen';

  @override
  String get thisPresetIsForFreeAlibabaCloud =>
      'Diese Voreinstellung gilt für kostenlose Alibaba-Cloud-Privatmail. Bei Firmendomains Alibaba Business wählen.';

  @override
  String get prepareLoginDetails => 'Anmeldedaten vorbereiten';

  @override
  String get enterTheFullEmailAddressAndRequired =>
      'Vollständige Adresse und benötigte Zugangsdaten eingeben. Sicherstellen, dass Clientzugriff erlaubt ist.';

  @override
  String get checkServers => 'Server prüfen';

  @override
  String get useTheOfficialSslServerSettingsBelow =>
      'Offizielle SSL-Servereinstellungen unten verwenden. Verbindung vor dem Speichern testen.';

  @override
  String get personalMailServersAndPorts => 'Privatmail-Server und Ports';

  @override
  String get customEmailProvider => 'Eigener E-Mail-Anbieter';

  @override
  String get identifyYourProvider => 'Anbieter feststellen';

  @override
  String get aCustomDomainDoesNotIdentifyThe =>
      'Eine eigene Domain identifiziert den E-Mail-Anbieter nicht. Den Mailadministrator fragen.';

  @override
  String get getConnectionSettings => 'Verbindungseinstellungen besorgen';

  @override
  String get prepareImapAndSmtpHostsPortsEncryption =>
      'IMAP- und SMTP-Hosts, Ports, Verschlüsselung und Passwort oder App-Passwort bereithalten.';

  @override
  String get enterAndVerify => 'Eingeben und prüfen';

  @override
  String get expandServerAndAdvancedSettingsAndEnter =>
      'Server und erweiterte Einstellungen öffnen und die Anbieterdaten eingeben.';

  @override
  String setupGuide(String p0) {
    return 'Einrichtungsanleitung für $p0';
  }

  @override
  String get closeSetupGuide => 'Einrichtungsanleitung schließen';

  @override
  String get defaultServersSsl => 'Standardserver · SSL';

  @override
  String incomingPortOutgoingPort(String p0, String p1) {
    return 'Eingang  $p0\nPort 993\n\nAusgang  $p1\nPort 465';
  }

  @override
  String get officialHelp => 'Offizielle Hilfe';

  @override
  String verifiedOfficialPagesOpenInYourBrowser(String p0) {
    return 'Geprüft: $p0 · offizielle Seiten öffnen sich im Browser';
  }

  @override
  String get returnToForm => 'Zum Formular zurück';

  @override
  String get mailpilotPreview => 'MailPilot · Vorschau';

  @override
  String get thisLinkIsNotAValidWeb =>
      'Dieser Link ist keine gültige Webadresse';

  @override
  String get openWebpage => 'Webseite öffnen';

  @override
  String get copyLink => 'Link kopieren';

  @override
  String get openInBrowser => 'Im Browser öffnen';

  @override
  String image(String p0) {
    return '[Bild $p0]';
  }

  @override
  String get sizeUnknown => 'Größe unbekannt';

  @override
  String get firstPagesByDefaultPageCountPending =>
      'Standardmäßig erste 10 Seiten; Seitenzahl noch offen';

  @override
  String get selectPdfPageNumbers => 'PDF-Seitennummern auswählen';

  @override
  String page(String p0) {
    return 'Seite $p0';
  }

  @override
  String get fileName => 'Dateiname';

  @override
  String get deselect => 'Auswahl aufheben';

  @override
  String get select420 => 'Auswählen';

  @override
  String get materialsForThisAnalysis => 'Materialien für diese Analyse';

  @override
  String materialSummary(String p0, String p1, String p2) {
    return '$p0 Anhänge · $p1$p2';
  }

  @override
  String withUnknownSize(String p0) {
    return ' · $p0 mit unbekannter Größe';
  }

  @override
  String get closeMaterials => 'Materialien schließen';

  @override
  String upToAttachmentsMbAndImagesOr(String p0) {
    return 'Pro Runde bis zu 10 Anhänge, 50 MB und 20 Bilder oder PDF-Seiten.\n$p0';
  }

  @override
  String get actualImageCountsInPdfAndOffice =>
      'Die tatsächliche Bildanzahl in PDF- und Office-Dateien wird beim Lesen geprüft.';

  @override
  String get selectedFilesAreReadOnlyWhenPreviewing =>
      'Ausgewählte Dateien werden nur zur Vorschau oder bei einer Frage gelesen.';

  @override
  String get attachmentListAwaitingSync =>
      'Anhangsliste wartet auf Synchronisierung';

  @override
  String get selectAllSupportedAttachments =>
      'Alle unterstützten Anhänge auswählen';

  @override
  String get keepBodyOnly => 'Nur Nachrichtentext behalten';

  @override
  String get deviceFiles => 'Gerätedateien';

  @override
  String get noMaterialsSelectedAddFilesOrSelect =>
      'Keine Materialien ausgewählt. Dateien hinzufügen oder E-Mails auswählen.';

  @override
  String get materialCheckIncomplete => 'Materialprüfung unvollständig';

  @override
  String get retryWithCurrentMaterials =>
      'Mit aktuellen Materialien erneut versuchen';

  @override
  String get analyzedImages => 'Analysierte Bilder';

  @override
  String get previousAnalysisIsReusedByDefaultSelect =>
      'Die vorherige Analyse wird standardmäßig wiederverwendet. Für neue Details erneut prüfen wählen; gilt ab der nächsten Nachricht.';

  @override
  String get cancelRecheck => 'Erneute Prüfung abbrechen';

  @override
  String get recheckImages => 'Bilder erneut prüfen';

  @override
  String get previousVersion => 'Vorherige Version';

  @override
  String messageVersionCount(String p0, String p1) {
    return 'Version $p0 von $p1';
  }

  @override
  String get nextVersion => 'Nächste Version';

  @override
  String get closeMessageActions => 'Nachrichtenaktionen schließen';

  @override
  String get copyMessage => 'Nachricht kopieren';

  @override
  String get messageCopied => 'Nachricht kopiert';

  @override
  String close(String p0) {
    return '$p0 schließen';
  }

  @override
  String get volcengineArk => 'Volcengine · Ark';

  @override
  String get alibabaCloudModelStudio => 'Alibaba Cloud · Model Studio';

  @override
  String get openaiCompatibleApi => 'OpenAI-kompatible API';

  @override
  String get minimalMinimal => 'Minimal · minimal';

  @override
  String get lowLow => 'Niedrig · low';

  @override
  String get mediumMedium => 'Mittel · medium';

  @override
  String get highHigh => 'Hoch · high';

  @override
  String get veryHighXhigh => 'Sehr hoch · xhigh';

  @override
  String get maximumMax => 'Maximum · max';

  @override
  String get chooseImageProcessing => 'Bildverarbeitung wählen';

  @override
  String get yourQuestionMaterialsAndCompletedAnalysisAre =>
      'Frage, Materialien und abgeschlossene Analysen bleiben erhalten.';

  @override
  String get adjustMaterials => 'Materialien anpassen';

  @override
  String get reduceImagesPagesOrTextAndSubmit =>
      'Bilder, Seiten oder Text reduzieren und erneut senden';

  @override
  String get processThisTurnInBatches => 'Diese Runde in Stapeln verarbeiten';

  @override
  String get readUnfinishedImagesInBatchesThenSummarize =>
      'Offene Bilder in Stapeln lesen und anschließend zusammenfassen';

  @override
  String get couldNotReadThisPage => 'Diese Seite konnte nicht gelesen werden';

  @override
  String get couldNotReadThisPagePleaseRetry =>
      'Diese Seite konnte nicht gelesen werden. Bitte erneut versuchen.';

  @override
  String get closePagePreview => 'Seitenvorschau schließen';

  @override
  String get pageImageUnavailable => 'Seitenbild nicht verfügbar';

  @override
  String get selectPdfPages => 'PDF-Seiten auswählen';

  @override
  String pagesTotal(String p0) {
    return ' · insgesamt $p0 Seiten';
  }

  @override
  String pagesSelectedMaximum(String p0) {
    return '$p0 Seiten ausgewählt / maximal 20';
  }

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get firstPages => 'Erste 10 Seiten';

  @override
  String get clear => 'Leeren';

  @override
  String get readingPdf => 'PDF wird gelesen…';

  @override
  String get couldNotReadPageNumbers =>
      'Seitennummern konnten nicht gelesen werden';

  @override
  String get retryReading => 'Lesen erneut versuchen';

  @override
  String get selectUpToPagesPerPdf => 'Bis zu 20 Seiten pro PDF auswählen';

  @override
  String get deselectThisAttachment => 'Diesen Anhang abwählen';

  @override
  String confirmSelectionPages(String p0) {
    return 'Auswahl bestätigen · $p0 Seiten';
  }

  @override
  String get retryPreview => 'Vorschau erneut versuchen';

  @override
  String previewPage(String p0) {
    return 'Vorschau von Seite $p0';
  }

  @override
  String get loadingPreview => 'Vorschau wird geladen…';

  @override
  String page480(String p0, String p1) {
    return '$p0, Seite $p1';
  }

  @override
  String reasoningSegmentHeading(String p0) {
    return 'Nachdenken $p0\n';
  }

  @override
  String get searching => 'Suche läuft';

  @override
  String get searchIncomplete => 'Suche unvollständig';

  @override
  String searchResultCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 Ergebnisse gefunden',
      one: '1 Ergebnis gefunden',
    );
    return '$_temp0';
  }

  @override
  String get readingWebpages => 'Webseiten werden gelesen';

  @override
  String readWebpageCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 Webseiten gelesen',
      one: '1 Webseite gelesen',
    );
    return '$_temp0';
  }

  @override
  String get webpageReadingFinished => 'Lesen der Webseiten beendet';

  @override
  String get readingMaterials => 'Materialien werden gelesen';

  @override
  String get sourceExcerptViewed => 'Quellenauszug angesehen';

  @override
  String get materialsReused => 'Materialien wiederverwendet';

  @override
  String get searchingEmails => 'E-Mails werden durchsucht';

  @override
  String get emailsSearched => 'E-Mails durchsucht';

  @override
  String get processing493 => 'Verarbeitung läuft';

  @override
  String get actionCompleted => 'Aktion abgeschlossen';

  @override
  String get lessThanSecond => 'Weniger als 1 Sekunde';

  @override
  String elapsedSeconds(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 Sekunden',
      one: '1 Sekunde',
    );
    return '$_temp0';
  }

  @override
  String get thinking497 => 'Denkt nach';

  @override
  String get thinkingStopped => 'Nachdenken gestoppt';

  @override
  String get thinkingInterrupted => 'Nachdenken unterbrochen';

  @override
  String get process => 'Ablauf';

  @override
  String get thought => 'Nachgedacht';

  @override
  String get reasoning => 'Denkverlauf';

  @override
  String get viewReasoning => 'Denkverlauf anzeigen';

  @override
  String get currentAttempt => 'Aktueller Versuch';

  @override
  String get previousAttempt => 'Vorheriger Versuch';

  @override
  String earlierAttempt(String p0) {
    return 'Früherer Versuch $p0';
  }

  @override
  String get viewingAPreviousAttempt => 'Vorheriger Versuch wird angezeigt';

  @override
  String get reasoningIsLongTheFirstCharactersHave =>
      'Der Denkverlauf ist lang. Die ersten 128000 Zeichen wurden behalten.';

  @override
  String get jumpToEndOfReasoning => 'Zum Ende des Denkverlaufs';

  @override
  String get uiPreviewSampleDataInstallAndroidTo =>
      'UI-Vorschau · Beispieldaten. Zum Verbinden von E-Mail und Modellen Android-Version installieren.';

  @override
  String get dismissNotice => 'Hinweis schließen';

  @override
  String get backToHome => 'Zur Startseite';

  @override
  String get backToSettings => 'Zurück zu Einstellungen';

  @override
  String get backToConversation => 'Zurück zum Gespräch';

  @override
  String get openMenu => 'Menü öffnen';

  @override
  String get noVersionsAvailable => 'Keine Versionen vorhanden';

  @override
  String get couldNotLoadVersionsPleaseRetry =>
      'Versionen konnten nicht geladen werden. Bitte erneut versuchen.';

  @override
  String get cannotEditThisQuestion =>
      'Diese Frage kann nicht bearbeitet werden';

  @override
  String get couldNotEditThisQuestionPleaseRetry =>
      'Frage konnte nicht bearbeitet werden. Bitte erneut versuchen.';

  @override
  String get editNotSubmittedPleaseRetry =>
      'Bearbeitung wurde nicht gesendet. Bitte erneut versuchen.';

  @override
  String get addAModelFirst => 'Zuerst ein Modell hinzufügen';

  @override
  String get materialCheckIncompletePleaseRetry =>
      'Materialprüfung unvollständig. Bitte erneut versuchen.';

  @override
  String get newConversation => 'Neues Gespräch';

  @override
  String get whatSOnYourMind => 'Worüber möchten Sie sprechen?';

  @override
  String get letSMakeSenseOfYourEmails =>
      'Bringen wir Klarheit in Ihre E-Mails.';

  @override
  String get configureAModelToChatYouCan =>
      'Modell konfigurieren, um zu chatten. E-Mail kann später hinzugefügt werden.';

  @override
  String get askAQuestionOrSelectEmailsAs =>
      'Frage stellen oder E-Mails als Kontext auswählen.';

  @override
  String get helpMeOrganizeMyThoughts => 'Hilf mir, meine Gedanken zu ordnen';

  @override
  String get helpMeWriteSomething => 'Hilf mir, einen Text zu schreiben';

  @override
  String get summarizeSelectedEmails => 'Ausgewählte E-Mails zusammenfassen';

  @override
  String get helpMeDraftAReply => 'Hilf mir, eine Antwort zu entwerfen';

  @override
  String get retryWebSearch => 'Websuche erneut versuchen';

  @override
  String get answerWithoutSearch => 'Ohne Suche antworten';

  @override
  String get continueSearching => 'Weitersuchen';

  @override
  String get responseIncomplete => 'Antwort unvollständig';

  @override
  String get continueOrganizing => 'Aufbereitung fortsetzen';

  @override
  String get retryThisTurn => 'Diese Runde erneut versuchen';

  @override
  String get viewBudget => 'Budget anzeigen';

  @override
  String get retryWithCompatibleFormat =>
      'Mit kompatiblem Format erneut versuchen';

  @override
  String get chooseProcessingMethod => 'Verarbeitungsmethode wählen';

  @override
  String get adjustMaterialsAndRetry =>
      'Materialien anpassen und erneut versuchen';

  @override
  String get restoreDefaultThinkingAndRetry =>
      'Standard-Denkmodus wiederherstellen und erneut versuchen';

  @override
  String get chooseVisionAssistant => 'Visuellen Assistenten wählen';

  @override
  String get editConfiguration => 'Konfiguration bearbeiten';

  @override
  String vision(String p0) {
    return 'Bildanalyse · $p0';
  }

  @override
  String sourceCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 Quellen',
      one: '1 Quelle',
    );
    return '$_temp0';
  }

  @override
  String get copyResponse => 'Antwort kopieren';

  @override
  String get originalMarkdownCopied => 'Markdown-Original kopiert';

  @override
  String get responseStopped => 'Antwort gestoppt';

  @override
  String get stoppedThePartialResponseReceivedIsShown =>
      'Gestoppt. Oben steht die bisher empfangene Teilantwort.';

  @override
  String get reviewDraftAndSend => 'Entwurf prüfen und senden';

  @override
  String get writeAsEmail => 'Als E-Mail verfassen';

  @override
  String get connectingToModel => 'Verbindung zum Modell wird hergestellt…';

  @override
  String get viewingAnOlderVersion => 'Frühere Version wird angezeigt';

  @override
  String get backToLatest => 'Zur neuesten Version';

  @override
  String get textModel => 'Textmodell';

  @override
  String tapToCancelSync(String p0) {
    return '$p0 · tippen, um Synchronisierung abzubrechen';
  }

  @override
  String get syncLatestEmailsInEachFolder =>
      'Neueste 50 E-Mails je Ordner synchronisieren';

  @override
  String get searchEmails => 'E-Mails suchen';

  @override
  String get emailActions => 'E-Mail-Aktionen';

  @override
  String get syncEmailsPerFolder => 'E-Mails synchronisieren (50 je Ordner)';

  @override
  String get showAll => 'Alle anzeigen';

  @override
  String get showUnread => 'Ungelesene anzeigen';

  @override
  String get subjectOrSender => 'Betreff oder Absender';

  @override
  String get runSearch => 'Suche ausführen';

  @override
  String get connectAnEmailAccountFirst => 'Zuerst ein E-Mail-Konto verbinden';

  @override
  String get supportsQqAndCustomEmailProviders =>
      'Unterstützt QQ, 163 und eigene E-Mail-Anbieter.';

  @override
  String get noLocalEmailsYet => 'Noch keine lokalen E-Mails';

  @override
  String get pullDownToSyncRecentEmailsStartup =>
      'Nach unten ziehen zum Synchronisieren. Beim Start wird nicht automatisch synchronisiert.';

  @override
  String analyzeSelectedEmails(String p0) {
    return '$p0 ausgewählte E-Mails analysieren';
  }

  @override
  String get emailDetails => 'E-Mail-Details';

  @override
  String get replyAndForward => 'Antworten und weiterleiten';

  @override
  String get reply => 'Antworten';

  @override
  String get replyAll => 'Allen antworten';

  @override
  String get forward => 'Weiterleiten';

  @override
  String get recipientDetails => 'Empfängerdetails';

  @override
  String toCc(String p0, String p1) {
    return 'An: $p0\nCc: $p1';
  }

  @override
  String get bodyAwaitingBackgroundSyncYouCanKeep =>
      'Nachrichtentext wartet auf Hintergrundsynchronisierung. Andere E-Mails können weiter angesehen werden.';

  @override
  String attachments(String p0) {
    return 'Anhänge · $p0';
  }

  @override
  String get tapAnAttachmentToPreviewSelectIt =>
      'Anhang antippen für Vorschau; für KI-Analyse auswählen';

  @override
  String get askAssistant => 'Assistenten fragen';

  @override
  String get noDraftsYet => 'Noch keine Entwürfe';

  @override
  String get writeYourOwnOrAskTheAssistant =>
      'Selbst schreiben oder den Assistenten um einen Entwurf bitten.';

  @override
  String get configurationSaved => 'Konfiguration gespeichert';

  @override
  String get closeConfiguration => 'Konfiguration schließen';

  @override
  String get actionFailed => 'Aktion fehlgeschlagen';

  @override
  String get backToConfiguration => 'Zurück zur Konfiguration';

  @override
  String get volcengineWebSearch => 'Volcengine-Websuche';

  @override
  String get bocha => 'Bocha';

  @override
  String get systemPreferredCloudOptional => 'System bevorzugt, Cloud optional';

  @override
  String get qwenCloudTranscription => 'Qwen-Cloud-Transkription';

  @override
  String get automaticSystemRecognitionFollowsDeviceLanguage =>
      'Automatisch (Systemerkennung folgt der Gerätesprache)';

  @override
  String get chinese => 'Chinesisch';

  @override
  String get searchProvider => 'Suchanbieter';

  @override
  String get recognitionMode => 'Erkennungsmodus';

  @override
  String get speechLanguage => 'Sprache der Spracherkennung';

  @override
  String get automatic => 'Automatisch';

  @override
  String get systemRecognitionNeedsNoApiKeyIf =>
      'Systemerkennung benötigt keinen API-Schlüssel. Falls das Gerät keinen Erkennungsdienst hat, kann unten Qwen ASR verwendet werden.';

  @override
  String get usedOnlyWhenSmartSearchIsEnabled =>
      'Wird nur bei aktivierter intelligenter Suche und einer Frage verwendet. Der Suchdienst erhält extrahierte Suchbegriffe, keine E-Mails, Anhänge oder Chatverläufe.';

  @override
  String get qwenAsrBaseUrl => 'Qwen-ASR-Basis-URL';

  @override
  String get fullSearchApiUrl => 'Vollständige Such-API-URL';

  @override
  String get leaveBlankToRetainTheSavedKey =>
      'Leer lassen, um gespeicherten Schlüssel zu behalten';

  @override
  String get showOrHideKey => 'Schlüssel ein- oder ausblenden';

  @override
  String get asrModel => 'ASR-Modell';

  @override
  String get forExampleQwenAsrFlash => 'Zum Beispiel qwen3-asr-flash';

  @override
  String get transcriptionFillsTheInputFieldOnlyReview =>
      'Die Transkription füllt nur das Eingabefeld; vor dem Senden prüfen. Cloud-Modus erfordert eine neue Aufnahme von höchstens 60 Sekunden.';

  @override
  String get streamingUiStateIsOutOfSync =>
      'Streaming-Oberfläche ist nicht synchron. Gespräch erneut öffnen.';

  @override
  String get streamNotReceivedCompletelyReopenThisConversation =>
      'Stream wurde nicht vollständig empfangen. Gespräch erneut öffnen.';

  @override
  String get appLanguage => 'Sprache';

  @override
  String get languageTitle => 'Sprache wählen';

  @override
  String get languageDescription =>
      'Ändert die Sprache der Oberfläche. E-Mails und Gespräche behalten ihren ursprünglichen Inhalt.';
}
