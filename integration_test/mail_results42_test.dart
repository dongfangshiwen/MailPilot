import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';

import '../test/chat_results42_test.dart' show resultsFixture;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('mail result bundle and detail return on API36', (tester) async {
    final b = resultsFixture();
    b.data = {
      ...b.data,
      'entries': [
        {'id': 'q42', 'role': 'user', 'text': '搜索最近的项目进展邮件'},
        {
          'id': 'a42',
          'role': 'assistant',
          'text': '找到 30 封相关邮件。可以打开查看，或选择要继续分析的邮件。',
        },
      ],
    };
    final c = MailController(b, initial: b.data);
    await c.start();
    try {
      await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      final list = find.byKey(const ValueKey('chat-message-list'));
      final scroll = tester.widget<ListView>(list).controller!;
      for (final dark in [false, true]) {
        await c.act('theme', {'value': dark ? 'dark' : 'light'});
        await tester.pumpAndSettle();
        expect(find.byType(Checkbox), findsNWidgets(2));
        await tester.ensureVisible(
          find.byKey(const ValueKey('mail-search-results-toggle')),
        );
        await tester.pumpAndSettle();
        await binding.takeScreenshot(
          'mail-results-collapsed-${dark ? 'dark' : 'light'}',
        );
        await tester.tap(
          find.byKey(const ValueKey('mail-search-results-toggle')),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('下一页邮件'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('下一页邮件'));
        await tester.pumpAndSettle();
        expect(find.text('2 / 6'), findsOneWidget);
        expect(find.byType(Checkbox), findsNWidgets(5));
        await tester.ensureVisible(find.text('检索邮件 5'));
        await tester.pumpAndSettle();
        final offset = scroll.offset;
        final y = tester.getTopLeft(find.text('检索邮件 5')).dy;
        await binding.takeScreenshot(
          'mail-results-expanded-${dark ? 'dark' : 'light'}',
        );
        await tester.tap(find.text('检索邮件 5'));
        await tester.pumpAndSettle();
        expect(c.data.child('detail').text('id'), 'mail5');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(tester.widget<ListView>(list).controller, same(scroll));
        expect(scroll.offset, closeTo(offset, .5));
        expect(tester.getTopLeft(find.text('检索邮件 5')).dy, closeTo(y, .5));
        expect(find.text('2 / 6'), findsOneWidget);
        await c.act('tab', {'index': 0, 'fromChat': true});
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(tester.widget<ListView>(list).controller, same(scroll));
        expect(scroll.offset, closeTo(offset, .5));
        await tester.ensureVisible(find.text('收起'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('收起'));
        await tester.pumpAndSettle();
        expect(find.byType(Checkbox), findsNWidgets(2));
        // Reset only the card's UI scope for the next theme scenario.
        b.data = {...b.data, 'responseId': 'theme-${dark ? 'done' : 'next'}'};
        b.publish();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(
        b.calls.where((v) => v == 'analyze' || v == 'confirmChatSend'),
        isEmpty,
      );
    } finally {
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });
}
