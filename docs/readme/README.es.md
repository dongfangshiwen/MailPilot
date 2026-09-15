<p align="center"><img src="../../docs/assets/mailpilot-banner.svg" alt="MailPilot" width="100%" /></p>

<h1 align="center">MailPilot</h1>
<p align="center">Conversaciones con IA, lectura de correo y respuestas en una sola app Android.</p>
<p align="center"><a href="https://github.com/dongfangshiwen/MailPilot/releases/latest">Descargar 1.0.0</a> · <a href="#quick-start">Primeros pasos</a> · <a href="#build">Instalación y compilación</a></p>

[简体中文](../../README.md) · [繁體中文](../../docs/readme/README.zh-Hant.md) · [English](../../docs/readme/README.en.md) · [日本語](../../docs/readme/README.ja.md) · [한국어](../../docs/readme/README.ko.md) · **Español** · [Français](../../docs/readme/README.fr.md) · [Deutsch](../../docs/readme/README.de.md)

> **Android 8.0+ · Flutter + Kotlin · 8 idiomas de interfaz**<br>
> Configura tu propio modelo para empezar a conversar y añade una cuenta de correo cuando la necesites. La app se conecta directamente a tus servicios; no requiere un servidor de MailPilot. Los mensajes solo se envían tras tu confirmación.

## Qué puedes hacer

| Función | Utilidad |
| --- | --- |
| **Conversaciones con IA** | Respuestas Markdown en streaming, razonamiento y actividad desplegables, cambio de modelo, parada y reintento. |
| **Asistencia de correo** | Conexión IMAP / SMTP, búsqueda y lectura de mensajes, análisis del contenido y los adjuntos seleccionados. |
| **Imágenes y documentos** | Imágenes, PDF, Office y texto. Reutiliza análisis de imágenes terminados en la misma conversación o solicita otra revisión. |
| **Búsqueda y fuentes** | Busca información pública con tu servicio configurado, lee enlaces de los materiales cuando haga falta y consulta las citas. |
| **Redactar y enviar** | Convierte una respuesta en correo, modifica destinatarios y adjuntos y revisa la tarjeta de confirmación antes de enviar. |
| **Historial organizado** | Búsqueda, grupos por fecha, fijación, cambio de nombre y selección múltiple en la barra lateral. Los resúmenes conservan los registros originales. |
| **Preferencias** | Ocho idiomas, temas claro y oscuro, entrada por voz y sincronización opcional, incluso una vez al día. |

## La interfaz

<p align="center">
  <img src="../../docs/screenshots/build43/language-zh-settings.png" width="30%" alt="简体中文" />
  <img src="../../docs/screenshots/build43/language-en-settings.png" width="30%" alt="English" />
  <img src="../../docs/screenshots/build43/language-de-settings.png" width="30%" alt="Deutsch — dark theme" />
</p>

Ajustes en chino simplificado, inglés y alemán con tema oscuro. Las capturas contienen configuraciones de ejemplo, sin credenciales reales.

<a id="quick-start"></a>
## Primeros pasos

1. **Instala la app**: descarga el APK desde Releases. Para actualizar y conservar los datos, utiliza un paquete con la misma firma que la instalación existente.
2. **Añade un modelo**: Ajustes → Modelos y servicios → Añadir modelo. Introduce proveedor, Base URL HTTPS, identificador del modelo y clave API. Puedes configurar DeepSeek, Volcengine Ark, Alibaba Cloud Model Studio o interfaces compatibles; las funciones dependen del modelo.
3. **Empieza a conversar**: escribe una pregunta o añade imágenes y archivos con el botón +. No necesitas una cuenta de correo para conversar con la IA.
4. **Conecta el correo (opcional)**: añade una cuenta desde Ajustes. Hay opciones para QQ, 163, Alibaba Mail e IMAP / SMTP personalizado. Activa los servicios en tu proveedor y utiliza su código de autorización o contraseña de aplicación.
5. **Lee y responde**: abre Mis correos en Ajustes y sincroniza. En la conversación, pulsa + → Seleccionar correos, revisa los adjuntos y pide un análisis o borrador. Comprueba destinatarios, texto y adjuntos antes de confirmar el envío.
6. **Personaliza**: configura Búsqueda y voz y elige idioma, apariencia y sincronización en Preferencias. El idioma inicial es chino simplificado. Cambiarlo no traduce automáticamente los correos ni las respuestas del modelo.

### Ejemplos de preguntas

- «Resume los correos seleccionados e indica fechas de entrega, importes y dudas pendientes».
- «Compara las especificaciones de estas imágenes y cita las fuentes».
- «Redacta una respuesta en inglés con estas conclusiones y deja que la revise primero».

### Adjuntos compatibles

| Tipo | Tratamiento |
| --- | --- |
| JPG / PNG / WebP | Análisis con el modelo visual configurado |
| PDF | Páginas elegidas convertidas en imágenes; las 10 primeras por defecto |
| DOCX / XLSX / PPTX | Extracción local de texto, tablas e imágenes integradas |
| TXT | Lectura local; convierte antes los antiguos DOC / XLS / PPT |

