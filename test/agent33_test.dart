import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/reasoning_panel.dart';
import 'package:mailpilot/stream_state_decoder.dart';

void main() {
  testWidgets(
    'tool boundaries retain thoughts and manual expansion survives final save',
    (tester) async {
      Future<void> show(String state, String text, {bool done = false}) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReasoningPanel(
                key: const ValueKey('same'),
                reasoning: {
                  'attemptId': 'a',
                  'text': text,
                  'state': state,
                  'elapsedMs': 1000,
                  'runComplete': done,
                },
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }

      await show('thinking', '第一段');
      await show('completed', '第一段');
      expect(find.text('第一段'), findsOneWidget);
      await show('thinking', '第一段\n\n第二段');
      expect(find.text('第一段\n\n第二段'), findsOneWidget);
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await show('completed', '第一段\n\n第二段', done: true);
      expect(find.text('第一段\n\n第二段'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'late full snapshots and duplicate deltas do not replace newer reasoning',
    () {
      final decoder = StreamStateDecoder();
      final initial = <String, dynamic>{
        'activeAccount': 'a',
        'conversationId': 'c',
        'responseId': 'r',
        'streaming': '',
        'reasoning': {'text': '第一段', 'state': 'thinking'},
        'draftPartial': {},
      };
      decoder.decode({
        'streamFrame': 1,
        'epoch': 'one',
        'sequence': 1,
        'state': initial,
      });
      final delta = {
        'streamFrame': 1,
        'epoch': 'one',
        'sequence': 2,
        'base': 1,
        'account': 'a',
        'conversation': 'c',
        'response': 'r',
        'streaming': {'at': 0, 'text': ''},
        'reasoning': {
          'text': {'at': 3, 'text': '第二段'},
          'state': 'thinking',
        },
        'draftPartial': {},
      };
      final value = decoder.decode(delta);
      expect(decoder.decode(delta), same(value));
      expect(
        decoder.decode({
          'streamFrame': 1,
          'epoch': 'one',
          'sequence': 1,
          'state': initial,
        }),
        same(value),
      );
      expect((value['reasoning'] as Map)['text'], '第一段第二段');
      expect(
        decoder.decode({
          'streamFrame': 1,
          'epoch': 'new',
          'sequence': 1,
          'state': initial,
        })['reasoning'],
        initial['reasoning'],
      );
    },
  );

  for (final width in [320.0, 360.0, 412.0]) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 1.6, 2.0]) {
        testWidgets('stable reasoning $width $brightness scale $scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final RowData old = {
            'attemptId': 'old',
            'text': '上次的内容仍然保留。',
            'state': 'interrupted',
            'runComplete': true,
            'elapsedMs': 2000,
          };
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 800),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ReasoningPanel(
                      reasoning: {
                        'attemptId': 'new',
                        'state': 'thinking',
                        'runComplete': false,
                        'text': List.filled(30, '当前思考内容。\n').join(),
                        'elapsedMs': 1000,
                        'previous': [old],
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          for (var i = 0; i < 40; i++) {
            await tester.pump(const Duration(milliseconds: 32));
          }
          final scroller = find.byType(SingleChildScrollView);
          await tester.drag(scroller, const Offset(0, 180));
          await tester.pump(const Duration(milliseconds: 300));
          final arrow = find.byKey(const ValueKey('reasoning-scroll-to-end'));
          expect(arrow, findsOneWidget);
          expect(find.text('回到思考末尾'), findsNothing);
          expect(tester.getSize(arrow).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(arrow).height, greaterThanOrEqualTo(48));
          await tester.tap(arrow);
          for (var i = 0; i < 40; i++) {
            await tester.pump(const Duration(milliseconds: 32));
          }
          expect(arrow, findsNothing);
          expect(
            tester
                .widget<SingleChildScrollView>(scroller)
                .controller!
                .position
                .extentAfter,
            lessThan(1),
          );
          await tester.tap(find.text('上次尝试'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('上次尝试').last);
          await tester.pumpAndSettle();
          expect(find.text('上次的内容仍然保留。'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
