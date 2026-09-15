import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('API 36 edit panel, cancel, resend and read-only versions', (
    tester,
  ) async {
    final b = PreviewBackend();
    b.data = {
      ...b.data,
      'tab': 1,
      'entries': [
        {
          'id': 'q1',
          'role': 'user',
          'text': '帮我回复对方，确认周五参加会议。',
          'canEdit': true,
        },
        {'id': 'a1', 'role': 'assistant', 'text': '已准备回复。你可以补充会议时间，或调整邮件措辞。'},
      ],
      'selection': [],
    };
    final c = MailController(b, initial: b.data);
    await c.start();
    try {
      await tester.pumpWidget(
        MailPilotApp(controller: c, autoStart: false, preview: true),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('chat102-bubble-actions');
      await tester.enterText(find.byType(TextField).first, '尚未发送的内容');
      await tester.tap(find.byKey(const ValueKey('user-bubble-q1')));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('chat102-message-sheet');
      await tester.tap(find.text('修改输入'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('chat102-edit-keyboard-light');
      await tester.enterText(find.byType(TextField).first, '请用英文回复，确认参加周五的会议。');
      await c.act('theme', {'value': 'dark'});
      await tester.pumpAndSettle();
      await binding.takeScreenshot('chat102-edit-keyboard-dark');
      await tester.tap(find.byTooltip('取消修改'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '尚未发送的内容',
      );
      expect(b.calls.where((e) => e == 'editMessage'), isEmpty);
      await c.act('theme', {'value': 'light'});
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('user-bubble-q1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('修改输入'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '请用英文回复，确认参加周五的会议。');
      await tester.tap(find.byTooltip('发送问题'));
      await tester.pump();
      for (var i = 0; i < 150 && b.data.flag('analyzing'); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(b.calls.where((e) => e == 'editMessage'), hasLength(1));
      tester
          .widget<ListView>(find.byType(ListView).first)
          .controller!
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
      await binding.takeScreenshot('chat102-inline-latest');
      final second = b.data
          .rows('entries')
          .firstWhere((e) => e.text('role') == 'user');
      await tester.ensureVisible(
        find.byKey(ValueKey('user-bubble-${second.text('id')}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('user-bubble-${second.text('id')}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('修改输入'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '请简洁地回复，确认参加周五会议。');
      await tester.tap(find.byTooltip('发送问题'));
      await tester.pump();
      for (var i = 0; i < 150 && b.data.flag('analyzing'); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      tester
          .widget<ListView>(find.byType(ListView).first)
          .controller!
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
      await binding.takeScreenshot('chat102-inline-third');
      await tester.tap(find.byTooltip('上一版本'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      await binding.takeScreenshot('chat102-inline-second');

      await tester.tap(find.byTooltip('上一版本'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text('帮我回复对方，确认周五参加会议。'), findsOneWidget);
      await binding.takeScreenshot('chat102-history-version');
      await tester.tap(find.text('回到最新'));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '尚未发送的内容',
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    }
  });
}
