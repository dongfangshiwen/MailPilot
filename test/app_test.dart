import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';
import 'package:mailpilot/forms.dart';

void main() {
  Future<(MailController, PreviewBackend)> mount(
    WidgetTester tester, {
    int tab = 1,
    RowData? initial,
  }) async {
    final b = PreviewBackend(initial: initial ?? previewState(tab: tab));
    final c = MailController(b, initial: b.data);
    await c.start();
    await c.act('tab', {'index': tab});
    await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
    await tester.pumpAndSettle();
    return (c, b);
  }

  testWidgets(
    'home keeps one input and email picker without navigation clutter',
    (tester) async {
      final (_, b) = await mount(tester);
      expect(find.text('邮件里的事，一起理清。'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(b.calls.contains('analyze'), isFalse);
      await tester.tap(find.byTooltip('添加附件'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('选择邮件'));
      await tester.pumpAndSettle();
      expect(find.text('示例：项目方案与预算，请确认'), findsOneWidget);
    },
  );
  testWidgets('selecting a mail does not open or analyze it', (tester) async {
    final (_, b) = await mount(tester, tab: 0);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(b.calls.contains('toggleMessage'), isTrue);
    expect(b.calls.contains('openMessage'), isFalse);
    expect(b.calls.contains('analyze'), isFalse);
    expect(find.text('分析已选的 1 封邮件'), findsOneWidget);
  });
  testWidgets('first launch keeps the configure model button visible', (
    tester,
  ) async {
    await mount(
      tester,
      initial: {...previewState(), 'accounts': [], 'models': []},
    );
    expect(find.text('添加模型'), findsOneWidget);
    await tester.tap(find.text('添加模型'));
    await tester.pumpAndSettle();
    expect(find.text('添加模型'), findsOneWidget);
  });
  testWidgets('a final preview and explicit action are required to send', (
    tester,
  ) async {
    final (c, b) = await mount(tester);
    await c.act('reply', {'id': 'm1'});
    await tester.pumpAndSettle();
    await tester.tap(find.text('在聊天中确认发送'));
    await tester.pumpAndSettle();
    expect(b.calls.contains('confirmChatSend'), isFalse);
    expect(find.text('发件人：preview@example.test'), findsOneWidget);
    expect(find.text('收件人：lin@example.test'), findsOneWidget);
    await tester.tap(find.text('确认发送'));
    await tester.pumpAndSettle();
    expect(b.calls.where((e) => e == 'confirmChatSend').length, 1);
    expect(find.text('在聊天中确认发送'), findsNothing);
  });
  testWidgets('PDF defaults to ten pages and clearing deselects the file', (
    tester,
  ) async {
    final (c, _) = await mount(tester);
    await c.act('openMessage', {'id': 'm1'});
    await c.act('editPdf', {'id': 'a2'});
    await tester.pumpAndSettle();
    expect(find.text('确认选择 · 10 页'), findsOneWidget);
    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '取消选择此附件'),
    );
    expect(button.onPressed, isNotNull);
    await tester.tap(find.text('取消选择此附件'));
    await tester.pumpAndSettle();
    expect(
      c.data.rows('selection').expand((s) => s.strings('attachmentIds')),
      isNot(contains('a2')),
    );
  });
  testWidgets('compact screen and large text have no overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final (c, _) = await mount(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await c.act('tab', {'index': 0});
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('new account asks for essentials and folds advanced fields', (
    tester,
  ) async {
    final (c, _) = await mount(tester);
    await tester.pumpWidget(
      MaterialApp(theme: mailTheme(false), home: AccountForm(c)),
    );
    await tester.pumpAndSettle();
    expect(find.text('邮箱地址'), findsOneWidget);
    expect(find.text('授权码'), findsOneWidget);
    expect(find.text('IMAP 主机'), findsNothing);
    await tester.tap(find.text('自定义'));
    await tester.pumpAndSettle();
    expect(find.text('IMAP 主机'), findsOneWidget);
  });
}
