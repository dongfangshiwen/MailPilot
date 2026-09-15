import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controller.dart';
import 'screens.dart';
import 'preview_data.dart';
import 'app_language.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    AndroidBackend.available
        ? MailPilotApp(controller: MailController(AndroidBackend()))
        : const MailPilotPreview(),
  );
}

/// Web / desktop previews have no native mail channels or real credentials.
class MailPilotPreview extends StatefulWidget {
  const MailPilotPreview({super.key});
  @override
  State<MailPilotPreview> createState() => _MailPilotPreviewState();
}

class _MailPilotPreviewState extends State<MailPilotPreview> {
  late final backend = PreviewBackend(simulateReasoning: true);
  late final controller = MailController(backend, initial: backend.data);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      MailPilotApp(controller: controller, preview: true);
}

class MailPilotApp extends StatefulWidget {
  const MailPilotApp({
    super.key,
    required this.controller,
    this.autoStart = true,
    this.preview = false,
  });
  final MailController controller;
  final bool autoStart;
  final bool preview;
  @override
  State<MailPilotApp> createState() => _MailPilotAppState();
}

class _MailPilotAppState extends State<MailPilotApp> {
  @override
  void initState() {
    super.initState();
    if (widget.autoStart) unawaited(widget.controller.start());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (_, _) {
      final mode = widget.controller.settings.text('theme');
      return MaterialApp(
        title: 'MailPilot',
        debugShowCheckedModeBanner: false,
        locale: AppLanguage.fromCode(
          widget.controller.settings.text('appLanguage'),
        ).locale,
        supportedLocales: AppLanguage.values.map((language) => language.locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: mailTheme(false),
        darkTheme: mailTheme(true),
        themeMode: mode == 'dark'
            ? ThemeMode.dark
            : mode == 'light'
            ? ThemeMode.light
            : ThemeMode.system,
        home: MailHome(controller: widget.controller, preview: widget.preview),
      );
    },
  );
}

ThemeData mailTheme(bool dark) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xff4167ed),
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: dark ? const Color(0xffa7bbff) : const Color(0xff4167ed),
        surface: dark ? const Color(0xff161719) : Colors.white,
        surfaceContainerLow: dark
            ? const Color(0xff222427)
            : const Color(0xfff6f7f9),
        onSurface: dark ? const Color(0xffeeeeef) : const Color(0xff202124),
        onSurfaceVariant: dark
            ? const Color(0xffb2b5bd)
            : const Color(0xff737780),
        outlineVariant: dark
            ? const Color(0xff36383e)
            : const Color(0xffeceef2),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionHandleColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: dark ? .38 : .28),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    textTheme: Typography.material2021().black.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: .7,
      space: 1,
    ),
  );
}
