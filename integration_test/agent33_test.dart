import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/reasoning_panel.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('API36 stable multi-request thinking and retry history', (
    tester,
  ) async {
    final samples = <FrameTiming>[];
    void timing(List<FrameTiming> values) => samples.addAll(values);
    SchedulerBinding.instance.addTimingsCallback(timing);
    final trace = ValueNotifier<Map<String, dynamic>>({
      'attemptId': 'device33',
      'state': 'thinking',
      'text': '',
      'runComplete': false,
      'elapsedMs': 0,
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff5162ad),
            brightness: Brightness.dark,
          ),
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('思考过程')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: ValueListenableBuilder(
              valueListenable: trace,
              builder: (_, value, _) => ReasoningPanel(
                key: const ValueKey('stable'),
                reasoning: value,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    samples.clear();
    var text = '';
    try {
      for (var i = 0; i < 90; i++) {
        text += '已核对资料片段 $i。';
        trace.value = {
          ...trace.value,
          'text': text,
          'elapsedMs': i * 32,
          'state': i == 35 ? 'completed' : 'thinking',
        };
        await tester.pump(const Duration(milliseconds: 32));
        if (i == 35) expect(find.byType(SelectableText), findsOneWidget);
      }
      trace.value = {...trace.value, 'state': 'completed'};
      await tester.pump(const Duration(seconds: 1));
      SchedulerBinding.instance.removeTimingsCallback(timing);
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      trace.value = {...trace.value, 'state': 'completed', 'runComplete': true};
      await tester.pump();
      expect(find.byType(SelectableText), findsOneWidget);
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('agent33-thinking-stable-dark');
      final old = trace.value;
      trace.value = {
        'attemptId': 'retry33',
        'state': 'thinking',
        'text': '本次正在继续处理。',
        'runComplete': false,
        'elapsedMs': 300,
        'previous': [old],
      };
      await tester.pump();
      await tester.tap(find.text('上次尝试'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('上次尝试').last);
      await tester.pumpAndSettle();
      expect(find.text(text), findsOneWidget);
      await binding.takeScreenshot('agent33-previous-attempt-dark');
      final builds = samples.map((v) => v.buildDuration.inMicroseconds).toList()
        ..sort();
      final rasters =
          samples.map((v) => v.rasterDuration.inMicroseconds).toList()..sort();
      binding.reportData = {
        ...?binding.reportData,
        'frames': samples.length,
        'buildP95Micros': builds.isEmpty
            ? null
            : builds[(builds.length * .95).floor().clamp(0, builds.length - 1)],
        'rasterP95Micros': rasters.isEmpty
            ? null
            : rasters[(rasters.length * .95).floor().clamp(
                0,
                rasters.length - 1,
              )],
        'over16msBuild': builds.where((v) => v > 16667).length,
        'syntheticStream': true,
        'measurement': 'stream-only; startup, screenshots and menus excluded',
        'mode': 'profile',
      };
    } finally {
      SchedulerBinding.instance.removeTimingsCallback(timing);
      await tester.pumpWidget(const SizedBox());
      trace.dispose();
    }
  });
}
