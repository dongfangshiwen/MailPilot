// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get switchAccount => 'Cambiar cuenta';

  @override
  String get closeAccountPicker => 'Cerrar selector de cuentas';

  @override
  String switchAccountCurrent(String p0) {
    return 'Cambiar cuenta, actual: $p0';
  }

  @override
  String get openWithAnotherApp => 'Abrir con otra aplicación';

  @override
  String get openInAnotherApp => 'Abrir en otra aplicación';

  @override
  String get saveToDevice => 'Guardar en el dispositivo';

  @override
  String get couldNotStartRecording => 'No se pudo iniciar la grabación';

  @override
  String get addImage => 'Añadir imagen';

  @override
  String get addFile => 'Añadir archivo';

  @override
  String get selectEmails => 'Seleccionar correos';

  @override
  String get manageImportedMaterials => 'Gestionar materiales importados';

  @override
  String get deepThinking => 'Razonamiento profundo';

  @override
  String get editInput => 'Editar entrada';

  @override
  String get cancelEdit => 'Cancelar edición';

  @override
  String selectedMaterialsCount(int p0, int p1) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 correos',
      one: '1 correo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      p1,
      locale: localeName,
      other: '$p1 adjuntos',
      one: '1 adjunto',
    );
    return '$_temp0 · $_temp1 seleccionados';
  }

  @override
  String get clearSelection => 'Borrar selección';

  @override
  String get listeningUpToSeconds => 'Escuchando · hasta 60 segundos';

  @override
  String get transcribing => 'Transcribiendo…';

  @override
  String get startingMicrophone => 'Iniciando micrófono…';

  @override
  String get recordAgainInCloudMode => 'Grabar de nuevo en la nube';

  @override
  String get cancelVoiceInput => 'Cancelar entrada de voz';

  @override
  String get askAboutSelectedMaterials =>
      'Pregunta sobre los materiales seleccionados…';

  @override
  String get messageOrUseVoiceInput => 'Escribe o usa la voz';

  @override
  String get smartSearch => 'Búsqueda inteligente';

  @override
  String get thinking => 'Razonamiento';

  @override
  String get search => 'Buscar';

  @override
  String get addAttachment => 'Añadir adjunto';

  @override
  String get stopResponse => 'Detener respuesta';

  @override
  String get stopRecording => 'Detener grabación';

  @override
  String get sendQuestion => 'Enviar pregunta';

  @override
  String get voiceInput => 'Entrada de voz';

  @override
  String get draftDeleted => 'Borrador eliminado';

  @override
  String get pleaseViewTheLatestVersion => 'Consulta la versión más reciente';

  @override
  String get from => 'De';

  @override
  String get to => 'Para';

  @override
  String get cc => 'Cc';

  @override
  String get bcc => 'Cco';

  @override
  String get notEntered => 'Sin completar';

  @override
  String get noSubject => '(Sin asunto)';

  @override
  String get afterReviewingConfirmSendingOrTapThe =>
      'Revisa el contenido y confirma el envío o pulsa el botón inferior.';

  @override
  String get confirmSend => 'Confirmar envío';

  @override
  String get addRecipient => 'Añadir destinatario';

  @override
  String get viewLatestVersion => 'Ver última versión';

  @override
  String get reviewAndEdit => 'Revisar y editar';

  @override
  String get editEmail => 'Editar correo';

  @override
  String get jumpToLatestMessage => 'Ir al último mensaje';

  @override
  String get inbox => 'Bandeja de entrada';

  @override
  String get sent => 'Enviados';

  @override
  String get drafts => 'Borradores';

  @override
  String get deleted => 'Eliminados';

  @override
  String get spam => 'Spam';

  @override
  String get archive => 'Archivo';

  @override
  String get mailFolders => 'Carpetas de correo';

  @override
  String get refreshFolders => 'Actualizar carpetas';

  @override
  String couldNotRefreshFoldersLocalListRetained(String p0) {
    return 'No se pudieron actualizar las carpetas. Se conserva la lista local. $p0';
  }

  @override
  String get unreadOnly => 'Solo no leídos';

  @override
  String get deleteThisDraft => '¿Eliminar este borrador?';

  @override
  String get onlyTheLocalDraftIsDeletedChats =>
      'Solo se elimina el borrador local. Se conservan los chats y los correos del servidor.';

  @override
  String get delete => 'Eliminar';

  @override
  String get draftActions => 'Acciones del borrador';

  @override
  String get rewrite => 'Reescribir';

  @override
  String get deleteDraft => 'Eliminar borrador';

  @override
  String get recipientEmail => 'Correo del destinatario';

  @override
  String get separateMultipleAddressesWithCommas =>
      'Separa las direcciones con comas';

  @override
  String get afterSavingReviewTheNewConfirmationCard =>
      'Tras guardar, revisa la nueva tarjeta de confirmación antes de enviar.';

  @override
  String get saveRecipients => 'Guardar destinatarios';

  @override
  String get draftAnswerPrompt =>
      'Redacta un correo formal basado en esta respuesta de la conversación:';

  @override
  String get draftAnswerPromptSuffix =>
      'Para revisarlo y confirmar antes de enviarlo.';

  @override
  String get turnThisAnswerIntoAnEmail =>
      'Convertir esta respuesta en un correo';

  @override
  String get viewOriginalOfOlderVersion =>
      'Ver original de la versión anterior';

  @override
  String get messageActions => 'Acciones del mensaje';

  @override
  String get needsVerification => 'Por verificar';

  @override
  String get sending => 'Enviando';

  @override
  String get sendFailed => 'Error de envío';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String attachmentCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 adjuntos',
      one: '1 adjunto',
    );
    return '$_temp0';
  }

  @override
  String select(String p0) {
    return 'Seleccionar $p0';
  }

  @override
  String get emailAndModelConnectionsRequireAndroidUse =>
      'Las conexiones de correo y modelos requieren Android. Usa aquí la vista previa.';

  @override
  String get notConnectedToTheAndroidMailService =>
      'Sin conexión al servicio de correo de Android. Cierra por completo y abre de nuevo el APK más reciente. En navegadores y Widget Preview, usa la entrada de vista previa.';

  @override
  String get actionIncomplete => 'Acción incompleta';

  @override
  String get thisFeatureIsUnavailableInTheCurrent =>
      'Esta función no está disponible en este entorno';

  @override
  String get pin => 'Fijar';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get previousDays => 'Últimos 7 días';

  @override
  String get previousDays86 => 'Últimos 30 días';

  @override
  String olderConversationDate(String p0, String p1, String p2) {
    return '$p2/$p1/$p0';
  }

  @override
  String get loadingConversations => 'Cargando conversaciones';

  @override
  String get noMatchingConversations => 'No se encontraron conversaciones';

  @override
  String get yourConversationsWillAppearHere =>
      'Tus conversaciones aparecerán aquí';

  @override
  String get tryShorterKeywordsOrClearTheSearch =>
      'Prueba palabras más cortas o borra la búsqueda.';

  @override
  String get startAChatAndComeBackAnytime =>
      'Empieza un chat y continúa cuando quieras.';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get startAConversation => 'Iniciar conversación';

  @override
  String get couldNotLoadConversationsTapToRetry =>
      'No se pudieron cargar las conversaciones. Toca para reintentar.';

  @override
  String get renameConversation => 'Renombrar conversación';

  @override
  String get enterConversationName => 'Nombre de la conversación';

  @override
  String get save => 'Guardar';

  @override
  String deleteConversationCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '¿Eliminar $p0 conversaciones?',
      one: '¿Eliminar 1 conversación?',
    );
    return '$_temp0';
  }

  @override
  String get chatsSummariesAndAnalysisCachesForThese =>
      'Se eliminarán los chats, resúmenes y cachés de análisis de estas conversaciones. Se conservan los correos y borradores.';

  @override
  String get rename => 'Renombrar';

  @override
  String get unpin => 'Desfijar';

  @override
  String get selectMultiple => 'Selección múltiple';

  @override
  String selectedConversationCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 conversaciones seleccionadas',
      one: '1 conversación seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get exitSelection => 'Salir de selección';

  @override
  String get closeSidebar => 'Cerrar barra lateral';

  @override
  String get searchConversations => 'Buscar conversaciones…';

  @override
  String get conversationSummary => 'Resumen de conversación';

  @override
  String get loading => 'Cargando…';

  @override
  String get loadMore => 'Cargar más';

  @override
  String get selectConversations => 'Seleccionar conversaciones';

  @override
  String get settings => 'Ajustes';

  @override
  String get thisConversationSSummary => 'Resumen de esta conversación';

  @override
  String summarizedMessageCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 mensajes anteriores resumidos',
      one: '1 mensaje anterior resumido',
    );
    return '$_temp0';
  }

  @override
  String get closeSummary => 'Cerrar resumen';

  @override
  String get originalMessagesAreRetainedYouCanAdd =>
      'Se conservan los mensajes originales. Puedes añadir información o correcciones.';

  @override
  String get noSummaryForThisConversationYet =>
      'Esta conversación aún no tiene resumen.';

  @override
  String get conversationChangedPleaseReopenTheSummary =>
      'La conversación cambió. Abre de nuevo el resumen.';

  @override
  String get draftingReadOnlyPreview =>
      'Redactando · vista previa de solo lectura';

  @override
  String get incompleteCannotSend => 'Incompleto · no se puede enviar';

  @override
  String get draftingEmail => 'Redacción de correo';

  @override
  String get generatingResponse => 'Generando respuesta';

  @override
  String get readingImages => 'Leyendo imágenes';

  @override
  String get preparingMaterials => 'Preparando materiales';

  @override
  String get generatingContent => 'Generando contenido';

  @override
  String get parsingModelAction => 'Analizando acción del modelo';

  @override
  String get organizingExistingResults => 'Organizando resultados existentes';

  @override
  String get organizingContext => 'Organizando contexto';

  @override
  String get webSearch => 'Búsqueda web';

  @override
  String get currentRequest => 'Solicitud actual';

  @override
  String get requestId => 'ID de solicitud';

  @override
  String get serverId => 'ID del servidor';

  @override
  String get httpStatus => 'Estado HTTP';

  @override
  String get finishReason => 'Motivo de finalización';

  @override
  String get exceptionType => 'Tipo de excepción';

  @override
  String get validationResult => 'Resultado de validación';

  @override
  String get requestBudgetAndDiagnostics =>
      'Presupuesto y diagnóstico de la solicitud';

  @override
  String get connectionDiagnostics => 'Diagnóstico de conexión';

  @override
  String get requestRecordsForThisTurn =>
      'Registros de solicitudes de este turno';

  @override
  String get closeDiagnostics => 'Cerrar diagnóstico';

  @override
  String get processingStage => 'Etapa de procesamiento';

  @override
  String get model => 'Modelo';

  @override
  String get apiHost => 'Host de la API';

  @override
  String get imageProcessing => 'Procesamiento de imágenes';

  @override
  String get fullTextAndImageResponse =>
      'Respuesta completa con texto e imágenes';

  @override
  String get visionAssistantReading => 'Lectura con asistente visual';

  @override
  String get batchProcessingSelectedForThisTurn =>
      'Procesamiento por lotes elegido para este turno';

  @override
  String get reusingPreviousAnalysis => 'Reutilizando análisis anterior';

  @override
  String get requestsWithImages => 'Solicitudes con imágenes';

  @override
  String requestCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 solicitudes',
      one: '1 solicitud',
    );
    return '$_temp0';
  }

  @override
  String get totalImagesUploaded => 'Total de imágenes subidas';

  @override
  String imageCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 imágenes',
      one: '1 imagen',
    );
    return '$_temp0';
  }

  @override
  String get reusedImages => 'Imágenes reutilizadas';

  @override
  String get batchingReason => 'Motivo de los lotes';

  @override
  String get estimatedInput => 'Entrada estimada';

  @override
  String get availableInputBudget => 'Presupuesto de entrada disponible';

  @override
  String get configuredContext => 'Contexto configurado';

  @override
  String get outputReserve => 'Reserva de salida';

  @override
  String get thinkingReserve => 'Reserva de razonamiento';

  @override
  String get suggestedSummaryLength => 'Longitud sugerida del resumen';

  @override
  String get summaryBudgetLimit => 'Límite de presupuesto del resumen';

  @override
  String get currentSummaryEstimate => 'Estimación del resumen actual';

  @override
  String get localEstimatesMayDifferFromProviderMetering =>
      'Las estimaciones locales pueden diferir de las del proveedor. La organización se inicia al 95% y busca llegar al 60%.';

  @override
  String get timeToFirstChunk => 'Tiempo al primer fragmento';

  @override
  String get lastChunkReceived => 'Último fragmento recibido';

  @override
  String get requestDuration => 'Duración de la solicitud';

  @override
  String get technicalDetails => 'Detalles técnicos';

  @override
  String get requestIdsAndExceptionInformation =>
      'Identificadores y datos de excepción';

  @override
  String get convertedToEmailBodyReviewBeforeSaving =>
      'Convertido al cuerpo del correo. Revisa antes de guardar.';

  @override
  String get conversionFailedOriginalTextRetained =>
      'Falló la conversión. Se conserva el texto original.';

  @override
  String get discardUnsavedChanges => '¿Descartar cambios sin guardar?';

  @override
  String get savedDraftsAreRetained => 'Se conservan los borradores guardados.';

  @override
  String get discardChanges => 'Descartar cambios';

  @override
  String get deleteThisLocalRecord => '¿Eliminar este registro local?';

  @override
  String get serverEmailsAreRetained =>
      'Se conservan los correos del servidor.';

  @override
  String get composeEmail => 'Redactar correo';

  @override
  String get back => 'Volver';

  @override
  String get moreEmailActions => 'Más acciones de correo';

  @override
  String get saveChangesAndRewrite => 'Guardar cambios y reescribir';

  @override
  String get convertMarkdownToBodyText =>
      'Convertir Markdown a texto del correo';

  @override
  String get sendingAccount => 'Cuenta de envío';

  @override
  String get subject => 'Asunto';

  @override
  String get body => 'Cuerpo';

  @override
  String get sendAsThePlainTextShownHere =>
      'Enviar como el texto sin formato mostrado';

  @override
  String get ccBcc => 'Cc / Cco';

  @override
  String remove(String p0) {
    return 'Quitar $p0';
  }

  @override
  String get firstCheckTheServerSSentFolder =>
      'Primero revisa los enviados del servidor y si los destinatarios recibieron el correo.';

  @override
  String get verifiedThatSendingSucceeded =>
      '¿Has verificado que se envió correctamente?';

  @override
  String get thisOnlyUpdatesTheLocalRecord =>
      'Esto solo actualiza el registro local.';

  @override
  String get verifiedSentSuccessfully => 'Verificado: enviado';

  @override
  String get confirmedThatNoRecipientsReceivedIt =>
      '¿Has confirmado que nadie lo recibió?';

  @override
  String get restoreTheDraftToReviewAndSend =>
      'Restaura el borrador para revisarlo y enviarlo de nuevo. Si algunos destinatarios ya lo recibieron, modifica primero la lista.';

  @override
  String get restoreDraft => 'Restaurar borrador';

  @override
  String get verifiedNotSent => 'Verificado: no enviado';

  @override
  String get confirmSendingInChat => 'Confirmar envío en el chat';

  @override
  String get confirmBeforeSending => 'Confirmar antes de enviar';

  @override
  String get pleaseReviewTheFollowing => 'Revisa lo siguiente';

  @override
  String get accountDeleted => 'Cuenta eliminada';

  @override
  String get couldNotReadAttachment => 'No se pudo leer el adjunto';

  @override
  String get couldNotReadImagePleaseRetry =>
      'No se pudo leer la imagen. Reinténtalo.';

  @override
  String get couldNotReadPagePleaseRetry =>
      'No se pudo leer la página. Reinténtalo.';

  @override
  String get reload => 'Recargar';

  @override
  String get referencedMaterial => 'Material citado';

  @override
  String get formattedView => 'Vista con formato';

  @override
  String get viewOriginal => 'Ver original';

  @override
  String get theFollowingWasGeneratedByAVision =>
      'Lo siguiente fue generado por un modelo visual. Compáralo con la imagen original si es necesario.';

  @override
  String get previousPage => 'Página anterior';

  @override
  String get nextPage => 'Página siguiente';

  @override
  String get loadingReferencedMaterial => 'Cargando material citado…';

  @override
  String get selectedImageOrPdfPagePinchTo =>
      'Imagen o página PDF seleccionada. Pellizca para ampliar.';

  @override
  String get imageUnavailableRetryOrOpenWithAnother =>
      'Imagen no disponible. Reintenta o abre con otra aplicación.';

  @override
  String get pinchToZoomSavingAndExternalOpening =>
      'Pellizca para ampliar · guardar y abrir externamente usa el adjunto original';

  @override
  String get mail => 'Correo';

  @override
  String get myEmails => 'Mis correos';

  @override
  String get draftsAndSending => 'Borradores y envíos';

  @override
  String get emailAccounts => 'Cuentas de correo';

  @override
  String get addEmailAccount => 'Añadir cuenta de correo';

  @override
  String get modelsAndServices => 'Modelos y servicios';

  @override
  String get defaultModel => 'Modelo predeterminado';

  @override
  String get visionAssistant => 'Asistente visual';

  @override
  String get addModel => 'Añadir modelo';

  @override
  String get automaticCurrentModelPreferred =>
      'Automático · prioridad al modelo actual';

  @override
  String fixedAssistant(String p0) {
    return 'Asistente fijo · $p0';
  }

  @override
  String get configurationUnavailable => 'Configuración no disponible';

  @override
  String get chooseAutomatically => 'Elegir automáticamente';

  @override
  String get searchAndVoice => 'Búsqueda y voz';

  @override
  String get webServicesAndSpeechRecognition =>
      'Servicios web y reconocimiento de voz';

  @override
  String get preferences => 'Preferencias';

  @override
  String get contextOrganization => 'Organización del contexto';

  @override
  String get fastOrganizationResponseSettingsUnchanged =>
      'Organización rápida · ajustes de respuesta sin cambios';

  @override
  String get followCurrentThinkingMode => 'Usar el modo de razonamiento actual';

  @override
  String get fastOrganizationNonThinkingModeOnSupported =>
      'Organización rápida (sin razonamiento en API compatibles)';

  @override
  String get appearance => 'Apariencia';

  @override
  String get systemDefault => 'Según el sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get backgroundSync => 'Sincronización en segundo plano';

  @override
  String get off => 'Desactivado';

  @override
  String get hourly => 'Cada hora';

  @override
  String get onceADay => 'Una vez al día';

  @override
  String everyMinutes(String p0) {
    return 'Cada $p0 minutos';
  }

  @override
  String get everyMinutes242 => 'Cada 30 minutos';

  @override
  String get clearCacheAndChats => 'Borrar caché y chats';

  @override
  String get clearLocalCache => '¿Borrar la caché local?';

  @override
  String get downloadedAttachmentsPagePreviewsAllChatsAnd =>
      'Se borrarán los adjuntos descargados, vistas previas, chats y resúmenes. Se conservan los ajustes de correo y modelos y los adjuntos de borradores.';

  @override
  String versionAndSendConfirmation(String p0) {
    return 'MailPilot $p0\nCada correo se envía solo con tu confirmación.';
  }

  @override
  String get custom => 'Personalizado';

  @override
  String get appPassword => 'Contraseña de aplicación';

  @override
  String get alibabaBusiness => 'Alibaba Empresas';

  @override
  String get passwordSecurityPassword => 'Contraseña / contraseña de seguridad';

  @override
  String get alibabaPersonal => 'Alibaba Personal';

  @override
  String get emailPassword => 'Contraseña del correo';

  @override
  String get passwordAppPassword => 'Contraseña / contraseña de aplicación';

  @override
  String get leaveBlankToKeepSavedCredentials =>
      'Deja en blanco para conservar las credenciales.';

  @override
  String get theAdministratorMustAllowThirdPartyClients =>
      'El administrador debe permitir clientes externos e IMAP/SMTP. Si se usan contraseñas de seguridad, utiliza la del cliente externo.';

  @override
  String get enterTheFullEmailAddressAndPassword =>
      'Introduce la dirección completa y la contraseña, y permite el acceso de clientes.';

  @override
  String get enableImapSmtpInYourEmailSettings =>
      'Activa IMAP/SMTP en los ajustes de correo y obtén una contraseña de aplicación.';

  @override
  String get useTheEmailPasswordOrAppPassword =>
      'Usa la contraseña de correo o de aplicación requerida por tu proveedor.';

  @override
  String get hideCredentials => 'Ocultar credenciales';

  @override
  String get showCredentials => 'Mostrar credenciales';

  @override
  String get connectEmail => 'Conectar correo';

  @override
  String get emailSettings => 'Ajustes de correo';

  @override
  String mail263(String p0) {
    return 'Correo $p0';
  }

  @override
  String mail264(String p0) {
    return 'Correo $p0';
  }

  @override
  String get emailAddress => 'Dirección de correo';

  @override
  String get senderNameOptional => 'Nombre del remitente (opcional)';

  @override
  String get emailSetupGuide => 'Guía de configuración del correo';

  @override
  String get connectionDetailsAndInstructions =>
      'Datos e instrucciones de conexión';

  @override
  String officialGuide(String p0) {
    return '$p0 · guía oficial';
  }

  @override
  String get serverAndAdvancedSettings => 'Servidor y ajustes avanzados';

  @override
  String get accountLabel => 'Etiqueta de la cuenta';

  @override
  String get loginUsername => 'Nombre de usuario';

  @override
  String get leaveBlankToUseTheFullEmail =>
      'Vacío: usar la dirección de correo completa';

  @override
  String get imapHost => 'Host IMAP';

  @override
  String get imapPort => 'Puerto IMAP';

  @override
  String get incomingEncryption => 'Cifrado de entrada';

  @override
  String get smtpHost => 'Host SMTP';

  @override
  String get smtpPort => 'Puerto SMTP';

  @override
  String get outgoingEncryption => 'Cifrado de salida';

  @override
  String get testConnection => 'Probar conexión';

  @override
  String get saveAccount => 'Guardar cuenta';

  @override
  String get deleteThisAccount => '¿Eliminar esta cuenta?';

  @override
  String get localEmailsDraftsAndAnalysisForThis =>
      'Se eliminarán los correos, borradores y análisis locales de esta cuenta. Se conservan los correos del servidor.';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get modelOptions => 'Opciones del modelo';

  @override
  String get closeModelOptions => 'Cerrar opciones del modelo';

  @override
  String get defaultTextModel => 'Modelo de texto predeterminado';

  @override
  String get forEverydayChatAndEmailDrafting =>
      'Para conversar y redactar correos';

  @override
  String get useAsFixedVisionAssistant => 'Usar como asistente visual fijo';

  @override
  String get forReadingImagesAndPdfPages => 'Para leer imágenes y páginas PDF';

  @override
  String get connectionDiagnosticsOptional =>
      'Diagnóstico de conexión (opcional)';

  @override
  String get sendTextStreamingToolAndImageRequests =>
      'Enviar solicitudes de texto, flujo, herramientas e imágenes';

  @override
  String get deleteModel => 'Eliminar modelo';

  @override
  String get deleteLocalConfigurationAndKeyAfterConfirmation =>
      'Eliminar configuración y clave locales tras confirmar';

  @override
  String get deleteThisModel => '¿Eliminar este modelo?';

  @override
  String get theLocalConfigurationAndKeyWillBe =>
      'Se eliminarán la configuración y la clave locales.';

  @override
  String get setAsFixedVisionAssistant =>
      'Establecido como asistente visual fijo';

  @override
  String get setAsDefaultTextModel =>
      'Establecido como modelo de texto predeterminado';

  @override
  String get savedLeaveBlankToRetain => 'Guardado · deja vacío para conservar';

  @override
  String get hideKey => 'Ocultar clave';

  @override
  String get showKey => 'Mostrar clave';

  @override
  String get providerDefault => 'Predeterminado del proveedor';

  @override
  String get enableThinking => 'Activar razonamiento';

  @override
  String get disableThinking => 'Desactivar razonamiento';

  @override
  String get letTheModelDecide => 'Dejar que el modelo decida';

  @override
  String get modelSettings => 'Ajustes del modelo';

  @override
  String get connectionConfiguration => 'Configuración de conexión';

  @override
  String get modelProvider => 'Proveedor del modelo';

  @override
  String get autoDetect => 'Detectar automáticamente';

  @override
  String autoDetect310(String p0) {
    return 'Detección automática · $p0';
  }

  @override
  String get configurationName => 'Nombre de configuración';

  @override
  String get apiUrl => 'URL de la API';

  @override
  String get modelName => 'Nombre del modelo';

  @override
  String get selectABundledModel => 'Seleccionar un modelo incluido';

  @override
  String get youCanAlsoEnterTheModelName =>
      'También puedes escribir el nombre del modelo';

  @override
  String get bundledModels => 'Modelos incluidos';

  @override
  String get advancedParameters => 'Parámetros avanzados';

  @override
  String get thinkingModeEffortAndOutputLength =>
      'Modo de razonamiento, esfuerzo y longitud de salida';

  @override
  String get thinkingMode => 'Modo de razonamiento';

  @override
  String get useProviderDefaultsWithoutExtraThinkingParameters =>
      'Usar los valores del proveedor sin parámetros adicionales de razonamiento';

  @override
  String get askTheModelToThinkDeeply =>
      'Pedir al modelo que razone en profundidad';

  @override
  String get askTheModelToAnswerDirectly =>
      'Pedir al modelo que responda directamente';

  @override
  String get letTheModelDecideWhetherThinkingIs =>
      'Dejar que el modelo decida si necesita razonar';

  @override
  String get thinkingEffort => 'Esfuerzo de razonamiento';

  @override
  String get higherEffortUsuallyTakesLongerAndUses =>
      'Un esfuerzo mayor suele tardar más y usar más tokens. Los niveles dependen del modelo.';

  @override
  String get thinkingBudgetTokens => 'Presupuesto de razonamiento (tokens)';

  @override
  String get blankOrUsesProviderDefaultsChooseEither =>
      'Vacío o 0 usa los valores del proveedor. Elige presupuesto o nivel de esfuerzo.';

  @override
  String get contextSettings => 'Ajustes del contexto';

  @override
  String get followModelSpecification => 'Según el modelo';

  @override
  String get officialApisUseVerifiedContextLimitsFor =>
      'Las API oficiales usan los límites de contexto verificados del modelo';

  @override
  String get setALocalBudgetWithinTheProvider =>
      'Establecer un presupuesto local dentro del límite del proveedor';

  @override
  String currentContextTokens(String p0, String p1) {
    return 'Contexto actual: $p0 tokens. $p1';
  }

  @override
  String get planApiLimitsAreUnverifiedCurrentSettings =>
      'Los límites de la API del plan no están verificados. Se mantienen los ajustes actuales sin aplicar los límites de la API estándar.';

  @override
  String get thisApiOrModelIsNotIn =>
      'Esta API o modelo no está en el catálogo. Puedes fijar un presupuesto personalizado.';

  @override
  String currentContextTokensOfficialMaximumInputTokens(
    String p0,
    String p1,
    String p2,
    String p3,
  ) {
    return 'Contexto actual: $p0 tokens\nEntrada máxima oficial: $p1 tokens · $p2\nCatálogo verificado el $p3. Se reserva espacio para la salida.';
  }

  @override
  String get nonThinking => 'Sin razonamiento';

  @override
  String get thinkingDefault => 'Razonamiento / predeterminado';

  @override
  String get contextIsOrganizedAtOfTheEffective =>
      'El contexto se organiza al 95% del presupuesto efectivo, con objetivo del 60%. Se conservan los registros originales.';

  @override
  String get maximumOutputLength => 'Longitud máxima de salida';

  @override
  String get useModelMaximum => 'Usar máximo del modelo';

  @override
  String get useTheVerifiedMaximumOutputForThe =>
      'Usar la salida máxima verificada del modelo real';

  @override
  String get keepYourCustomOutputLength =>
      'Mantener la longitud de salida personalizada';

  @override
  String get theMaximumOutputForThisApiIs =>
      'La salida máxima de esta API no está verificada. Se usan 4096 tokens; puedes personalizarla.';

  @override
  String modelMaximumOutputTokensRequestsAdjustTo(String p0) {
    return 'Salida máxima del modelo: $p0 tokens. Se ajusta al contexto restante; el modelo puede terminar antes.';
  }

  @override
  String get contextLength => 'Longitud del contexto';

  @override
  String get customOutputLength => 'Longitud de salida personalizada';

  @override
  String get lengthsAreInTokensSomeModelsCount =>
      'Las longitudes están en tokens. Algunos modelos cuentan el razonamiento como salida.';

  @override
  String get outputLengthParameter => 'Parámetro de longitud de salida';

  @override
  String get standardParameter => 'Parámetro estándar';

  @override
  String get completionLengthParameter =>
      'Parámetro de longitud de finalización';

  @override
  String get chooseAccordingToTheProviderSApi =>
      'Elige según la API del proveedor. Esto no cambia la longitud introducida.';

  @override
  String get notTested => 'Sin probar';

  @override
  String get processing => 'Procesando…';

  @override
  String get saveModel => 'Guardar modelo';

  @override
  String emailCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 correos',
      one: '1 correo',
    );
    return '$_temp0';
  }

  @override
  String expandEmailCount(int p0) {
    return 'Mostrar los $p0';
  }

  @override
  String get previousEmailPage => 'Página anterior de correos';

  @override
  String get nextEmailPage => 'Página siguiente de correos';

  @override
  String get collapse => 'Contraer';

  @override
  String get qqMail => 'Correo QQ';

  @override
  String get enableMailServices => 'Activar servicios de correo';

  @override
  String get signInToQqMailInA =>
      'Inicia sesión en QQ Mail desde un navegador de escritorio. En Ajustes → Cuenta y seguridad → Seguridad, activa POP3/IMAP/SMTP.';

  @override
  String get generateAnAppPassword => 'Generar contraseña de aplicación';

  @override
  String get completeIdentityVerificationOnTheOfficialPage =>
      'Completa la verificación en la página oficial, genera una contraseña de aplicación de 16 caracteres e introdúcela aquí.';

  @override
  String get returnToAccountForm => 'Volver al formulario de cuenta';

  @override
  String get enterTheFullEmailAddressServersAre =>
      'Introduce la dirección completa. Los servidores ya están rellenados. Prueba la conexión antes de guardar.';

  @override
  String get getAndManageAppPasswords =>
      'Obtener y gestionar contraseñas de aplicación';

  @override
  String get mail368 => 'Correo 163';

  @override
  String get enableImapSmtp => 'Activar IMAP/SMTP';

  @override
  String get signInToWebmailFindPopSmtp =>
      'Inicia sesión en el correo web de 163. Busca POP3/SMTP/IMAP en los ajustes y activa IMAP/SMTP.';

  @override
  String get getAClientAppPassword => 'Obtener contraseña de cliente';

  @override
  String get completeTheVerificationAsInstructedAndEnter =>
      'Completa la verificación indicada e introduce aquí la contraseña del cliente generada.';

  @override
  String get checkTheFullEmailAddress => 'Verificar la dirección completa';

  @override
  String get useYourFullComAddressIfYou =>
      'Usa tu dirección completa @163.com. Si no encuentras el ajuste, busca “授权码” o “IMAP” en la ayuda oficial de NetEase.';

  @override
  String get neteaseMailOfficialHelp => 'Ayuda oficial de NetEase Mail';

  @override
  String get alibabaBusinessMail => 'Correo Alibaba Empresas';

  @override
  String get checkClientPermissions => 'Verificar permisos del cliente';

  @override
  String get askTheAdministratorToAllowThirdParty =>
      'Pide al administrador que permita clientes externos y active IMAP/SMTP. Las cuentas empresariales nuevas pueden bloquearlos por defecto.';

  @override
  String get prepareASecurityPassword => 'Preparar contraseña de seguridad';

  @override
  String get inWebmailGoToSettingsAccountAnd =>
      'En el correo web, ve a Ajustes → Cuenta y seguridad y genera una contraseña para clientes externos. Úsala aquí tras activarla.';

  @override
  String get enterTheBusinessEmailAddress => 'Introducir correo empresarial';

  @override
  String get useTheFullBusinessAddressDefaultServers =>
      'Usa la dirección empresarial completa. Los servidores están predefinidos; cámbialos en ajustes avanzados para Hong Kong o configuraciones de empresa.';

  @override
  String get allowThirdPartyClients => 'Permitir clientes externos';

  @override
  String get generateAThirdPartyClientSecurityPassword =>
      'Generar contraseña de seguridad para clientes externos';

  @override
  String get serverAddressesAndPorts => 'Direcciones y puertos de servidores';

  @override
  String get alibabaPersonalMail => 'Correo Alibaba Personal';

  @override
  String get checkAccountType => 'Verificar tipo de cuenta';

  @override
  String get thisPresetIsForFreeAlibabaCloud =>
      'Este ajuste es para el correo personal gratuito de Alibaba Cloud. Para dominios empresariales, elige Alibaba Empresas.';

  @override
  String get prepareLoginDetails => 'Preparar datos de acceso';

  @override
  String get enterTheFullEmailAddressAndRequired =>
      'Introduce la dirección completa y las credenciales requeridas. Asegúrate de que se permite el acceso de clientes.';

  @override
  String get checkServers => 'Verificar servidores';

  @override
  String get useTheOfficialSslServerSettingsBelow =>
      'Usa los ajustes SSL oficiales de abajo. Prueba la conexión antes de guardar.';

  @override
  String get personalMailServersAndPorts =>
      'Servidores y puertos de correo personal';

  @override
  String get customEmailProvider => 'Proveedor de correo personalizado';

  @override
  String get identifyYourProvider => 'Identificar el proveedor';

  @override
  String get aCustomDomainDoesNotIdentifyThe =>
      'Un dominio propio no identifica al proveedor. Consulta al administrador de correo.';

  @override
  String get getConnectionSettings => 'Obtener ajustes de conexión';

  @override
  String get prepareImapAndSmtpHostsPortsEncryption =>
      'Prepara hosts IMAP y SMTP, puertos, cifrado y contraseña o contraseña de aplicación.';

  @override
  String get enterAndVerify => 'Introducir y verificar';

  @override
  String get expandServerAndAdvancedSettingsAndEnter =>
      'Abre Servidor y ajustes avanzados e introduce los datos del proveedor.';

  @override
  String setupGuide(String p0) {
    return 'Guía de configuración de $p0';
  }

  @override
  String get closeSetupGuide => 'Cerrar guía de configuración';

  @override
  String get defaultServersSsl => 'Servidores predeterminados · SSL';

  @override
  String incomingPortOutgoingPort(String p0, String p1) {
    return 'Entrada  $p0\nPuerto 993\n\nSalida  $p1\nPuerto 465';
  }

  @override
  String get officialHelp => 'Ayuda oficial';

  @override
  String verifiedOfficialPagesOpenInYourBrowser(String p0) {
    return 'Verificado: $p0 · las páginas oficiales se abren en el navegador';
  }

  @override
  String get returnToForm => 'Volver al formulario';

  @override
  String get mailpilotPreview => 'MailPilot · Vista previa';

  @override
  String get thisLinkIsNotAValidWeb =>
      'Este enlace no es una dirección web válida';

  @override
  String get openWebpage => 'Abrir página web';

  @override
  String get copyLink => 'Copiar enlace';

  @override
  String get openInBrowser => 'Abrir en el navegador';

  @override
  String image(String p0) {
    return '[Imagen $p0]';
  }

  @override
  String get sizeUnknown => 'Tamaño desconocido';

  @override
  String get firstPagesByDefaultPageCountPending =>
      'Primeras 10 páginas por defecto; total pendiente';

  @override
  String get selectPdfPageNumbers => 'Seleccionar números de página PDF';

  @override
  String page(String p0) {
    return 'Página $p0';
  }

  @override
  String get fileName => 'Nombre de archivo';

  @override
  String get deselect => 'Deseleccionar';

  @override
  String get select420 => 'Seleccionar';

  @override
  String get materialsForThisAnalysis => 'Materiales de este análisis';

  @override
  String materialSummary(String p0, String p1, String p2) {
    return '$p0 adjuntos · $p1$p2';
  }

  @override
  String withUnknownSize(String p0) {
    return ' · $p0 de tamaño desconocido';
  }

  @override
  String get closeMaterials => 'Cerrar materiales';

  @override
  String upToAttachmentsMbAndImagesOr(String p0) {
    return 'Hasta 10 adjuntos, 50 MB y 20 imágenes o páginas PDF por turno.\n$p0';
  }

  @override
  String get actualImageCountsInPdfAndOffice =>
      'Las imágenes de archivos PDF y Office se cuentan al leerlos.';

  @override
  String get selectedFilesAreReadOnlyWhenPreviewing =>
      'Los archivos se leen solo al previsualizar o hacer una pregunta.';

  @override
  String get attachmentListAwaitingSync =>
      'Lista de adjuntos pendiente de sincronizar';

  @override
  String get selectAllSupportedAttachments =>
      'Seleccionar todos los adjuntos compatibles';

  @override
  String get keepBodyOnly => 'Conservar solo el cuerpo';

  @override
  String get deviceFiles => 'Archivos del dispositivo';

  @override
  String get noMaterialsSelectedAddFilesOrSelect =>
      'No hay materiales seleccionados. Añade archivos o selecciona correos.';

  @override
  String get materialCheckIncomplete => 'Comprobación de materiales incompleta';

  @override
  String get retryWithCurrentMaterials =>
      'Reintentar con los materiales actuales';

  @override
  String get analyzedImages => 'Imágenes analizadas';

  @override
  String get previousAnalysisIsReusedByDefaultSelect =>
      'Se reutiliza el análisis anterior por defecto. Selecciona revisar para nuevos detalles; se aplicará al próximo mensaje.';

  @override
  String get cancelRecheck => 'Cancelar revisión';

  @override
  String get recheckImages => 'Revisar imágenes de nuevo';

  @override
  String get previousVersion => 'Versión anterior';

  @override
  String messageVersionCount(String p0, String p1) {
    return 'Versión $p0 de $p1';
  }

  @override
  String get nextVersion => 'Versión siguiente';

  @override
  String get closeMessageActions => 'Cerrar acciones del mensaje';

  @override
  String get copyMessage => 'Copiar mensaje';

  @override
  String get messageCopied => 'Mensaje copiado';

  @override
  String close(String p0) {
    return 'Cerrar $p0';
  }

  @override
  String get volcengineArk => 'Volcengine · Ark';

  @override
  String get alibabaCloudModelStudio => 'Alibaba Cloud · Model Studio';

  @override
  String get openaiCompatibleApi => 'API compatible con OpenAI';

  @override
  String get minimalMinimal => 'Mínimo · minimal';

  @override
  String get lowLow => 'Bajo · low';

  @override
  String get mediumMedium => 'Medio · medium';

  @override
  String get highHigh => 'Alto · high';

  @override
  String get veryHighXhigh => 'Muy alto · xhigh';

  @override
  String get maximumMax => 'Máximo · max';

  @override
  String get chooseImageProcessing => 'Elegir procesamiento de imágenes';

  @override
  String get yourQuestionMaterialsAndCompletedAnalysisAre =>
      'Se conservan tu pregunta, materiales y análisis completados.';

  @override
  String get adjustMaterials => 'Ajustar materiales';

  @override
  String get reduceImagesPagesOrTextAndSubmit =>
      'Reduce imágenes, páginas o texto y vuelve a enviar';

  @override
  String get processThisTurnInBatches => 'Procesar este turno por lotes';

  @override
  String get readUnfinishedImagesInBatchesThenSummarize =>
      'Leer las imágenes pendientes por lotes y resumir';

  @override
  String get couldNotReadThisPage => 'No se pudo leer esta página';

  @override
  String get couldNotReadThisPagePleaseRetry =>
      'No se pudo leer esta página. Reinténtalo.';

  @override
  String get closePagePreview => 'Cerrar vista previa de página';

  @override
  String get pageImageUnavailable => 'Imagen de página no disponible';

  @override
  String get selectPdfPages => 'Seleccionar páginas PDF';

  @override
  String pagesTotal(String p0) {
    return ' · $p0 páginas en total';
  }

  @override
  String pagesSelectedMaximum(String p0) {
    return '$p0 páginas seleccionadas / máximo 20';
  }

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get firstPages => 'Primeras 10 páginas';

  @override
  String get clear => 'Borrar';

  @override
  String get readingPdf => 'Leyendo PDF…';

  @override
  String get couldNotReadPageNumbers =>
      'No se pudieron leer los números de página';

  @override
  String get retryReading => 'Reintentar lectura';

  @override
  String get selectUpToPagesPerPdf => 'Selecciona hasta 20 páginas por PDF';

  @override
  String get deselectThisAttachment => 'Deseleccionar este adjunto';

  @override
  String confirmSelectionPages(String p0) {
    return 'Confirmar selección · $p0 páginas';
  }

  @override
  String get retryPreview => 'Reintentar vista previa';

  @override
  String previewPage(String p0) {
    return 'Vista previa de página $p0';
  }

  @override
  String get loadingPreview => 'Cargando vista previa…';

  @override
  String page480(String p0, String p1) {
    return '$p0, página $p1';
  }

  @override
  String reasoningSegmentHeading(String p0) {
    return 'Razonamiento $p0\n';
  }

  @override
  String get searching => 'Buscando';

  @override
  String get searchIncomplete => 'Búsqueda incompleta';

  @override
  String searchResultCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 resultados encontrados',
      one: '1 resultado encontrado',
    );
    return '$_temp0';
  }

  @override
  String get readingWebpages => 'Leyendo páginas web';

  @override
  String readWebpageCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 páginas leídas',
      one: '1 página leída',
    );
    return '$_temp0';
  }

  @override
  String get webpageReadingFinished => 'Lectura de páginas finalizada';

  @override
  String get readingMaterials => 'Leyendo materiales';

  @override
  String get sourceExcerptViewed => 'Fragmento de fuente consultado';

  @override
  String get materialsReused => 'Materiales reutilizados';

  @override
  String get searchingEmails => 'Buscando correos';

  @override
  String get emailsSearched => 'Correos buscados';

  @override
  String get processing493 => 'Procesando';

  @override
  String get actionCompleted => 'Acción completada';

  @override
  String get lessThanSecond => 'Menos de 1 segundo';

  @override
  String elapsedSeconds(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 segundos',
      one: '1 segundo',
    );
    return '$_temp0';
  }

  @override
  String get thinking497 => 'Razonando';

  @override
  String get thinkingStopped => 'Razonamiento detenido';

  @override
  String get thinkingInterrupted => 'Razonamiento interrumpido';

  @override
  String get process => 'Proceso';

  @override
  String get thought => 'Razonamiento completado';

  @override
  String get reasoning => 'Razonamiento';

  @override
  String get viewReasoning => 'Ver razonamiento';

  @override
  String get currentAttempt => 'Intento actual';

  @override
  String get previousAttempt => 'Intento anterior';

  @override
  String earlierAttempt(String p0) {
    return 'Intento anterior $p0';
  }

  @override
  String get viewingAPreviousAttempt => 'Viendo un intento anterior';

  @override
  String get reasoningIsLongTheFirstCharactersHave =>
      'El razonamiento es largo. Se conservan los primeros 128000 caracteres.';

  @override
  String get jumpToEndOfReasoning => 'Ir al final del razonamiento';

  @override
  String get uiPreviewSampleDataInstallAndroidTo =>
      'Vista previa · datos de ejemplo. Instala Android para conectar correo y modelos.';

  @override
  String get dismissNotice => 'Cerrar aviso';

  @override
  String get backToHome => 'Volver al inicio';

  @override
  String get backToSettings => 'Volver a ajustes';

  @override
  String get backToConversation => 'Volver a la conversación';

  @override
  String get openMenu => 'Abrir menú';

  @override
  String get noVersionsAvailable => 'No hay versiones';

  @override
  String get couldNotLoadVersionsPleaseRetry =>
      'No se pudieron cargar las versiones. Reinténtalo.';

  @override
  String get cannotEditThisQuestion => 'No se puede editar esta pregunta';

  @override
  String get couldNotEditThisQuestionPleaseRetry =>
      'No se pudo editar esta pregunta. Reinténtalo.';

  @override
  String get editNotSubmittedPleaseRetry =>
      'La edición no se envió. Reinténtalo.';

  @override
  String get addAModelFirst => 'Añade primero un modelo';

  @override
  String get materialCheckIncompletePleaseRetry =>
      'Comprobación de materiales incompleta. Reinténtalo.';

  @override
  String get newConversation => 'Nueva conversación';

  @override
  String get whatSOnYourMind => '¿De qué quieres hablar?';

  @override
  String get letSMakeSenseOfYourEmails => 'Aclaremos tus correos juntos.';

  @override
  String get configureAModelToChatYouCan =>
      'Configura un modelo para chatear. Puedes añadir el correo después.';

  @override
  String get askAQuestionOrSelectEmailsAs =>
      'Haz una pregunta o selecciona correos como contexto.';

  @override
  String get helpMeOrganizeMyThoughts => 'Ayúdame a ordenar mis ideas';

  @override
  String get helpMeWriteSomething => 'Ayúdame a escribir un texto';

  @override
  String get summarizeSelectedEmails => 'Resumir correos seleccionados';

  @override
  String get helpMeDraftAReply => 'Ayúdame a redactar una respuesta';

  @override
  String get retryWebSearch => 'Reintentar búsqueda web';

  @override
  String get answerWithoutSearch => 'Responder sin buscar';

  @override
  String get continueSearching => 'Seguir buscando';

  @override
  String get responseIncomplete => 'Respuesta incompleta';

  @override
  String get continueOrganizing => 'Seguir organizando';

  @override
  String get retryThisTurn => 'Reintentar este turno';

  @override
  String get viewBudget => 'Ver presupuesto';

  @override
  String get retryWithCompatibleFormat => 'Reintentar con formato compatible';

  @override
  String get chooseProcessingMethod => 'Elegir método de procesamiento';

  @override
  String get adjustMaterialsAndRetry => 'Ajustar materiales y reintentar';

  @override
  String get restoreDefaultThinkingAndRetry =>
      'Restaurar razonamiento predeterminado y reintentar';

  @override
  String get chooseVisionAssistant => 'Elegir asistente visual';

  @override
  String get editConfiguration => 'Editar configuración';

  @override
  String vision(String p0) {
    return 'Visión · $p0';
  }

  @override
  String sourceCount(int p0) {
    String _temp0 = intl.Intl.pluralLogic(
      p0,
      locale: localeName,
      other: '$p0 fuentes',
      one: '1 fuente',
    );
    return '$_temp0';
  }

  @override
  String get copyResponse => 'Copiar respuesta';

  @override
  String get originalMarkdownCopied => 'Markdown original copiado';

  @override
  String get responseStopped => 'Respuesta detenida';

  @override
  String get stoppedThePartialResponseReceivedIsShown =>
      'Detenido. Arriba se muestra la respuesta parcial recibida.';

  @override
  String get reviewDraftAndSend => 'Revisar borrador y enviar';

  @override
  String get writeAsEmail => 'Redactar como correo';

  @override
  String get connectingToModel => 'Conectando al modelo…';

  @override
  String get viewingAnOlderVersion => 'Viendo una versión anterior';

  @override
  String get backToLatest => 'Volver a la última';

  @override
  String get textModel => 'Modelo de texto';

  @override
  String tapToCancelSync(String p0) {
    return '$p0 · toca para cancelar sincronización';
  }

  @override
  String get syncLatestEmailsInEachFolder =>
      'Sincronizar los últimos 50 correos de cada carpeta';

  @override
  String get searchEmails => 'Buscar correos';

  @override
  String get emailActions => 'Acciones de correo';

  @override
  String get syncEmailsPerFolder => 'Sincronizar correos (50 por carpeta)';

  @override
  String get showAll => 'Mostrar todos';

  @override
  String get showUnread => 'Ver no leídos';

  @override
  String get subjectOrSender => 'Asunto o remitente';

  @override
  String get runSearch => 'Ejecutar búsqueda';

  @override
  String get connectAnEmailAccountFirst =>
      'Conecta primero una cuenta de correo';

  @override
  String get supportsQqAndCustomEmailProviders =>
      'Compatible con QQ, 163 y proveedores personalizados.';

  @override
  String get noLocalEmailsYet => 'Aún no hay correos locales';

  @override
  String get pullDownToSyncRecentEmailsStartup =>
      'Desliza hacia abajo para sincronizar. No se sincroniza automáticamente al iniciar.';

  @override
  String analyzeSelectedEmails(String p0) {
    return 'Analizar $p0 correos seleccionados';
  }

  @override
  String get emailDetails => 'Detalles del correo';

  @override
  String get replyAndForward => 'Responder y reenviar';

  @override
  String get reply => 'Responder';

  @override
  String get replyAll => 'Responder a todos';

  @override
  String get forward => 'Reenviar';

  @override
  String get recipientDetails => 'Datos de destinatarios';

  @override
  String toCc(String p0, String p1) {
    return 'Para: $p0\nCc: $p1';
  }

  @override
  String get bodyAwaitingBackgroundSyncYouCanKeep =>
      'El cuerpo espera sincronización en segundo plano. Puedes seguir viendo otros correos.';

  @override
  String attachments(String p0) {
    return 'Adjuntos · $p0';
  }

  @override
  String get tapAnAttachmentToPreviewSelectIt =>
      'Toca un adjunto para verlo; selecciónalo para el análisis de IA';

  @override
  String get askAssistant => 'Consultar al asistente';

  @override
  String get noDraftsYet => 'Aún no hay borradores';

  @override
  String get writeYourOwnOrAskTheAssistant =>
      'Escribe tú o pide un borrador al asistente.';

  @override
  String get configurationSaved => 'Configuración guardada';

  @override
  String get closeConfiguration => 'Cerrar configuración';

  @override
  String get actionFailed => 'Error en la acción';

  @override
  String get backToConfiguration => 'Volver a configuración';

  @override
  String get volcengineWebSearch => 'Búsqueda web de Volcengine';

  @override
  String get bocha => 'Bocha';

  @override
  String get systemPreferredCloudOptional => 'Sistema preferido, nube opcional';

  @override
  String get qwenCloudTranscription => 'Transcripción en la nube de Qwen';

  @override
  String get automaticSystemRecognitionFollowsDeviceLanguage =>
      'Automático (el reconocimiento del sistema sigue el idioma del dispositivo)';

  @override
  String get chinese => 'Chino';

  @override
  String get searchProvider => 'Proveedor de búsqueda';

  @override
  String get recognitionMode => 'Modo de reconocimiento';

  @override
  String get speechLanguage => 'Idioma de voz';

  @override
  String get automatic => 'Automático';

  @override
  String get systemRecognitionNeedsNoApiKeyIf =>
      'El reconocimiento del sistema no necesita clave API. Si tu dispositivo no tiene servicio de reconocimiento, puedes usar Qwen ASR abajo.';

  @override
  String get usedOnlyWhenSmartSearchIsEnabled =>
      'Se usa solo al activar la búsqueda inteligente y preguntar. El servicio recibe palabras clave extraídas, no correos, adjuntos ni historial.';

  @override
  String get qwenAsrBaseUrl => 'URL base de Qwen ASR';

  @override
  String get fullSearchApiUrl => 'URL completa de la API de búsqueda';

  @override
  String get leaveBlankToRetainTheSavedKey =>
      'Deja en blanco para conservar la clave';

  @override
  String get showOrHideKey => 'Mostrar u ocultar clave';

  @override
  String get asrModel => 'Modelo ASR';

  @override
  String get forExampleQwenAsrFlash => 'Por ejemplo, qwen3-asr-flash';

  @override
  String get transcriptionFillsTheInputFieldOnlyReview =>
      'La transcripción solo rellena el campo; revísala antes de enviar. El modo nube requiere una nueva grabación de hasta 60 segundos.';

  @override
  String get streamingUiStateIsOutOfSync =>
      'El estado de la interfaz está desincronizado. Abre de nuevo la conversación.';

  @override
  String get streamNotReceivedCompletelyReopenThisConversation =>
      'El flujo no se recibió completo. Abre de nuevo la conversación.';

  @override
  String get appLanguage => 'Idioma';

  @override
  String get languageTitle => 'Elegir idioma';

  @override
  String get languageDescription =>
      'Cambia el idioma de la interfaz. Correos y conversaciones conservan su contenido original.';
}
