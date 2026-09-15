import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/screens.dart';

import 'history24_fixture.dart';

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('settings navigation and scroll $width $scale $dark', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 850);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final b = history24Fixture();
          b.data['tab'] = 3;
          final c = MailController(b, initial: b.data);
          await c.start();
          await c.act('tab', {'index': 3});
          await c.act('theme', {'value': dark ? 'dark' : 'light'});
          await tester.pumpWidget(
            MailPilotApp(controller: c, autoStart: false),
          );
          await tester.pumpAndSettle();
          expect(find.text('我的邮件'), findsOneWidget);
          final list = find.byKey(const PageStorageKey('settings-list'));
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('app-version-footer')),
            200,
            scrollable: find.descendant(
              of: list,
              matching: find.byType(Scrollable),
            ),
          );
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('后台同步'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('后台同步'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('每天一次'));
          await tester.pumpAndSettle();
          expect(c.settings.number('syncMinutes'), 1440);
          tester
              .state<ScrollableState>(
                find.descendant(of: list, matching: find.byType(Scrollable)),
              )
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
          await tester.tap(find.text('我的邮件'));
          await tester.pumpAndSettle();
          expect(find.byType(Inbox), findsOneWidget);
          await tester.tap(find.byTooltip('返回设置'));
          await tester.pumpAndSettle();
          expect(c.data.number('tab'), 3);
          await tester.tap(find.text('草稿与发送'));
          await tester.pumpAndSettle();
          expect(find.byType(DraftList), findsOneWidget);
          expect(find.byTooltip('返回设置'), findsOneWidget);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(c.data.number('tab'), 3);
          await tester.tap(find.byTooltip('返回主页'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('打开菜单'));
          await tester.pumpAndSettle();
          expect(find.text('AI 助手'), findsNothing);
          expect(find.text('我的邮件'), findsNothing);
          expect(find.text('草稿与发送'), findsNothing);
          expect(find.text('设置'), findsOneWidget);
          expect(
            b.calls.where((x) => x == 'analyze' || x == 'confirmChatSend'),
            isEmpty,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        });
      }
    }
  }
}
