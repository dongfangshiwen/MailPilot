<p align="center"><img src="../../docs/assets/mailpilot-banner.svg" alt="MailPilot" width="100%" /></p>

<h1 align="center">MailPilot</h1>
<p align="center">KI-Gespräche, E-Mails lesen und antworten – gemeinsam in einer Android-App.</p>
<p align="center"><a href="https://github.com/dongfangshiwen/MailPilot/releases/latest">1.0.0 herunterladen</a> · <a href="#quick-start">Erste Schritte</a> · <a href="#build">Einrichtung und Build</a></p>

[简体中文](../../README.md) · [繁體中文](../../docs/readme/README.zh-Hant.md) · [English](../../docs/readme/README.en.md) · [日本語](../../docs/readme/README.ja.md) · [한국어](../../docs/readme/README.ko.md) · [Español](../../docs/readme/README.es.md) · [Français](../../docs/readme/README.fr.md) · **Deutsch**

> **Android 8.0+ · Flutter + Kotlin · 8 Oberflächensprachen**<br>
> Mit einem selbst konfigurierten Modell können Sie sofort chatten. Ein E-Mail-Konto fügen Sie bei Bedarf hinzu. Die App verbindet sich direkt mit Ihren Diensten; ein MailPilot-Server ist nicht erforderlich. E-Mails werden erst nach Ihrer Bestätigung gesendet.

## Funktionen

| Funktion | Nutzen |
| --- | --- |
| **KI-Gespräche** | Markdown-Antworten als Stream, aufklappbare Denk- und Verarbeitungsschritte, Modellwechsel, Stopp und Wiederholung. |
| **E-Mail-Assistent** | IMAP / SMTP verbinden, Nachrichten suchen und lesen sowie ausgewählte Inhalte und Anhänge analysieren. |
| **Bilder und Dokumente** | Bilder, PDF, Office und Text. Abgeschlossene Bildanalysen im selben Gespräch wiederverwenden oder erneut prüfen lassen. |
| **Suche und Quellen** | Öffentliche Informationen über den eingerichteten Suchdienst finden, Dokumentlinks bei Bedarf lesen und Quellen nachprüfen. |
| **Entwurf und Versand** | Antworten in E-Mail-Entwürfe umwandeln, Empfänger und Anhänge bearbeiten und vor dem Versand die Bestätigungskarte prüfen. |
| **Gesprächsverwaltung** | Suche, Datumsgruppen, Anheften, Umbenennen und Mehrfachauswahl in der Seitenleiste. Originalnachrichten bleiben nach Zusammenfassungen erhalten. |
| **Einstellungen** | Acht Sprachen, helles und dunkles Design, Spracheingabe und optionale Hintergrundsynchronisierung, auch einmal täglich. |

## Einblick in die Oberfläche

<p align="center">
  <img src="../../docs/screenshots/build43/language-zh-settings.png" width="30%" alt="简体中文" />
  <img src="../../docs/screenshots/build43/language-en-settings.png" width="30%" alt="English" />
  <img src="../../docs/screenshots/build43/language-de-settings.png" width="30%" alt="Deutsch — dark theme" />
</p>

Einstellungen auf vereinfachtem Chinesisch, Englisch und Deutsch im dunklen Design. Die Bilder zeigen Beispielkonfigurationen ohne echte Zugangsdaten.

<a id="quick-start"></a>
## Erste Schritte

1. **Installieren**: Laden Sie die APK unter Releases herunter. Verwenden Sie für Updates dieselbe Signatur wie bei der bestehenden Installation, damit die Daten erhalten bleiben.
2. **Modell hinzufügen**: Einstellungen → Modelle und Dienste → Modell hinzufügen. Anbieter, HTTPS Base URL, Modellkennung und API-Schlüssel eintragen. DeepSeek, Volcengine Ark, Alibaba Cloud Model Studio und kompatible Schnittstellen sind konfigurierbar; die Fähigkeiten hängen vom Modell ab.
3. **Gespräch starten**: Stellen Sie auf der Startseite eine Frage oder fügen Sie über + Bilder und Dateien hinzu. Ein E-Mail-Konto ist für KI-Chats nicht nötig.
4. **E-Mail verbinden (optional)**: Fügen Sie unter Einstellungen ein Konto hinzu. Unterstützt werden QQ, 163, Alibaba Mail und eigene IMAP-/SMTP-Konfigurationen. Aktivieren Sie die Dienste beim Anbieter und verwenden Sie dessen Autorisierungscode oder App-Passwort.
5. **Lesen und antworten**: Öffnen Sie Meine E-Mails in den Einstellungen und synchronisieren Sie. Wählen Sie im Chat über + E-Mails und Anhänge aus und fordern Sie eine Analyse oder einen Entwurf an. Prüfen Sie Empfänger, Inhalt und Anhänge vor der Sendebestätigung.
6. **Anpassen**: Richten Sie Suche und Sprache ein und wählen Sie Sprache, Design und Synchronisierung unter Voreinstellungen. Standard ist vereinfachtes Chinesisch. Die Oberflächensprache übersetzt E-Mails und Modellantworten nicht automatisch.

### Beispielfragen

- „Fasse die ausgewählten E-Mails zusammen und nenne Liefertermine, Beträge und offene Fragen.“
- „Vergleiche die technischen Angaben in diesen Bildern und gib die Quellen an.“
- „Erstelle daraus eine englische Antwort und lass mich sie zuerst prüfen.“

### Unterstützte Anhänge

