import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/chat_composer.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

import 'scroll23_fixture.dart';

const jumpKey = ValueKey('chat-scroll-to-latest');
const listKey = ValueKey('chat-message-list');

ScrollController chatScroll(WidgetTester tester) =>
    tester.widget<ListView>(find.byKey(listKey)).controller!;

Future<MailController> mountChat(
  WidgetTester tester,
  PreviewBackend backend,
) async {
  final c = MailController(backend, initial: backend.data);
  addTearDown(c.dispose);
  await c.start();
  await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final dark in [false, true]) {
      testWidgets('jump through variable-height history $width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = dark ? 2 : 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final b = scroll23Fixture(theme: dark ? 'dark' : 'light');
        final c = await mountChat(tester, b);
        final entries = c.data.rows('entries');
        final scroll = chatScroll(tester);
        scroll.jumpTo(0);
        await tester.pumpAndSettle();
        final composer = tester.getRect(find.byType(ChatComposer));
        expect(find.byTooltip('回到最新消息'), findsOneWidget);
        expect(tester.getSize(find.byKey(jumpKey)), const Size(48, 48));
        expect(
          tester.getRect(find.byKey(jumpKey)).bottom,
          lessThan(composer.top),
        );
        final semantics = tester.ensureSemantics();
        expect(
          tester.getSemantics(find.byKey(jumpKey)),
          matchesSemantics(label: '回到最新消息', isButton: true, hasTapAction: true),
        );
        semantics.dispose();
        await tester.tap(find.byKey(jumpKey));
        await tester.pumpAndSettle();
        expect(scroll.position.extentAfter, lessThan(1));
        expect(find.byKey(jumpKey), findsNothing);
        expect(
          find.textContaining('这是最新的回答', findRichText: true),
          findsOneWidget,
        );
        expect(tester.getRect(find.byType(ChatComposer)), composer);
        expect(c.data.rows('entries'), entries);
        expect(tester.testTextInput.isVisible, isFalse);
        expect(
          b.calls.where((v) => v == 'analyze' || v == 'confirmChatSend'),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'streaming preserves old reading position and explicit jump resumes following',
    (tester) async {
      final b = scroll23Fixture();
      final c = await mountChat(tester, b);
      final scroll = chatScroll(tester);
      scroll.jumpTo(200);
      await tester.pumpAndSettle();
      final before = scroll.offset;
      b.data = {
        ...b.data,
        'analyzing': true,
        'responseId': 'live23',
        'streaming': '正在继续回答',
      };
      b.publish();
      await tester.pump(const Duration(milliseconds: 250));
      expect(scroll.offset, closeTo(before, 1));
      expect(find.byKey(jumpKey), findsOneWidget);
      await tester.tap(find.byKey(jumpKey));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }
      expect(scroll.position.extentAfter, lessThan(1));
      b.data = {...b.data, 'streaming': '正在继续回答\n\n第二段内容已到达。'};
      b.publish();
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }
      expect(scroll.position.extentAfter, lessThan(1));
      expect(c.data.flag('analyzing'), isTrue);
      expect(find.byKey(jumpKey), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'keyboard, input and conversation changes do not leave a stale navigation button',
    (tester) async {
      final b = scroll23Fixture();
      final c = await mountChat(tester, b);
      await tester.enterText(find.byType(TextField), '保留输入，不发送');
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      chatScroll(tester).jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.byKey(jumpKey), findsOneWidget);
      await tester.tap(find.byKey(jumpKey));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '保留输入，不发送',
      );
      await c.act('newConversation');
      await tester.pumpAndSettle();
      expect(find.byKey(jumpKey), findsNothing);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('short and empty chats need no downward button', (tester) async {
    final b = PreviewBackend(initial: {...previewState(), 'selection': []});
    await mountChat(tester, b);
    expect(find.byKey(jumpKey), findsNothing);
    b.data = {
      ...b.data,
      'entries': [
        {'id': 'a', 'role': 'assistant', 'text': '简短回答'},
      ],
    };
    b.publish();
    await tester.pumpAndSettle();
    expect(find.byKey(jumpKey), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
