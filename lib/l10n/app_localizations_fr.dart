// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get switchAccount => 'Changer de compte';

  @override
  String get closeAccountPicker => 'Fermer le sélecteur de compte';

  @override
  String switchAccountCurrent(String p0) {
    return 'Changer de compte, actuel : $p0';
  }

  @override
  String get openWithAnotherApp => 'Ouvrir avec une autre application';

  @override
  String get openInAnotherApp => 'Ouvrir dans une autre application';

  @override
  String get saveToDevice => 'Enregistrer sur l’appareil';

  @override
  String get couldNotStartRecording =>
      'Impossible de démarrer l’enregistrement';

  @override
  String get addImage => 'Ajouter une image';

  @override
  String get addFile => 'Ajouter un fichier';

  @override
  String get selectEmails => 'Sélectionner des e-mails';

  @override
  String get manageImportedMaterials => 'Gérer les documents importés';

  @override
  String get deepThinking => 'Réflexion approfondie';

  @override
  String get editInput => 'Modifier la saisie';

  @override
  String get cancelEdit => 'Annuler la modification';

  @override
  String selectedMaterialsCount(int p0, int p1) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 e-mails',
      one: '1 e-mail',
    );
    String _temp1 = intl.Intl.pluralLogic(
      p1,
      locale: localeName,
      other: '$p1 pièces jointes',
      one: '1 pièce jointe',
    );
    return '$_temp0 · $_temp1 sélectionnés';
  }

  @override
  String get clearSelection => 'Effacer la sélection';

  @override
  String get listeningUpToSeconds => 'Écoute en cours · 60 secondes maximum';

  @override
  String get transcribing => 'Transcription…';

  @override
  String get startingMicrophone => 'Démarrage du microphone…';

  @override
  String get recordAgainInCloudMode => 'Réenregistrer en mode cloud';

  @override
  String get cancelVoiceInput => 'Annuler la saisie vocale';

  @override
  String get askAboutSelectedMaterials =>
      'Posez une question sur les documents sélectionnés…';

  @override
  String get messageOrUseVoiceInput => 'Écrivez ou utilisez la voix';

  @override
  String get smartSearch => 'Recherche intelligente';

  @override
  String get thinking => 'Réflexion';

  @override
  String get search => 'Rechercher';

  @override
  String get addAttachment => 'Ajouter une pièce jointe';

  @override
  String get stopResponse => 'Arrêter la réponse';

  @override
  String get stopRecording => 'Arrêter l’enregistrement';

  @override
  String get sendQuestion => 'Envoyer la question';

  @override
  String get voiceInput => 'Saisie vocale';

  @override
  String get draftDeleted => 'Brouillon supprimé';

  @override
  String get pleaseViewTheLatestVersion => 'Consultez la dernière version';

  @override
  String get from => 'De';

  @override
  String get to => 'À';

  @override
  String get cc => 'Cc';

  @override
  String get bcc => 'Cci';

  @override
  String get notEntered => 'Non renseigné';

  @override
  String get noSubject => '(Sans objet)';

  @override
  String get afterReviewingConfirmSendingOrTapThe =>
      'Vérifiez le contenu puis confirmez l’envoi ou appuyez sur le bouton ci-dessous.';

  @override
  String get confirmSend => 'Confirmer l’envoi';

  @override
  String get addRecipient => 'Ajouter un destinataire';

  @override
  String get viewLatestVersion => 'Voir la dernière version';

  @override
  String get reviewAndEdit => 'Vérifier et modifier';

  @override
  String get editEmail => 'Modifier l’e-mail';

  @override
  String get jumpToLatestMessage => 'Aller au dernier message';

  @override
  String get inbox => 'Boîte de réception';

  @override
  String get sent => 'Envoyés';

  @override
  String get drafts => 'Brouillons';

  @override
  String get deleted => 'Supprimés';

  @override
  String get spam => 'Indésirables';

  @override
  String get archive => 'Archives';

  @override
  String get mailFolders => 'Dossiers de messagerie';

  @override
  String get refreshFolders => 'Actualiser les dossiers';

  @override
  String couldNotRefreshFoldersLocalListRetained(String p0) {
    return 'Impossible d’actualiser les dossiers. La liste locale est conservée. $p0';
  }

  @override
  String get unreadOnly => 'Non lus uniquement';

  @override
  String get deleteThisDraft => 'Supprimer ce brouillon ?';

  @override
  String get onlyTheLocalDraftIsDeletedChats =>
      'Seul le brouillon local est supprimé. Les discussions et les e-mails du serveur sont conservés.';

  @override
  String get delete => 'Supprimer';

  @override
  String get draftActions => 'Actions du brouillon';

  @override
  String get rewrite => 'Réécrire';

  @override
  String get deleteDraft => 'Supprimer le brouillon';

  @override
  String get recipientEmail => 'E-mail du destinataire';

  @override
  String get separateMultipleAddressesWithCommas =>
      'Séparez les adresses par des virgules';

  @override
  String get afterSavingReviewTheNewConfirmationCard =>
      'Après l’enregistrement, vérifiez la nouvelle carte de confirmation avant l’envoi.';

  @override
  String get saveRecipients => 'Enregistrer les destinataires';

  @override
  String get draftAnswerPrompt =>
      'Rédigez un e-mail formel à partir de cette réponse :';

  @override
  String get draftAnswerPromptSuffix =>
      'Pour que je puisse vérifier et confirmer avant l’envoi.';

  @override
  String get turnThisAnswerIntoAnEmail => 'Transformer cette réponse en e-mail';

  @override
  String get viewOriginalOfOlderVersion =>
      'Voir l’original de l’ancienne version';

  @override
  String get messageActions => 'Actions du message';

  @override
  String get needsVerification => 'À vérifier';

  @override
  String get sending => 'Envoi en cours';

  @override
  String get sendFailed => 'Échec de l’envoi';

  @override
  String get confirm => 'Confirmer';

  @override
  String get cancel => 'Annuler';

  @override
  String attachmentCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 pièces jointes',
      one: '1 pièce jointe',
    );
    return '$_temp0';
  }

  @override
  String select(String p0) {
    return 'Sélectionner $p0';
  }

  @override
  String get emailAndModelConnectionsRequireAndroidUse =>
      'Les connexions de messagerie et de modèles nécessitent Android. Utilisez ici l’aperçu.';

  @override
  String get notConnectedToTheAndroidMailService =>
      'Non connecté au service de messagerie Android. Fermez complètement puis rouvrez le dernier APK. Dans les navigateurs et Widget Preview, utilisez l’entrée d’aperçu.';

  @override
  String get actionIncomplete => 'Action incomplète';

  @override
  String get thisFeatureIsUnavailableInTheCurrent =>
      'Cette fonction est indisponible dans cet environnement';

  @override
  String get pin => 'Épingler';

  @override
  String get today => 'Aujourd’hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get previousDays => '7 derniers jours';

  @override
  String get previousDays86 => '30 derniers jours';

  @override
  String olderConversationDate(String p0, String p1, String p2) {
    return '$p2/$p1/$p0';
  }

  @override
  String get loadingConversations => 'Chargement des conversations';

  @override
  String get noMatchingConversations => 'Aucune conversation correspondante';

  @override
  String get yourConversationsWillAppearHere =>
      'Vos conversations apparaîtront ici';

  @override
  String get tryShorterKeywordsOrClearTheSearch =>
      'Essayez des mots plus courts ou effacez la recherche.';

  @override
  String get startAChatAndComeBackAnytime =>
      'Démarrez une discussion et reprenez-la à tout moment.';

  @override
  String get clearSearch => 'Effacer la recherche';

  @override
  String get startAConversation => 'Démarrer une conversation';

  @override
  String get couldNotLoadConversationsTapToRetry =>
      'Impossible de charger les conversations. Appuyez pour réessayer.';

  @override
  String get renameConversation => 'Renommer la conversation';

  @override
  String get enterConversationName => 'Nom de la conversation';

  @override
  String get save => 'Enregistrer';

  @override
  String deleteConversationCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: 'Supprimer $p0 conversations ?',
      one: 'Supprimer 1 conversation ?',
    );
    return '$_temp0';
  }

  @override
  String get chatsSummariesAndAnalysisCachesForThese =>
      'Les discussions, résumés et caches d’analyse de ces conversations seront supprimés. Les e-mails et brouillons sont conservés.';

  @override
  String get rename => 'Renommer';

  @override
  String get unpin => 'Désépingler';

  @override
  String get selectMultiple => 'Sélection multiple';

  @override
  String selectedConversationCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 conversations sélectionnées',
      one: '1 conversation sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String get exitSelection => 'Quitter la sélection';

  @override
  String get closeSidebar => 'Fermer le volet latéral';

  @override
  String get searchConversations => 'Rechercher des conversations…';

  @override
  String get conversationSummary => 'Résumé de la conversation';

  @override
  String get loading => 'Chargement…';

  @override
  String get loadMore => 'Charger plus';

  @override
  String get selectConversations => 'Sélectionner des conversations';

  @override
  String get settings => 'Paramètres';

  @override
  String get thisConversationSSummary => 'Résumé de cette conversation';

  @override
  String summarizedMessageCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 anciens messages résumés',
      one: '1 ancien message résumé',
    );
    return '$_temp0';
  }

  @override
  String get closeSummary => 'Fermer le résumé';

  @override
  String get originalMessagesAreRetainedYouCanAdd =>
      'Les messages d’origine sont conservés. Vous pouvez ajouter des informations ou des corrections.';

  @override
  String get noSummaryForThisConversationYet =>
      'Cette conversation n’a pas encore de résumé.';

  @override
  String get conversationChangedPleaseReopenTheSummary =>
      'La conversation a changé. Rouvrez le résumé.';

  @override
  String get draftingReadOnlyPreview => 'Rédaction · aperçu en lecture seule';

  @override
  String get incompleteCannotSend => 'Incomplet · envoi impossible';

  @override
  String get draftingEmail => 'Rédaction d’e-mail';

  @override
  String get generatingResponse => 'Génération de la réponse';

  @override
  String get readingImages => 'Lecture des images';

  @override
  String get preparingMaterials => 'Préparation des documents';

  @override
  String get generatingContent => 'Génération du contenu';

  @override
  String get parsingModelAction => 'Analyse de l’action du modèle';

  @override
  String get organizingExistingResults =>
      'Organisation des résultats existants';

  @override
  String get organizingContext => 'Organisation du contexte';

  @override
  String get webSearch => 'Recherche web';

  @override
  String get currentRequest => 'Requête actuelle';

  @override
  String get requestId => 'ID de requête';

  @override
  String get serverId => 'ID du serveur';

  @override
  String get httpStatus => 'Statut HTTP';

  @override
  String get finishReason => 'Motif de fin';

  @override
  String get exceptionType => 'Type d’exception';

  @override
  String get validationResult => 'Résultat de validation';

  @override
  String get requestBudgetAndDiagnostics =>
      'Budget et diagnostic de la requête';

  @override
  String get connectionDiagnostics => 'Diagnostic de connexion';

  @override
  String get requestRecordsForThisTurn => 'Requêtes de ce tour';

  @override
  String get closeDiagnostics => 'Fermer le diagnostic';

  @override
  String get processingStage => 'Étape du traitement';

  @override
  String get model => 'Modèle';

  @override
  String get apiHost => 'Hôte de l’API';

  @override
  String get imageProcessing => 'Traitement des images';

  @override
  String get fullTextAndImageResponse =>
      'Réponse complète avec texte et images';

  @override
  String get visionAssistantReading => 'Lecture par l’assistant visuel';

  @override
  String get batchProcessingSelectedForThisTurn =>
      'Traitement par lots choisi pour ce tour';

  @override
  String get reusingPreviousAnalysis => 'Réutilisation de l’analyse précédente';

  @override
  String get requestsWithImages => 'Requêtes avec images';

  @override
  String requestCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 requêtes',
      one: '1 requête',
    );
    return '$_temp0';
  }

  @override
  String get totalImagesUploaded => 'Total d’images envoyées';

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
  String get reusedImages => 'Images réutilisées';

  @override
  String get batchingReason => 'Motif du traitement par lots';

  @override
  String get estimatedInput => 'Entrée estimée';

  @override
  String get availableInputBudget => 'Budget d’entrée disponible';

  @override
  String get configuredContext => 'Contexte configuré';

  @override
  String get outputReserve => 'Réserve de sortie';

  @override
  String get thinkingReserve => 'Réserve de réflexion';

  @override
  String get suggestedSummaryLength => 'Longueur de résumé conseillée';

  @override
  String get summaryBudgetLimit => 'Limite du budget du résumé';

  @override
  String get currentSummaryEstimate => 'Estimation du résumé actuel';

  @override
  String get localEstimatesMayDifferFromProviderMetering =>
      'Les estimations locales peuvent différer des mesures du fournisseur. L’organisation commence à 95 % et vise 60 %.';

  @override
  String get timeToFirstChunk => 'Délai du premier fragment';

  @override
  String get lastChunkReceived => 'Dernier fragment reçu';

  @override
  String get requestDuration => 'Durée de la requête';

  @override
  String get technicalDetails => 'Détails techniques';

  @override
  String get requestIdsAndExceptionInformation =>
      'Identifiants et informations d’exception';

  @override
  String get convertedToEmailBodyReviewBeforeSaving =>
      'Converti en corps d’e-mail. Vérifiez avant d’enregistrer.';

  @override
  String get conversionFailedOriginalTextRetained =>
      'Échec de la conversion. Le texte d’origine est conservé.';

  @override
  String get discardUnsavedChanges =>
      'Abandonner les modifications non enregistrées ?';

  @override
  String get savedDraftsAreRetained =>
      'Les brouillons enregistrés sont conservés.';

  @override
  String get discardChanges => 'Abandonner les modifications';

  @override
  String get deleteThisLocalRecord => 'Supprimer cet enregistrement local ?';

  @override
  String get serverEmailsAreRetained =>
      'Les e-mails du serveur sont conservés.';

  @override
  String get composeEmail => 'Rédiger un e-mail';

  @override
  String get back => 'Retour';

  @override
  String get moreEmailActions => 'Autres actions de messagerie';

  @override
  String get saveChangesAndRewrite => 'Enregistrer et réécrire';

  @override
  String get convertMarkdownToBodyText =>
      'Convertir Markdown en texte du message';

  @override
  String get sendingAccount => 'Compte d’envoi';

  @override
  String get subject => 'Objet';

  @override
  String get body => 'Corps';

  @override
  String get sendAsThePlainTextShownHere => 'Envoyer le texte brut affiché ici';

  @override
  String get ccBcc => 'Cc / Cci';

  @override
  String remove(String p0) {
    return 'Retirer $p0';
  }

  @override
  String get firstCheckTheServerSSentFolder =>
      'Vérifiez d’abord le dossier Envoyés du serveur et la réception par les destinataires.';

  @override
  String get verifiedThatSendingSucceeded =>
      'Avez-vous vérifié que l’envoi a réussi ?';

  @override
  String get thisOnlyUpdatesTheLocalRecord =>
      'Cette action met uniquement à jour l’enregistrement local.';

  @override
  String get verifiedSentSuccessfully => 'Vérifié : envoyé';

  @override
  String get confirmedThatNoRecipientsReceivedIt =>
      'Avez-vous confirmé qu’aucun destinataire ne l’a reçu ?';

  @override
  String get restoreTheDraftToReviewAndSend =>
      'Restaurez le brouillon pour le vérifier et le renvoyer. Si certains destinataires l’ont déjà reçu, modifiez d’abord la liste.';

  @override
  String get restoreDraft => 'Restaurer le brouillon';

  @override
  String get verifiedNotSent => 'Vérifié : non envoyé';

  @override
  String get confirmSendingInChat => 'Confirmer l’envoi dans la discussion';

  @override
  String get confirmBeforeSending => 'Confirmation avant envoi';

  @override
  String get pleaseReviewTheFollowing =>
      'Veuillez vérifier les éléments suivants';

  @override
  String get accountDeleted => 'Compte supprimé';

  @override
  String get couldNotReadAttachment => 'Impossible de lire la pièce jointe';

  @override
  String get couldNotReadImagePleaseRetry =>
      'Impossible de lire l’image. Réessayez.';

  @override
  String get couldNotReadPagePleaseRetry =>
      'Impossible de lire la page. Réessayez.';

  @override
  String get reload => 'Recharger';

  @override
  String get referencedMaterial => 'Document cité';

  @override
  String get formattedView => 'Vue mise en forme';

  @override
  String get viewOriginal => 'Voir l’original';

  @override
  String get theFollowingWasGeneratedByAVision =>
      'Le contenu suivant a été généré par un modèle visuel. Comparez-le à l’image d’origine si nécessaire.';

  @override
  String get previousPage => 'Page précédente';

  @override
  String get nextPage => 'Page suivante';

  @override
  String get loadingReferencedMaterial => 'Chargement du document cité…';

  @override
  String get selectedImageOrPdfPagePinchTo =>
      'Image ou page PDF sélectionnée. Pincez pour zoomer.';

  @override
  String get imageUnavailableRetryOrOpenWithAnother =>
      'Image indisponible. Réessayez ou ouvrez avec une autre application.';

  @override
  String get pinchToZoomSavingAndExternalOpening =>
      'Pincez pour zoomer · l’enregistrement et l’ouverture externe utilisent l’original';

  @override
  String get mail => 'Messagerie';

  @override
  String get myEmails => 'Mes e-mails';

  @override
  String get draftsAndSending => 'Brouillons et envois';

  @override
  String get emailAccounts => 'Comptes de messagerie';

  @override
  String get addEmailAccount => 'Ajouter un compte de messagerie';

  @override
  String get modelsAndServices => 'Modèles et services';

  @override
  String get defaultModel => 'Modèle par défaut';

  @override
  String get visionAssistant => 'Assistant visuel';

  @override
  String get addModel => 'Ajouter un modèle';

  @override
  String get automaticCurrentModelPreferred =>
      'Automatique · priorité au modèle actuel';

  @override
  String fixedAssistant(String p0) {
    return 'Assistant fixe · $p0';
  }

  @override
  String get configurationUnavailable => 'Configuration indisponible';

  @override
  String get chooseAutomatically => 'Choisir automatiquement';

  @override
  String get searchAndVoice => 'Recherche et voix';

  @override
  String get webServicesAndSpeechRecognition =>
      'Services web et reconnaissance vocale';

  @override
  String get preferences => 'Préférences';

  @override
  String get contextOrganization => 'Organisation du contexte';

  @override
  String get fastOrganizationResponseSettingsUnchanged =>
      'Organisation rapide · paramètres de réponse conservés';

  @override
  String get followCurrentThinkingMode => 'Suivre le mode de réflexion actuel';

  @override
  String get fastOrganizationNonThinkingModeOnSupported =>
      'Organisation rapide (sans réflexion sur les API compatibles)';

  @override
  String get appearance => 'Apparence';

  @override
  String get systemDefault => 'Selon le système';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get backgroundSync => 'Synchronisation en arrière-plan';

  @override
  String get off => 'Désactivé';

  @override
  String get hourly => 'Toutes les heures';

  @override
  String get onceADay => 'Une fois par jour';

  @override
  String everyMinutes(String p0) {
    return 'Toutes les $p0 minutes';
  }

  @override
  String get everyMinutes242 => 'Toutes les 30 minutes';

  @override
  String get clearCacheAndChats => 'Effacer le cache et les discussions';

  @override
  String get clearLocalCache => 'Effacer le cache local ?';

  @override
  String get downloadedAttachmentsPagePreviewsAllChatsAnd =>
      'Les pièces jointes téléchargées, aperçus, discussions et résumés seront effacés. Les réglages de messagerie et de modèles et les pièces jointes des brouillons sont conservés.';

  @override
  String versionAndSendConfirmation(String p0) {
    return 'MailPilot $p0\nChaque e-mail est envoyé uniquement après votre confirmation.';
  }

  @override
  String get custom => 'Personnalisé';

  @override
  String get appPassword => 'Mot de passe d’application';

  @override
  String get alibabaBusiness => 'Alibaba Entreprise';

  @override
  String get passwordSecurityPassword =>
      'Mot de passe / mot de passe de sécurité';

  @override
  String get alibabaPersonal => 'Alibaba Personnel';

  @override
  String get emailPassword => 'Mot de passe de messagerie';

  @override
  String get passwordAppPassword => 'Mot de passe / mot de passe d’application';

  @override
  String get leaveBlankToKeepSavedCredentials =>
      'Laissez vide pour conserver les identifiants.';

  @override
  String get theAdministratorMustAllowThirdPartyClients =>
      'L’administrateur doit autoriser les clients tiers et IMAP/SMTP. Si les mots de passe de sécurité sont activés, utilisez celui du client tiers.';

  @override
  String get enterTheFullEmailAddressAndPassword =>
      'Saisissez l’adresse complète et le mot de passe, et autorisez l’accès des clients de messagerie.';

  @override
  String get enableImapSmtpInYourEmailSettings =>
      'Activez IMAP/SMTP dans les paramètres puis obtenez un mot de passe d’application.';

  @override
  String get useTheEmailPasswordOrAppPassword =>
      'Utilisez le mot de passe de messagerie ou d’application requis par le fournisseur.';

  @override
  String get hideCredentials => 'Masquer les identifiants';

  @override
  String get showCredentials => 'Afficher les identifiants';

  @override
  String get connectEmail => 'Connecter la messagerie';

  @override
  String get emailSettings => 'Paramètres de messagerie';

  @override
  String mail263(String p0) {
    return 'Messagerie $p0';
  }

  @override
  String mail264(String p0) {
    return 'Messagerie $p0';
  }

  @override
  String get emailAddress => 'Adresse e-mail';

  @override
  String get senderNameOptional => 'Nom de l’expéditeur (facultatif)';

  @override
  String get emailSetupGuide => 'Guide de configuration de la messagerie';

  @override
  String get connectionDetailsAndInstructions =>
      'Paramètres et instructions de connexion';

  @override
  String officialGuide(String p0) {
    return '$p0 · guide officiel';
  }

  @override
  String get serverAndAdvancedSettings => 'Serveur et paramètres avancés';

  @override
  String get accountLabel => 'Libellé du compte';

  @override
  String get loginUsername => 'Nom d’utilisateur';

  @override
  String get leaveBlankToUseTheFullEmail =>
      'Laissez vide pour utiliser l’adresse complète';

  @override
  String get imapHost => 'Hôte IMAP';

  @override
  String get imapPort => 'Port IMAP';

  @override
  String get incomingEncryption => 'Chiffrement entrant';

  @override
  String get smtpHost => 'Hôte SMTP';

  @override
  String get smtpPort => 'Port SMTP';

  @override
  String get outgoingEncryption => 'Chiffrement sortant';

  @override
  String get testConnection => 'Tester la connexion';

  @override
  String get saveAccount => 'Enregistrer le compte';

  @override
  String get deleteThisAccount => 'Supprimer ce compte ?';

  @override
  String get localEmailsDraftsAndAnalysisForThis =>
      'Les e-mails, brouillons et analyses locaux de ce compte seront supprimés. Les e-mails du serveur sont conservés.';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get modelOptions => 'Options du modèle';

  @override
  String get closeModelOptions => 'Fermer les options du modèle';

  @override
  String get defaultTextModel => 'Modèle de texte par défaut';

  @override
  String get forEverydayChatAndEmailDrafting =>
      'Pour discuter et rédiger des e-mails';

  @override
  String get useAsFixedVisionAssistant =>
      'Utiliser comme assistant visuel fixe';

  @override
  String get forReadingImagesAndPdfPages => 'Pour lire les images et pages PDF';

  @override
  String get connectionDiagnosticsOptional =>
      'Diagnostic de connexion (facultatif)';

  @override
  String get sendTextStreamingToolAndImageRequests =>
      'Envoyer des requêtes de texte, flux, outils et images';

  @override
  String get deleteModel => 'Supprimer le modèle';

  @override
  String get deleteLocalConfigurationAndKeyAfterConfirmation =>
      'Supprimer la configuration et la clé locales après confirmation';

  @override
  String get deleteThisModel => 'Supprimer ce modèle ?';

  @override
  String get theLocalConfigurationAndKeyWillBe =>
      'La configuration et la clé locales seront supprimées.';

  @override
  String get setAsFixedVisionAssistant => 'Défini comme assistant visuel fixe';

  @override
  String get setAsDefaultTextModel => 'Défini comme modèle de texte par défaut';

  @override
  String get savedLeaveBlankToRetain =>
      'Enregistré · laissez vide pour conserver';

  @override
  String get hideKey => 'Masquer la clé';

  @override
  String get showKey => 'Afficher la clé';

  @override
  String get providerDefault => 'Valeur par défaut du fournisseur';

  @override
  String get enableThinking => 'Activer la réflexion';

  @override
  String get disableThinking => 'Désactiver la réflexion';

  @override
  String get letTheModelDecide => 'Laisser le modèle décider';

  @override
  String get modelSettings => 'Paramètres du modèle';

  @override
  String get connectionConfiguration => 'Configuration de connexion';

  @override
  String get modelProvider => 'Fournisseur du modèle';

  @override
  String get autoDetect => 'Détection automatique';

  @override
  String autoDetect310(String p0) {
    return 'Détection automatique · $p0';
  }

  @override
  String get configurationName => 'Nom de la configuration';

  @override
  String get apiUrl => 'URL de l’API';

  @override
  String get modelName => 'Nom du modèle';

  @override
  String get selectABundledModel => 'Sélectionner un modèle inclus';

  @override
  String get youCanAlsoEnterTheModelName =>
      'Vous pouvez aussi saisir directement le nom du modèle';

  @override
  String get bundledModels => 'Modèles inclus';

  @override
  String get advancedParameters => 'Paramètres avancés';

  @override
  String get thinkingModeEffortAndOutputLength =>
      'Mode de réflexion, effort et longueur de sortie';

  @override
  String get thinkingMode => 'Mode de réflexion';

  @override
  String get useProviderDefaultsWithoutExtraThinkingParameters =>
      'Utiliser les valeurs du fournisseur sans paramètres de réflexion supplémentaires';

  @override
  String get askTheModelToThinkDeeply =>
      'Demander au modèle de réfléchir en profondeur';

  @override
  String get askTheModelToAnswerDirectly =>
      'Demander au modèle de répondre directement';

  @override
  String get letTheModelDecideWhetherThinkingIs =>
      'Laisser le modèle décider si une réflexion est nécessaire';

  @override
  String get thinkingEffort => 'Effort de réflexion';

  @override
  String get higherEffortUsuallyTakesLongerAndUses =>
      'Un effort plus élevé prend généralement plus de temps et de tokens. Les niveaux dépendent du modèle.';

  @override
  String get thinkingBudgetTokens => 'Budget de réflexion (tokens)';

  @override
  String get blankOrUsesProviderDefaultsChooseEither =>
      'Vide ou 0 utilise les valeurs du fournisseur. Choisissez un budget ou un niveau d’effort.';

  @override
  String get contextSettings => 'Paramètres du contexte';

  @override
  String get followModelSpecification => 'Selon le modèle';

  @override
  String get officialApisUseVerifiedContextLimitsFor =>
      'Les API officielles utilisent les limites de contexte vérifiées du modèle';

  @override
  String get setALocalBudgetWithinTheProvider =>
      'Définir un budget local respectant la limite du fournisseur';

  @override
  String currentContextTokens(String p0, String p1) {
    return 'Contexte actuel : $p0 tokens. $p1';
  }

  @override
  String get planApiLimitsAreUnverifiedCurrentSettings =>
      'Les limites de l’API du forfait ne sont pas vérifiées. Les réglages actuels sont conservés sans appliquer les limites de l’API standard.';

  @override
  String get thisApiOrModelIsNotIn =>
      'Cette API ou ce modèle n’est pas au catalogue. Vous pouvez définir un budget personnalisé.';

  @override
  String currentContextTokensOfficialMaximumInputTokens(
    String p0,
    String p1,
    String p2,
    String p3,
  ) {
    return 'Contexte actuel : $p0 tokens\nEntrée maximale officielle : $p1 tokens · $p2\nCatalogue vérifié le $p3. Un espace est réservé pour la sortie.';
  }

  @override
  String get nonThinking => 'Sans réflexion';

  @override
  String get thinkingDefault => 'Réflexion / par défaut';

  @override
  String get contextIsOrganizedAtOfTheEffective =>
      'Le contexte est organisé à 95 % du budget effectif, avec un objectif de 60 %. Les originaux sont conservés.';

  @override
  String get maximumOutputLength => 'Longueur maximale de sortie';

  @override
  String get useModelMaximum => 'Utiliser le maximum du modèle';

  @override
  String get useTheVerifiedMaximumOutputForThe =>
      'Utiliser la sortie maximale vérifiée du modèle réel';

  @override
  String get keepYourCustomOutputLength => 'Conserver votre longueur de sortie';

  @override
  String get theMaximumOutputForThisApiIs =>
      'La sortie maximale de cette API n’est pas vérifiée. 4096 tokens sont utilisés ; vous pouvez personnaliser la valeur.';

  @override
  String modelMaximumOutputTokensRequestsAdjustTo(String p0) {
    return 'Sortie maximale du modèle : $p0 tokens. Les requêtes s’adaptent au contexte restant ; le modèle peut terminer plus tôt.';
  }

  @override
  String get contextLength => 'Longueur du contexte';

  @override
  String get customOutputLength => 'Longueur de sortie personnalisée';

  @override
  String get lengthsAreInTokensSomeModelsCount =>
      'Les longueurs sont en tokens. Certains modèles comptent la réflexion dans la sortie.';

  @override
  String get outputLengthParameter => 'Paramètre de longueur de sortie';

  @override
  String get standardParameter => 'Paramètre standard';

  @override
  String get completionLengthParameter => 'Paramètre de longueur de complétion';

  @override
  String get chooseAccordingToTheProviderSApi =>
      'Choisissez selon l’API du fournisseur. Cela ne modifie pas la longueur saisie.';

  @override
  String get notTested => 'Non testé';

  @override
  String get processing => 'Traitement…';

  @override
  String get saveModel => 'Enregistrer le modèle';

  @override
  String emailCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 e-mails',
      one: '1 e-mail',
    );
    return '$_temp0';
  }

  @override
  String expandEmailCount(int p0) {
    return 'Afficher les $p0';
  }

  @override
  String get previousEmailPage => 'Page d’e-mails précédente';

  @override
  String get nextEmailPage => 'Page d’e-mails suivante';

  @override
  String get collapse => 'Réduire';

  @override
  String get qqMail => 'QQ Mail';

  @override
  String get enableMailServices => 'Activer les services de messagerie';

  @override
  String get signInToQqMailInA =>
      'Connectez-vous à QQ Mail dans un navigateur de bureau. Dans Paramètres → Compte et sécurité → Sécurité, activez POP3/IMAP/SMTP.';

  @override
  String get generateAnAppPassword => 'Générer un mot de passe d’application';

  @override
  String get completeIdentityVerificationOnTheOfficialPage =>
      'Vérifiez votre identité sur la page officielle, générez un mot de passe d’application de 16 caractères et saisissez-le ici.';

  @override
  String get returnToAccountForm => 'Revenir au formulaire du compte';

  @override
  String get enterTheFullEmailAddressServersAre =>
      'Saisissez l’adresse complète. Les serveurs sont préremplis. Testez la connexion avant d’enregistrer.';

  @override
  String get getAndManageAppPasswords =>
      'Obtenir et gérer les mots de passe d’application';

  @override
  String get mail368 => '163 Mail';

  @override
  String get enableImapSmtp => 'Activer IMAP/SMTP';

  @override
  String get signInToWebmailFindPopSmtp =>
      'Connectez-vous au webmail 163. Trouvez POP3/SMTP/IMAP dans les paramètres et activez IMAP/SMTP.';

  @override
  String get getAClientAppPassword => 'Obtenir un mot de passe client';

  @override
  String get completeTheVerificationAsInstructedAndEnter =>
      'Effectuez la vérification indiquée et saisissez ici le mot de passe client généré.';

  @override
  String get checkTheFullEmailAddress => 'Vérifier l’adresse complète';

  @override
  String get useYourFullComAddressIfYou =>
      'Utilisez votre adresse @163.com complète. Si vous ne trouvez pas le réglage, cherchez « 授权码 » ou « IMAP » dans l’aide officielle NetEase.';

  @override
  String get neteaseMailOfficialHelp => 'Aide officielle de NetEase Mail';

  @override
  String get alibabaBusinessMail => 'Messagerie Alibaba Entreprise';

  @override
  String get checkClientPermissions => 'Vérifier les autorisations du client';

  @override
  String get askTheAdministratorToAllowThirdParty =>
      'Demandez à l’administrateur d’autoriser les clients tiers et d’activer IMAP/SMTP. Les nouveaux comptes professionnels peuvent les bloquer par défaut.';

  @override
  String get prepareASecurityPassword => 'Préparer un mot de passe de sécurité';

  @override
  String get inWebmailGoToSettingsAccountAnd =>
      'Dans le webmail, ouvrez Paramètres → Compte et sécurité et générez un mot de passe pour client tiers. Utilisez-le ici après activation.';

  @override
  String get enterTheBusinessEmailAddress => 'Saisir l’adresse professionnelle';

  @override
  String get useTheFullBusinessAddressDefaultServers =>
      'Utilisez l’adresse professionnelle complète. Les serveurs sont préremplis ; modifiez-les dans les paramètres avancés pour Hong Kong ou votre entreprise.';

  @override
  String get allowThirdPartyClients => 'Autoriser les clients tiers';

  @override
  String get generateAThirdPartyClientSecurityPassword =>
      'Générer un mot de passe de sécurité pour client tiers';

  @override
  String get serverAddressesAndPorts => 'Adresses et ports des serveurs';

  @override
  String get alibabaPersonalMail => 'Messagerie Alibaba Personnel';

  @override
  String get checkAccountType => 'Vérifier le type de compte';

  @override
  String get thisPresetIsForFreeAlibabaCloud =>
      'Ce préréglage concerne la messagerie personnelle gratuite Alibaba Cloud. Pour un domaine d’entreprise, choisissez Alibaba Entreprise.';

  @override
  String get prepareLoginDetails => 'Préparer les identifiants';

  @override
  String get enterTheFullEmailAddressAndRequired =>
      'Saisissez l’adresse complète et les identifiants requis. Assurez-vous que l’accès des clients est autorisé.';

  @override
  String get checkServers => 'Vérifier les serveurs';

  @override
  String get useTheOfficialSslServerSettingsBelow =>
      'Utilisez les paramètres SSL officiels ci-dessous. Testez la connexion avant d’enregistrer.';

  @override
  String get personalMailServersAndPorts =>
      'Serveurs et ports de messagerie personnelle';

  @override
  String get customEmailProvider => 'Fournisseur de messagerie personnalisé';

  @override
  String get identifyYourProvider => 'Identifier le fournisseur';

  @override
  String get aCustomDomainDoesNotIdentifyThe =>
      'Un domaine personnalisé ne permet pas d’identifier le fournisseur. Consultez l’administrateur.';

  @override
  String get getConnectionSettings => 'Obtenir les paramètres de connexion';

  @override
  String get prepareImapAndSmtpHostsPortsEncryption =>
      'Préparez les hôtes IMAP et SMTP, ports, chiffrement et mot de passe ou mot de passe d’application.';

  @override
  String get enterAndVerify => 'Saisir et vérifier';

  @override
  String get expandServerAndAdvancedSettingsAndEnter =>
      'Développez Serveur et paramètres avancés puis saisissez les données du fournisseur.';

  @override
  String setupGuide(String p0) {
    return 'Guide de configuration de $p0';
  }

  @override
  String get closeSetupGuide => 'Fermer le guide de configuration';

  @override
  String get defaultServersSsl => 'Serveurs par défaut · SSL';

  @override
  String incomingPortOutgoingPort(String p0, String p1) {
    return 'Entrant  $p0\nPort 993\n\nSortant  $p1\nPort 465';
  }

  @override
  String get officialHelp => 'Aide officielle';

  @override
  String verifiedOfficialPagesOpenInYourBrowser(String p0) {
    return 'Vérifié : $p0 · les pages officielles s’ouvrent dans le navigateur';
  }

  @override
  String get returnToForm => 'Revenir au formulaire';

  @override
  String get mailpilotPreview => 'MailPilot · Aperçu';

  @override
  String get thisLinkIsNotAValidWeb =>
      'Ce lien n’est pas une adresse web valide';

  @override
  String get openWebpage => 'Ouvrir la page web';

  @override
  String get copyLink => 'Copier le lien';

  @override
  String get openInBrowser => 'Ouvrir dans le navigateur';

  @override
  String image(String p0) {
    return '[Image $p0]';
  }

  @override
  String get sizeUnknown => 'Taille inconnue';

  @override
  String get firstPagesByDefaultPageCountPending =>
      '10 premières pages par défaut ; total à déterminer';

  @override
  String get selectPdfPageNumbers => 'Sélectionner les numéros de page PDF';

  @override
  String page(String p0) {
    return 'Page $p0';
  }

  @override
  String get fileName => 'Nom du fichier';

  @override
  String get deselect => 'Désélectionner';

  @override
  String get select420 => 'Sélectionner';

  @override
  String get materialsForThisAnalysis => 'Documents de cette analyse';

  @override
  String materialSummary(String p0, String p1, String p2) {
    return '$p0 pièces jointes · $p1$p2';
  }

  @override
  String withUnknownSize(String p0) {
    return ' · $p0 de taille inconnue';
  }

  @override
  String get closeMaterials => 'Fermer les documents';

  @override
  String upToAttachmentsMbAndImagesOr(String p0) {
    return 'Maximum 10 pièces jointes, 50 MB et 20 images ou pages PDF par tour.\n$p0';
  }

  @override
  String get actualImageCountsInPdfAndOffice =>
      'Le nombre réel d’images dans les fichiers PDF et Office est vérifié à la lecture.';

  @override
  String get selectedFilesAreReadOnlyWhenPreviewing =>
      'Les fichiers sélectionnés ne sont lus qu’à l’aperçu ou lors d’une question.';

  @override
  String get attachmentListAwaitingSync =>
      'Liste des pièces jointes en attente de synchronisation';

  @override
  String get selectAllSupportedAttachments =>
      'Sélectionner toutes les pièces jointes compatibles';

  @override
  String get keepBodyOnly => 'Conserver uniquement le corps';

  @override
  String get deviceFiles => 'Fichiers de l’appareil';

  @override
  String get noMaterialsSelectedAddFilesOrSelect =>
      'Aucun document sélectionné. Ajoutez des fichiers ou sélectionnez des e-mails.';

  @override
  String get materialCheckIncomplete => 'Vérification des documents incomplète';

  @override
  String get retryWithCurrentMaterials =>
      'Réessayer avec les documents actuels';

  @override
  String get analyzedImages => 'Images analysées';

  @override
  String get previousAnalysisIsReusedByDefaultSelect =>
      'L’analyse précédente est réutilisée par défaut. Sélectionnez une nouvelle vérification pour plus de détails ; elle s’applique au prochain message.';

  @override
  String get cancelRecheck => 'Annuler la nouvelle vérification';

  @override
  String get recheckImages => 'Revérifier les images';

  @override
  String get previousVersion => 'Version précédente';

  @override
  String messageVersionCount(String p0, String p1) {
    return 'Version $p0 sur $p1';
  }

  @override
  String get nextVersion => 'Version suivante';

  @override
  String get closeMessageActions => 'Fermer les actions du message';

  @override
  String get copyMessage => 'Copier le message';

  @override
  String get messageCopied => 'Message copié';

  @override
  String close(String p0) {
    return 'Fermer $p0';
  }

  @override
  String get volcengineArk => 'Volcengine · Ark';

  @override
  String get alibabaCloudModelStudio => 'Alibaba Cloud · Model Studio';

  @override
  String get openaiCompatibleApi => 'API compatible OpenAI';

  @override
  String get minimalMinimal => 'Minimal · minimal';

  @override
  String get lowLow => 'Faible · low';

  @override
  String get mediumMedium => 'Moyen · medium';

  @override
  String get highHigh => 'Élevé · high';

  @override
  String get veryHighXhigh => 'Très élevé · xhigh';

  @override
  String get maximumMax => 'Maximum · max';

  @override
  String get chooseImageProcessing => 'Choisir le traitement des images';

  @override
  String get yourQuestionMaterialsAndCompletedAnalysisAre =>
      'Votre question, vos documents et les analyses terminées sont conservés.';

  @override
  String get adjustMaterials => 'Ajuster les documents';

  @override
  String get reduceImagesPagesOrTextAndSubmit =>
      'Réduisez les images, pages ou textes puis renvoyez';

  @override
  String get processThisTurnInBatches => 'Traiter ce tour par lots';

  @override
  String get readUnfinishedImagesInBatchesThenSummarize =>
      'Lire les images restantes par lots puis résumer';

  @override
  String get couldNotReadThisPage => 'Impossible de lire cette page';

  @override
  String get couldNotReadThisPagePleaseRetry =>
      'Impossible de lire cette page. Réessayez.';

  @override
  String get closePagePreview => 'Fermer l’aperçu de la page';

  @override
  String get pageImageUnavailable => 'Image de la page indisponible';

  @override
  String get selectPdfPages => 'Sélectionner les pages PDF';

  @override
  String pagesTotal(String p0) {
    return ' · $p0 pages au total';
  }

  @override
  String pagesSelectedMaximum(String p0) {
    return '$p0 pages sélectionnées / maximum 20';
  }

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get firstPages => '10 premières pages';

  @override
  String get clear => 'Effacer';

  @override
  String get readingPdf => 'Lecture du PDF…';

  @override
  String get couldNotReadPageNumbers =>
      'Impossible de lire les numéros de page';

  @override
  String get retryReading => 'Réessayer la lecture';

  @override
  String get selectUpToPagesPerPdf => 'Sélectionnez jusqu’à 20 pages par PDF';

  @override
  String get deselectThisAttachment => 'Désélectionner cette pièce jointe';

  @override
  String confirmSelectionPages(String p0) {
    return 'Confirmer la sélection · $p0 pages';
  }

  @override
  String get retryPreview => 'Réessayer l’aperçu';

  @override
  String previewPage(String p0) {
    return 'Aperçu de la page $p0';
  }

  @override
  String get loadingPreview => 'Chargement de l’aperçu…';

  @override
  String page480(String p0, String p1) {
    return '$p0, page $p1';
  }

  @override
  String reasoningSegmentHeading(String p0) {
    return 'Réflexion $p0\n';
  }

  @override
  String get searching => 'Recherche en cours';

  @override
  String get searchIncomplete => 'Recherche incomplète';

  @override
  String searchResultCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 résultats trouvés',
      one: '1 résultat trouvé',
    );
    return '$_temp0';
  }

  @override
  String get readingWebpages => 'Lecture des pages web';

  @override
  String readWebpageCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 pages web lues',
      one: '1 page web lue',
    );
    return '$_temp0';
  }

  @override
  String get webpageReadingFinished => 'Lecture des pages terminée';

  @override
  String get readingMaterials => 'Lecture des documents';

  @override
  String get sourceExcerptViewed => 'Extrait de source consulté';

  @override
  String get materialsReused => 'Documents réutilisés';

  @override
  String get searchingEmails => 'Recherche d’e-mails';

  @override
  String get emailsSearched => 'E-mails recherchés';

  @override
  String get processing493 => 'Traitement en cours';

  @override
  String get actionCompleted => 'Action terminée';

  @override
  String get lessThanSecond => 'Moins d’une seconde';

  @override
  String elapsedSeconds(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 secondes',
      one: '1 seconde',
    );
    return '$_temp0';
  }

  @override
  String get thinking497 => 'Réflexion en cours';

  @override
  String get thinkingStopped => 'Réflexion arrêtée';

  @override
  String get thinkingInterrupted => 'Réflexion interrompue';

  @override
  String get process => 'Déroulement';

  @override
  String get thought => 'Réflexion terminée';

  @override
  String get reasoning => 'Raisonnement';

  @override
  String get viewReasoning => 'Voir le raisonnement';

  @override
  String get currentAttempt => 'Tentative actuelle';

  @override
  String get previousAttempt => 'Tentative précédente';

  @override
  String earlierAttempt(String p0) {
    return 'Ancienne tentative $p0';
  }

  @override
  String get viewingAPreviousAttempt => 'Affichage d’une tentative précédente';

  @override
  String get reasoningIsLongTheFirstCharactersHave =>
      'Le raisonnement est long. Les 128000 premiers caractères sont conservés.';

  @override
  String get jumpToEndOfReasoning => 'Aller à la fin du raisonnement';

  @override
  String get uiPreviewSampleDataInstallAndroidTo =>
      'Aperçu · données d’exemple. Installez la version Android pour connecter messagerie et modèles.';

  @override
  String get dismissNotice => 'Fermer l’avis';

  @override
  String get backToHome => 'Retour à l’accueil';

  @override
  String get backToSettings => 'Retour aux paramètres';

  @override
  String get backToConversation => 'Retour à la conversation';

  @override
  String get openMenu => 'Ouvrir le menu';

  @override
  String get noVersionsAvailable => 'Aucune version disponible';

  @override
  String get couldNotLoadVersionsPleaseRetry =>
      'Impossible de charger les versions. Réessayez.';

  @override
  String get cannotEditThisQuestion => 'Impossible de modifier cette question';

  @override
  String get couldNotEditThisQuestionPleaseRetry =>
      'Impossible de modifier cette question. Réessayez.';

  @override
  String get editNotSubmittedPleaseRetry =>
      'La modification n’a pas été envoyée. Réessayez.';

  @override
  String get addAModelFirst => 'Ajoutez d’abord un modèle';

  @override
  String get materialCheckIncompletePleaseRetry =>
      'Vérification des documents incomplète. Réessayez.';

  @override
  String get newConversation => 'Nouvelle conversation';

  @override
  String get whatSOnYourMind => 'De quoi souhaitez-vous parler ?';

  @override
  String get letSMakeSenseOfYourEmails => 'Faisons le point sur vos e-mails.';

  @override
  String get configureAModelToChatYouCan =>
      'Configurez un modèle pour discuter. Vous pourrez ajouter la messagerie plus tard.';

  @override
  String get askAQuestionOrSelectEmailsAs =>
      'Posez une question ou sélectionnez des e-mails comme contexte.';

  @override
  String get helpMeOrganizeMyThoughts => 'Aidez-moi à organiser mes idées';

  @override
  String get helpMeWriteSomething => 'Aidez-moi à rédiger un texte';

  @override
  String get summarizeSelectedEmails => 'Résumer les e-mails sélectionnés';

  @override
  String get helpMeDraftAReply => 'Aidez-moi à rédiger une réponse';

  @override
  String get retryWebSearch => 'Réessayer la recherche web';

  @override
  String get answerWithoutSearch => 'Répondre sans recherche';

  @override
  String get continueSearching => 'Poursuivre la recherche';

  @override
  String get responseIncomplete => 'Réponse incomplète';

  @override
  String get continueOrganizing => 'Poursuivre l’organisation';

  @override
  String get retryThisTurn => 'Réessayer ce tour';

  @override
  String get viewBudget => 'Voir le budget';

  @override
  String get retryWithCompatibleFormat => 'Réessayer avec un format compatible';

  @override
  String get chooseProcessingMethod => 'Choisir le mode de traitement';

  @override
  String get adjustMaterialsAndRetry => 'Ajuster les documents et réessayer';

  @override
  String get restoreDefaultThinkingAndRetry =>
      'Rétablir la réflexion par défaut et réessayer';

  @override
  String get chooseVisionAssistant => 'Choisir l’assistant visuel';

  @override
  String get editConfiguration => 'Modifier la configuration';

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
  String get copyResponse => 'Copier la réponse';

  @override
  String get originalMarkdownCopied => 'Markdown d’origine copié';

  @override
  String get responseStopped => 'Réponse arrêtée';

  @override
  String get stoppedThePartialResponseReceivedIsShown =>
      'Arrêté. La réponse partielle reçue est affichée ci-dessus.';

  @override
  String get reviewDraftAndSend => 'Vérifier le brouillon et envoyer';

  @override
  String get writeAsEmail => 'Rédiger en e-mail';

  @override
  String get connectingToModel => 'Connexion au modèle…';

  @override
  String get viewingAnOlderVersion => 'Affichage d’une ancienne version';

  @override
  String get backToLatest => 'Revenir à la dernière';

  @override
  String get textModel => 'Modèle de texte';

  @override
  String tapToCancelSync(String p0) {
    return '$p0 · appuyez pour annuler la synchronisation';
  }

  @override
  String get syncLatestEmailsInEachFolder =>
      'Synchroniser les 50 derniers e-mails de chaque dossier';

  @override
  String get searchEmails => 'Rechercher des e-mails';

  @override
  String get emailActions => 'Actions de messagerie';

  @override
  String get syncEmailsPerFolder => 'Synchroniser les e-mails (50 par dossier)';

  @override
  String get showAll => 'Tout afficher';

  @override
  String get showUnread => 'Afficher les non lus';

  @override
  String get subjectOrSender => 'Objet ou expéditeur';

  @override
  String get runSearch => 'Lancer la recherche';

  @override
  String get connectAnEmailAccountFirst =>
      'Connectez d’abord un compte de messagerie';

  @override
  String get supportsQqAndCustomEmailProviders =>
      'Compatible avec QQ, 163 et les fournisseurs personnalisés.';

  @override
  String get noLocalEmailsYet => 'Aucun e-mail local pour le moment';

  @override
  String get pullDownToSyncRecentEmailsStartup =>
      'Tirez vers le bas pour synchroniser. Le démarrage ne lance pas de synchronisation automatique.';

  @override
  String analyzeSelectedEmails(String p0) {
    return 'Analyser $p0 e-mails sélectionnés';
  }

  @override
  String get emailDetails => 'Détails de l’e-mail';

  @override
  String get replyAndForward => 'Répondre et transférer';

  @override
  String get reply => 'Répondre';

  @override
  String get replyAll => 'Répondre à tous';

  @override
  String get forward => 'Transférer';

  @override
  String get recipientDetails => 'Informations sur les destinataires';

  @override
  String toCc(String p0, String p1) {
    return 'À : $p0\nCc : $p1';
  }

  @override
  String get bodyAwaitingBackgroundSyncYouCanKeep =>
      'Le corps attend la synchronisation en arrière-plan. Vous pouvez consulter d’autres e-mails.';

  @override
  String attachments(String p0) {
    return 'Pièces jointes · $p0';
  }

  @override
  String get tapAnAttachmentToPreviewSelectIt =>
      'Appuyez pour prévisualiser ; sélectionnez pour l’analyse IA';

  @override
  String get askAssistant => 'Demander à l’assistant';

  @override
  String get noDraftsYet => 'Aucun brouillon pour le moment';

  @override
  String get writeYourOwnOrAskTheAssistant =>
      'Rédigez vous-même ou demandez un brouillon à l’assistant.';

  @override
  String get configurationSaved => 'Configuration enregistrée';

  @override
  String get closeConfiguration => 'Fermer la configuration';

  @override
  String get actionFailed => 'Échec de l’action';

  @override
  String get backToConfiguration => 'Retour à la configuration';

  @override
  String get volcengineWebSearch => 'Recherche web Volcengine';

  @override
  String get bocha => 'Bocha';

  @override
  String get systemPreferredCloudOptional =>
      'Système prioritaire, cloud facultatif';

  @override
  String get qwenCloudTranscription => 'Transcription cloud Qwen';

  @override
  String get automaticSystemRecognitionFollowsDeviceLanguage =>
      'Automatique (la reconnaissance système suit la langue de l’appareil)';

  @override
  String get chinese => 'Chinois';

  @override
  String get searchProvider => 'Fournisseur de recherche';

  @override
  String get recognitionMode => 'Mode de reconnaissance';

  @override
  String get speechLanguage => 'Langue vocale';

  @override
  String get automatic => 'Automatique';

  @override
  String get systemRecognitionNeedsNoApiKeyIf =>
      'La reconnaissance système ne nécessite pas de clé API. Si votre appareil n’a pas ce service, utilisez Qwen ASR ci-dessous.';

  @override
  String get usedOnlyWhenSmartSearchIsEnabled =>
      'Utilisé uniquement avec la recherche intelligente activée et une question. Le service reçoit les mots-clés extraits, pas les e-mails, pièces jointes ou historiques.';

  @override
  String get qwenAsrBaseUrl => 'URL de base de Qwen ASR';

  @override
  String get fullSearchApiUrl => 'URL complète de l’API de recherche';

  @override
  String get leaveBlankToRetainTheSavedKey =>
      'Laissez vide pour conserver la clé enregistrée';

  @override
  String get showOrHideKey => 'Afficher ou masquer la clé';

  @override
  String get asrModel => 'Modèle ASR';

  @override
  String get forExampleQwenAsrFlash => 'Par exemple, qwen3-asr-flash';

  @override
  String get transcriptionFillsTheInputFieldOnlyReview =>
      'La transcription remplit uniquement le champ ; vérifiez avant d’envoyer. Le mode cloud nécessite un nouvel enregistrement de 60 secondes maximum.';

  @override
  String get streamingUiStateIsOutOfSync =>
      'L’état de l’interface est désynchronisé. Rouvrez la conversation.';

  @override
  String get streamNotReceivedCompletelyReopenThisConversation =>
      'Le flux n’a pas été reçu complètement. Rouvrez la conversation.';

  @override
  String get appLanguage => 'Langue';

  @override
  String get languageTitle => 'Choisir la langue';

  @override
  String get languageDescription =>
      'Changez la langue de l’interface. Les e-mails et conversations conservent leur contenu d’origine.';
}