| Typ | Verarbeitung |
| --- | --- |
| JPG / PNG / WebP | Analyse durch das konfigurierte Bildmodell |
| PDF | Ausgewählte Seiten als Bilder; standardmäßig die ersten 10 Seiten |
| DOCX / XLSX / PPTX | Text, Tabellen und eingebettete Bilder lokal extrahieren |
| TXT | Lokal lesen; ältere DOC / XLS / PPT vorher konvertieren |

Pro Runde höchstens 10 Anhänge, insgesamt 50 MB und 20 visuelle Elemente; höchstens 20 MB je Anhang. Für kodierte Anfragen gelten zusätzlich 32 MiB als App-Grenze und die Grenzen des Anbieters. Bei Überschreitung die Auswahl anpassen oder eine Stapelverarbeitung wählen.

<a id="build"></a>
## Einrichtung und Build

MailPilot läuft auf Android. Docker, Datenbankserver und ein eigenes API-Backend sind nicht nötig. Zugangsdaten gehören in die Einstellungen der installierten App, nicht in den Quellcode. Web dient nur als Vorschau mit Beispieldaten.

### Build-Umgebung

| Komponente | Geprüfte Version |
| --- | --- |
| Flutter / Dart | 3.47.2 / 3.13.2 |
| JDK | 17–25 |
| Android SDK / Build Tools | 36 / 36.0.0 |
| NDK / CMake | 28.2.13676358 / 3.22.1 |
| Gradle / AGP | 9.3.1 / 9.1.0 |

Installieren Sie Flutter und Android Studio, nehmen Sie Flutter in PATH auf und installieren Sie die aufgeführten Android-Komponenten im SDK Manager. Passen Sie den JDK-Pfad an Ihren Rechner an. Der erste Download der Abhängigkeiten benötigt Internet.

```powershell
git clone https://github.com/dongfangshiwen/MailPilot.git
cd MailPilot
flutter doctor

$env:MAILPILOT_JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
.\scripts\Build.ps1 -Mode Debug
.\scripts\Build.ps1 -Mode Release
.\scripts\Package-Delivery.ps1
```

Debug verwendet das isolierte Paket `app.mailpilot.validation`, Release dagegen `app.mailpilot`. Die Skripte erzeugen die lokale SDK-Konfiguration. Der erste Release-Build erstellt `.signing/`; bewahren Sie es für Updates auf. Ein neuer Schlüssel kann eine offiziell signierte Installation nicht aktualisieren.

### Ausgabedateien · artifacts/

| Datei | Zweck |
| --- | --- |
| `MailPilot-1.0.0-flutter-release.apk` | Android-Installationsdatei |
| `MailPilot-1.0.0-flutter-source.zip` | Quellcode, Skripte, Dokumentation und Screenshots |
| `MailPilot-1.0.0-flutter-delivery.zip` | Komplettpaket mit APK und Quellcode |
| `*.sha256` | SHA-256-Prüfsumme der jeweiligen Datei |

### Tests

```powershell
.\scripts\Build.ps1 -Mode Test
adb devices
.\scripts\Test-Profile.ps1 -Device emulator-5554 -Mode Debug -Target integration_test/language43_test.dart
```

Ersetzen Sie die Gerätekennung durch die Ausgabe von `adb devices`. Das UI-Testskript verwendet ein isoliertes Paket und lässt es installiert. Führen Sie `flutter drive` nicht direkt mit dem täglich genutzten App-Paket aus.

Das Sprachupdate bestand 489 Flutter-Tests, 3 native Sprachtests und die isolierte API36-Prüfung. Lint meldet keine Fehler und 13 Hinweise. 72 Layoutfälle prüfen acht Sprachen, drei Breiten und Textskalierung. Details stehen im verlinkten Testbericht.

### Browser-Vorschau

```powershell
flutter run -d chrome -t lib/main_preview.dart
```

Die Vorschau nutzt Beispielmails und simulierte Antworten ohne Verbindung zu echten Diensten. Sie ist kein unterstützter Web-E-Mail-Client.

## Projektstruktur

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

Flutter zeichnet die Oberfläche und ruft Kotlin-Dienste über Plattformkanäle auf. Android übernimmt Agent, E-Mail, Anhänge, Room und DataStore. Nach Änderungen an ARB-Dateien in `lib/l10n/` führen Sie `flutter gen-l10n` aus.

## Daten und Versand

- Autorisierungscodes und API-Schlüssel werden mit Android Keystore verschlüsselt. Gespräche, Anhänge und Cache liegen im privaten App-Speicher.
- Bei einer Frage werden ausgewählte Inhalte an das konfigurierte Modell übertragen. Suche und Cloud-Sprache nutzen ihre jeweiligen Dienste und können Kosten verursachen.
- Webseitenzugriffe sind lesend. Anmeldung, CAPTCHA und manche dynamischen Seiten verhindern die Extraktion; nicht jeder Link lässt sich auslesen.
- Der Versand verlangt immer eine Bestätigung. Hintergrundsynchronisierung ist standardmäßig deaktiviert und analysiert oder versendet keine E-Mails automatisch.
- Eine Deinstallation löscht lokale Daten. Archive enthalten weder Signaturschlüssel noch persönliche Konfigurationen oder Datenbanken. Entwickler sollten `.signing/` getrennt sichern.

## Weitere Informationen

- [E-Mail-Einrichtung](../../docs/MAIL_SETUP.md)
- [Acht Sprachen und Testbericht](../../docs/LOCALIZATION_1_0_0_BUILD_43.md)
- [Versionsverlauf](../../docs/CHANGELOG.md)
- [Drittanbieter-Komponenten](../../docs/THIRD_PARTY.md)

Die README gibt es in acht Sprachen. Ausführliche technische Unterlagen sind derzeit überwiegend auf vereinfachtem Chinesisch verfügbar.
