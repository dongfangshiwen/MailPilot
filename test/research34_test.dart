import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/reasoning_panel.dart';

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      for (final brightness in Brightness.values) {
        testWidgets('research timeline $width $scale $brightness', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          Future<void> show(bool done) async {
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
                      padding: const EdgeInsets.all(16),
                      child: ReasoningPanel(
                        reasoning: {
                          'text': '根据邮件中的公开主题检索。',
                          'state': 'completed',
                          'runComplete': done,
                          'revision': done ? 4 : 3,
                          'segments': [
                            {
                              'id': 's',
                              'start': 0,
                              'end': 14,
                              'order': 1,
                              'state': 'completed',
                            },
                          ],
                          'activities': [
                            {
                              'id': 'search',
                              'kind': 'web_search',
                              'state': 'completed',
                              'count': 5,
                              'order': 2,
                              'domains': ['example.org'],
                            },
                            {
                              'id': 'read',
                              'kind': 'read_web_page',
                              'state': 'completed',
                              'count': 2,
                              'order': 3,
                            },
                          ],
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 100));
          }

          await show(false);
          expect(find.text('搜索到 5 条结果'), findsOneWidget);
          expect(find.text('已读取 2 个网页'), findsOneWidget);
          expect(find.text('回到思考末尾'), findsNothing);
          await tester.tap(find.byType(InkWell).first);
          await tester.pump();
          await tester.tap(find.byType(InkWell).first);
          await tester.pump();
          await show(true);
          expect(find.byKey(const ValueKey('reasoning-body')), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
