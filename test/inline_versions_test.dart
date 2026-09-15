import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/message_versions.dart';
import 'package:mailpilot/preview_data.dart';

class VersionBackend extends PreviewBackend {
  bool failVersions = false;
  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) {
    if (method == 'messageVersions' && failVersions) {
      throw StateError('fixture failure');
    }
    return super.invoke(method, args);
  }
}

VersionBackend fixture() {
  final b = VersionBackend();
  b.data = {
    ...b.data,
    'tab': 1,
    'conversationId': 'chat-versions',
    'selection': [],
    'entries': [
      {'id': 'q3', 'role': 'user', 'text': '第三版问题', 'versionCount': 3},
      {'id': 'a3', 'role': 'assistant', 'text': '第三版回答'},
      {'id': 'follow', 'role': 'user', 'text': '最新分支后续问题', 'canEdit': false},
      {'id': 'follow-a', 'role': 'assistant', 'text': '最新分支后续回答'},
    ],
  };
  b.messageHistory['q3'] = [
    for (var n = 1; n <= 3; n++)
      {
        'id': 'q$n',
        'text': '第$n版问题',
        'entries': [
          {'id': 'q$n', 'role': 'user', 'text': '第$n版问题'},
          {
            'id': 'a$n',
            'role': 'assistant',
            'text': '第$n版回答',
            'reasoning': {'text': '原始思考$n', 'state': 'completed'},
            'sources': [
              {
                'id': 'T$n:S1',
                'title': '资料$n',
                'location': '第 $n 页',
                'text': '来源$n',
              },
            ],
            if (n == 2)
              'draftPreview': {
                'id': 'draft',
                'subject': '历史草稿',
                'body': '历史正文',
              },
          },
        ],
      },
  ];
  return b;
}

Future<void> start(
  WidgetTester tester,
  VersionBackend b, {
  bool dark = false,
}) async {
  final c = MailController(b, initial: b.data);
  await c.start();
  await c.act('theme', {'value': dark ? 'dark' : 'light'});
  addTearDown(c.dispose);
  await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
  await tester.pumpAndSettle();
  tester.widget<ListView>(find.byType(ListView).first).controller!.jumpTo(0);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6, 2.0]) {
        testWidgets('inline versions $width $dark $scale', (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final b = fixture();
          await start(tester, b, dark: dark);
          expect(find.byTooltip('修改输入'), findsNothing);
          expect(find.text('3 / 3'), findsOneWidget);
          final pager = find.byType(MessageVersionPager);
          final theme = Theme.of(tester.element(pager));
          expect(
            tester.widget<Text>(find.text('3 / 3')).style!.color,
            theme.colorScheme.onSurfaceVariant,
          );
          await tester.tap(find.byTooltip('上一版本'));
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsNothing);
          expect(find.text('2 / 3'), findsOneWidget);
          expect(find.text('第2版问题'), findsOneWidget);
          expect(find.text('第2版回答'), findsOneWidget);
          expect(find.text('最新分支后续问题'), findsNothing);
          expect(find.text('确认发送'), findsNothing);
          expect(find.text('编辑邮件'), findsNothing);
          await tester.tap(find.byTooltip('上一版本'));
          await tester.pumpAndSettle();
          expect(find.text('1 / 3'), findsOneWidget);
          expect(find.text('第1版回答'), findsOneWidget);
          expect(
            tester
                .widget<IconButton>(
                  find.byWidgetPredicate(
                    (w) => w is IconButton && w.tooltip == '上一版本',
                  ),
                )
                .onPressed,
            isNull,
          );
          await tester.tap(find.byTooltip('下一版本'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('下一版本'));
          await tester.pumpAndSettle();
          expect(find.text('第三版问题'), findsOneWidget);
          expect(find.text('3 / 3'), findsOneWidget);
          expect(b.calls.where((e) => e == 'messageVersions'), hasLength(1));
          expect(
            b.calls.where(
              (e) =>
                  e == 'analyze' ||
                  e == 'editMessage' ||
                  e == 'confirmChatSend',
            ),
            isEmpty,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('bubble sheet, draft input retention and failed version load', (
    tester,
  ) async {
    final b = fixture();
    await start(tester, b);
    await tester.enterText(find.byType(TextField), '保留这段输入');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('user-bubble-q3')));
    await tester.pumpAndSettle();
    expect(find.text('修改输入'), findsOneWidget);
    expect(find.text('复制消息'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭消息操作'));
    await tester.pumpAndSettle();
    b.failVersions = true;
    await tester.tap(find.byTooltip('上一版本'));
    await tester.pumpAndSettle();
    expect(find.text('第三版问题'), findsOneWidget);
    expect(find.text('版本记录暂时无法读取，请重试'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    b.failVersions = false;
    await tester.tap(find.byTooltip('上一版本'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('回到最新'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '保留这段输入',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