Por turno: hasta 10 adjuntos, 50 MB en total y 20 elementos visuales; máximo 20 MB por adjunto. Las solicitudes codificadas también están sujetas al límite de 32 MiB de la app y a los límites del proveedor. Ajusta la selección o elige procesar por lotes si se supera un límite.

<a id="build"></a>
## Instalación y compilación

Se ejecuta en Android, sin Docker, servidor de base de datos ni backend API independiente. Introduce las credenciales en Ajustes, no en el código. La versión Web es solo una vista previa con datos de ejemplo.

### Entorno de compilación

| Componente | Versión validada |
| --- | --- |
| Flutter / Dart | 3.47.2 / 3.13.2 |
| JDK | 17–25 |
| Android SDK / Build Tools | 36 / 36.0.0 |
| NDK / CMake | 28.2.13676358 / 3.22.1 |
| Gradle / AGP | 9.3.1 / 9.1.0 |

Instala Flutter y Android Studio, añade Flutter al PATH e instala los componentes Android indicados mediante SDK Manager. Cambia la ruta del JDK por la de tu equipo. La primera descarga de dependencias requiere conexión a internet.

```powershell
git clone https://github.com/dongfangshiwen/MailPilot.git
cd MailPilot
flutter doctor

$env:MAILPILOT_JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
.\scripts\Build.ps1 -Mode Debug
.\scripts\Build.ps1 -Mode Release
.\scripts\Package-Delivery.ps1
```

Debug utiliza el paquete aislado `app.mailpilot.validation`; Release utiliza `app.mailpilot`. Los scripts generan la configuración local del SDK. La primera compilación Release crea `.signing/`: consérvalo para las actualizaciones. Una clave nueva no puede actualizar una instalación con la firma oficial.

### Archivos de salida · artifacts/

| Archivo | Contenido |
| --- | --- |
| `MailPilot-1.0.0-flutter-release.apk` | Instalador Android |
| `MailPilot-1.0.0-flutter-source.zip` | Código, scripts, documentación y capturas |
| `MailPilot-1.0.0-flutter-delivery.zip` | Paquete completo con APK y código |
| `*.sha256` | Suma SHA-256 del archivo correspondiente |

### Pruebas

```powershell
.\scripts\Build.ps1 -Mode Test
adb devices
.\scripts\Test-Profile.ps1 -Device emulator-5554 -Mode Debug -Target integration_test/language43_test.dart
```

Sustituye el identificador del dispositivo por el que indique `adb devices`. Las pruebas de interfaz usan un paquete aislado que permanece instalado. No ejecutes `flutter drive` directamente sobre la app de uso diario.

La actualización de idiomas superó 489 pruebas Flutter, 3 pruebas nativas de idioma y la validación aislada en API36. Lint no detectó errores y mostró 13 avisos. Los 72 casos de diseño cubren ocho idiomas, tres anchos y escalado de texto. Consulta el informe enlazado.

### Vista previa en el navegador

```powershell
flutter run -d chrome -t lib/main_preview.dart
```

Utiliza correos de ejemplo y respuestas simuladas, sin conectar con servicios reales. No constituye un cliente de correo Web compatible.

## Estructura del proyecto

```text
MailPilot/
├── lib/                    # Flutter UI
│   └── l10n/               # ARB resources & generated localizations
├── android/app/src/main/   # Android services & Agent
├── test/                   # Flutter tests
├── integration_test/       # Isolated UI tests
├── scripts/                # Windows build & packaging
└── docs/                   # Guides, reports & screenshots
```

Flutter presenta la interfaz y llama a Kotlin mediante canales de plataforma. Android gestiona el Agent, correo, adjuntos, Room y DataStore. Edita los ARB de `lib/l10n/` y ejecuta `flutter gen-l10n`.

## Datos y envío

- Los códigos de autorización y las claves API se cifran con Android Keystore. Las conversaciones, los adjuntos y la caché se guardan en el espacio privado de la app.
- Al preguntar, el material seleccionado se envía al modelo configurado. La búsqueda y la voz en la nube utilizan sus servicios correspondientes y pueden generar cargos.
- La lectura Web es de solo lectura. Los inicios de sesión, CAPTCHA y algunas páginas dinámicas pueden impedir extraer contenido; no se garantiza la lectura de todos los enlaces.
- El envío siempre requiere confirmación. La sincronización en segundo plano está desactivada por defecto y no analiza ni envía correos automáticamente.
- Desinstalar elimina los datos locales. Los paquetes excluyen firmas, configuraciones personales y bases de datos. Guarda una copia independiente de `.signing/` si desarrollas la app.

## Más información

- [Configuración del correo](../../docs/MAIL_SETUP.md)
- [Ocho idiomas e informe de pruebas](../../docs/LOCALIZATION_1_0_0_BUILD_43.md)
- [Historial de versiones](../../docs/CHANGELOG.md)
- [Componentes de terceros](../../docs/THIRD_PARTY.md)

El README está disponible en ocho idiomas. La documentación técnica detallada está principalmente en chino simplificado.
