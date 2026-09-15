import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/reasoning_panel.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('thinking end control uses only an accessible arrow', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            appBar: AppBar(title: const Text('思考过程')),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: ReasoningPanel(
                key: ValueKey(brightness),
                reasoning: {
                  'state': 'completed',
                  'runComplete': true,
                  'text': List.generate(
                    40,
                    (i) => '资料核对 ${i + 1}：采购方与产品公开信息。',
                  ).join('\n'),
                  'elapsedMs': 4000,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      final scroller = find.byType(SingleChildScrollView);
      await tester.drag(scroller, const Offset(0, -80));
      await tester.pumpAndSettle();
      final arrow = find.byKey(const ValueKey('reasoning-scroll-to-end'));
      expect(arrow, findsOneWidget);
      expect(find.text('回到思考末尾'), findsNothing);
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('reasoning-icon-${brightness.name}');
      await tester.tap(arrow);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SingleChildScrollView>(scroller)
            .controller!
            .position
            .extentAfter,
        lessThan(1),
      );
      expect(arrow, findsNothing);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
