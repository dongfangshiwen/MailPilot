import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/forms.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

class AccountRecordingBackend extends PreviewBackend {
  RowData? tested;
  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) async {
    if (method == 'testAccount') {
      tested = {...args};
      return '本地测试已记录配置';
    }
    return super.invoke(method, args);
  }
}

void main() {
  Finder formScroll() => find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;
  testWidgets('mail provider selection keeps chip and email positions stable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final b = AccountRecordingBackend();
    final c = MailController(b);
    addTearDown(c.dispose);
    const labels = ['QQ 邮箱', '163 邮箱', '阿里企业邮箱', '阿里个人邮箱', '自定义'];
    for (final width in [320.0, 360.0, 393.0, 430.0]) {
      for (final scale in [1.0, 1.6, 2.0]) {
        tester.view.physicalSize = Size(width, 1600);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('$width-$scale'),
            theme: mailTheme(false),
            home: AccountForm(c),
          ),
        );
        await tester.pumpAndSettle();
        final positions = {
          for (final label in labels)
            label: tester.getRect(find.widgetWithText(ChoiceChip, label)),
        };
        final emailPosition = tester.getRect(
          find.widgetWithText(TextField, '邮箱地址'),
        );
        for (final label in [...labels.skip(1), labels.first]) {
          await tester.tap(find.widgetWithText(ChoiceChip, label));
          for (final duration in [
            Duration.zero,
            const Duration(milliseconds: 75),
            const Duration(milliseconds: 150),
          ]) {
            await tester.pump(duration);
            for (final entry in positions.entries) {
              expect(
                tester.getRect(find.widgetWithText(ChoiceChip, entry.key)),
                entry.value,
                reason:
                    '$width dp / scale $scale: ${entry.key} moved when selecting $label',
              );
            }
            expect(
              tester.getRect(find.widgetWithText(TextField, '邮箱地址')),
              emailPosition,
            );
          }
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
                .selected,
            isTrue,
          );
          expect(tester.takeException(), isNull);
        }
      }
    }
  });
  testWidgets(
    'Alibaba presets submit SSL servers and preserve typed credentials',
    (tester) async {
      final b = AccountRecordingBackend();
      final c = MailController(b);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(theme: mailTheme(false), home: AccountForm(c)),
      );
      await tester.enterText(
        find.byType(TextField).at(0),
        'member@example.test',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'synthetic-client-password',
      );
      for (final preset in [
        ('阿里企业邮箱', 'imap.qiye.aliyun.com', 'smtp.qiye.aliyun.com'),
        ('阿里个人邮箱', 'imap.aliyun.com', 'smtp.aliyun.com'),
      ]) {
        await tester.scrollUntilVisible(
          find.text(preset.$1),
          -250,
          scrollable: formScroll(),
        );
        await tester.tap(find.text(preset.$1));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('测试连接'),
          250,
          scrollable: formScroll(),
        );
        await tester.ensureVisible(find.text('测试连接'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('测试连接'));
        await tester.pumpAndSettle();
        expect(b.tested?['imapHost'], preset.$2);
        expect(b.tested?['smtpHost'], preset.$3);
        expect(b.tested?['imapPort'], 993);
        expect(b.tested?['smtpPort'], 465);
        expect(b.tested?['imapSecurity'], 'SSL');
        expect(b.tested?['smtpSecurity'], 'SSL');
        expect(b.tested?['email'], 'member@example.test');
        expect(b.tested?['secret'], 'synthetic-client-password');
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'existing Alibaba config is recognised on narrow large-text screens',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final b = AccountRecordingBackend();
      final c = MailController(b);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: mailTheme(false),
          home: AccountForm(
            c,
            initial: const {
              'id': 'existing',
              'email': 'member@example.test',
              'hasSecret': true,
              'imapHost': 'imap.qiye.aliyun.com',
              'smtpHost': 'smtp.qiye.aliyun.com',
              'imapPort': 993,
              'smtpPort': 465,
              'imapSecurity': 'SSL',
              'smtpSecurity': 'SSL',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '阿里企业邮箱'))
            .selected,
        isTrue,
      );
      expect(find.textContaining('管理员需允许第三方客户端'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('测试连接'),
        250,
        scrollable: formScroll(),
      );
      await tester.ensureVisible(find.text('测试连接'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('测试连接'));
      await tester.pumpAndSettle();
      expect(b.tested?['id'], 'existing');
      expect(b.tested?['secret'], '');
      expect(b.tested?['imapHost'], 'imap.qiye.aliyun.com');
      expect(tester.takeException(), isNull);
    },
  );
}
