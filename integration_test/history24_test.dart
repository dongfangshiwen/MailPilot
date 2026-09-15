import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';

import '../test/history24_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('API 36 sidebar groups menus multi selection and rename', (
    tester,
  ) async {
    final b = history24Fixture();
    final controller = MailController(b, initial: b.data);
    await controller.start();
    try {
      await tester.pumpWidget(
        MailPilotApp(controller: controller, autoStart: false),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      Future<void> capture(String name) async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump();
        await binding.takeScreenshot(name);
      }

      Future<void> waitFor(Finder finder) async {
        for (
          var attempt = 0;
          attempt < 30 && finder.evaluate().isEmpty;
          attempt++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(finder, findsOneWidget);
      }

      for (final theme in ['light', 'dark']) {
        await controller.act('theme', {'value': theme});
        await tester.pumpAndSettle();
        final scaffold = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        scaffold.openDrawer();
        await tester.pumpAndSettle();
        await capture('sidebar-$theme');
        await tester.tap(find.byTooltip('多选对话'));
        await tester.pumpAndSettle();
        expect(find.text('已选 0 个对话'), findsOneWidget);
        await tester.tap(find.byTooltip('退出多选'));
        await tester.pumpAndSettle();
        final search = find.byKey(const ValueKey('conversation-search'));
        await tester.enterText(search, '历史对话 1');
        await tester.pumpAndSettle(const Duration(milliseconds: 350));
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        await waitFor(find.byKey(const ValueKey('conversation-history-1')));
        await capture('sidebar-search-$theme');
        await tester.tap(find.byTooltip('清空搜索'));
        await tester.pumpAndSettle();
        await waitFor(find.byKey(const ValueKey('conversation-history-0')));
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final first = find.byKey(const ValueKey('conversation-history-0'));
        await tester.longPress(first);
        await tester.pumpAndSettle();
        await capture('sidebar-menu-$theme');
        await tester.tap(find.text('多选'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('conversation-history-1')));
        await tester.pumpAndSettle();
        expect(find.text('已选 2 个对话'), findsOneWidget);
        await capture('sidebar-multi-$theme');
        await tester.tap(find.byTooltip('退出多选'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('关闭侧栏'));
        await tester.pumpAndSettle();
        expect(tester.view.viewInsets.bottom, 0);
        await controller.act('tab', {'index': 3});
        await tester.pumpAndSettle();
        await capture('settings-$theme');
        expect(find.text('我的邮件'), findsOneWidget);
        await controller.act('tab', {'index': 1});
        await tester.pumpAndSettle();
      }
      expect(
        b.calls.where((e) => e == 'analyze' || e == 'confirmChatSend'),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    }
  });
}
