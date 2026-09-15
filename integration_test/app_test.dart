import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';
import 'package:mailpilot/forms.dart';
import 'package:mailpilot/service_form.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Future<void> capture(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump();
    await binding.takeScreenshot(name);
  }

  Future<void> until(WidgetTester tester, bool Function() ready) async {
    for (var i = 0; i < 80 && !ready(); i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(ready(), isTrue);
  }

  testWidgets('Android channel and encrypted model configuration round trip', (
    tester,
  ) async {
    final c = MailController(AndroidBackend());
    await tester.pumpWidget(MailPilotApp(controller: c));
    await until(tester, () => c.data.flag('ready'));
    expect(c.failure, isNull);
    final converted = await c.request('plainMailBody', {
      'body': '# 邮件\n\n您好，**已收到**。',
    });
    expect(converted, '邮件\n\n您好，已收到。');
    await c.act('tab', {'index': 3});
    await until(tester, () => c.data.number('tab') == 3);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('返回主页'));
    await until(tester, () => c.data.number('tab') == 1);
    await c.act('tab', {'index': 3});
    await until(tester, () => c.data.number('tab') == 3);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await until(tester, () => c.data.number('tab') == 1);
    expect(
      c.data
          .rows('modelCatalog')
          .any((m) => m.text('model') == 'doubao-seed-evolving'),
      isTrue,
    );
    final originalText = c.settings.text('textModelId');
    final label = 'integration-${DateTime.now().microsecondsSinceEpoch}';
    const secret = 'test-only-never-a-real-api-key';
    String? createdId;
    try {
      await c.request('saveModel', {
        'label': label,
        'baseUrl': 'https://unused.invalid/v1',
        'model': 'test-fixture',
        'contextTokens': 8192,
        'outputTokens': 512,
        'secret': secret,
        'provider': 'deepseek',
        'thinkingMode': 'enabled',
        'reasoningEffort': 'max',
      });
      await until(tester, () => c.models.any((m) => m.text('label') == label));
      final saved = c.models.singleWhere((m) => m.text('label') == label);
      createdId = saved.text('id');
      expect(saved.flag('hasSecret'), isTrue);
      expect(saved.text('thinkingMode'), 'enabled');
      expect(saved.text('reasoningEffort'), 'max');
      expect(saved.containsKey('apiKeyCipher'), isFalse);
      expect(jsonEncode(c.data).contains(secret), isFalse);
      await c.request('saveModel', {
        ...saved,
        'baseUrl': 'https://ark.cn-beijing.volces.com/api/v3',
        'provider': 'volcengine',
        'model': 'doubao-seed-evolving',
        'thinkingMode': 'default',
        'reasoningEffort': '',
        'secret': '',
      });
      await until(
        tester,
        () => c.models.any(
          (m) =>
              m.text('id') == createdId &&
              m.text('model') == 'doubao-seed-evolving',
        ),
      );
      expect(
        c.models
            .firstWhere((m) => m.text('id') == createdId)
            .child('capability')
            .text('vision'),
        'supported',
      );
      expect(
        c.models
            .firstWhere((m) => m.text('id') == createdId)
            .flag('textVerified'),
        isFalse,
      );
      await c.request('saveModel', {
        ...saved,
        'label': '$label-edited',
        'secret': '',
      });
      await until(
        tester,
        () => c.models.any((m) => m.text('label') == '$label-edited'),
      );
      expect(
        c.models
            .singleWhere((m) => m.text('id') == createdId)
            .flag('hasSecret'),
        isTrue,
      );
      expect(
        c.models
            .singleWhere((m) => m.text('id') == createdId)
            .text('reasoningEffort'),
        'max',
      );
    } finally {
      if (createdId != null) {
        await c.request('deleteModel', {'id': createdId});
        await until(
          tester,
          () => !c.models.any((m) => m.text('id') == createdId),
        );
      }
      await c.request('defaultModel', {'id': originalText, 'vision': false});
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });

  testWidgets('1.8 service drawer preserves options and captures both themes', (
    tester,
  ) async {
    final backend = PreviewBackend();
    final c = MailController(backend, initial: backend.data);
    await c.start();
    await tester.pumpWidget(
      MailPilotApp(controller: c, autoStart: false, preview: true),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await capture(tester, 'flutter-180-composer-light-fixture');
    for (final theme in ['light', 'dark']) {
      await c.act('theme', {'value': theme});
      await tester.pumpAndSettle();
      showServiceSheet(tester.element(find.byType(TextField).first), c);
      await tester.pumpAndSettle();
      await capture(tester, 'flutter-180-search-$theme-fixture');
      await tester.tap(find.text('搜索服务商'));
      await tester.pumpAndSettle();
      await capture(tester, 'flutter-180-provider-$theme-fixture');
      await tester.tap(find.text('返回配置'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '语音输入'));
      await tester.pumpAndSettle();
      await capture(tester, 'flutter-180-speech-$theme-fixture');
      await tester.tap(find.byTooltip('关闭配置'));
      await tester.pumpAndSettle();
    }
    await capture(tester, 'flutter-180-composer-dark-fixture');
    expect(backend.calls, isNot(contains('testService')));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Thinking stream collapses and draft save floats on phone', (
    tester,
  ) async {
    final backend = PreviewBackend(simulateReasoning: true);
    final c = MailController(backend, initial: backend.data);
    await c.start();
    await tester.pumpWidget(
      MailPilotApp(controller: c, autoStart: false, preview: true),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '请分析邮件并帮我起草回复');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('发送问题'));
    await until(
      tester,
      () => c.data.child('reasoning').text('text').length > 20,
    );
    await tester.pump();
    await capture(tester, 'flutter-thinking-active-fixture');
    await until(tester, () => c.data.text('streaming').isNotEmpty);
    await tester.pump();
    expect(find.textContaining('已思考'), findsOneWidget);
    await capture(tester, 'flutter-thinking-collapsed-fixture');
    await until(tester, () => !c.data.flag('analyzing'));
    await tester.pumpAndSettle();
    final heading = find.textContaining('已思考');
    await tester.ensureVisible(heading);
    await tester.pumpAndSettle();
    await tester.tap(heading);
    await tester.pumpAndSettle();
    await capture(tester, 'flutter-thinking-reopened-fixture');
    await tester.ensureVisible(find.text('写成邮件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('写成邮件'));
    await tester.pumpAndSettle();
    await capture(tester, 'flutter-recipient-needed-fixture');
    await tester.ensureVisible(find.text('编辑邮件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑邮件'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '收件人'),
      'other@example.test',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    await capture(tester, 'flutter-draft-toast-fixture');
    await tester.tap(find.text('在聊天中确认发送'));
    await tester.pumpAndSettle();
    await until(
      tester,
      () => find.text('收件人：other@example.test').evaluate().isNotEmpty,
    );
    expect(find.text('收件人：other@example.test'), findsOneWidget);
    expect(backend.calls, isNot(contains('confirmChatSend')));
    await capture(tester, 'flutter-draft-confirm-fixture');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Flutter phone workflow with explicitly labelled fixtures', (
    tester,
  ) async {
    final backend = PreviewBackend();
    final c = MailController(backend, initial: backend.data);
    await c.start();
    await tester.pumpWidget(
      MailPilotApp(controller: c, autoStart: false, preview: true),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await capture(tester, 'flutter-home-fixture');
    await tester.tap(find.byTooltip('添加附件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择邮件'));
    await tester.pumpAndSettle();
    await capture(tester, 'flutter-inbox-fixture');
    await tester.tap(find.text('收件箱 ▾'));
    await tester.pumpAndSettle();
    expect(find.text('已发送'), findsOneWidget);
    await capture(tester, 'flutter-folders-fixture');
    await tester.tap(find.text('收件箱').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(backend.calls.contains('analyze'), isFalse);
    expect(backend.calls.contains('openMessage'), isFalse);
    await tester.tap(find.text('分析已选的 1 封邮件'));
    await tester.pumpAndSettle();
    expect(c.data.number('tab'), 1);
    await c.act('openMessage', {'id': 'm1'});
    await tester.pumpAndSettle();
    await capture(tester, 'flutter-detail-fixture');
    await c.act('editPdf', {'id': 'a2'});
    await tester.pumpAndSettle();
    expect(find.text('确认选择 · 10 页'), findsOneWidget);
    await capture(tester, 'flutter-pdf-fixture');
    await c.act('dismissPdf');
    await c.act('reply', {'id': 'm1'});
    await tester.pumpAndSettle();
    await capture(tester, 'flutter-draft-fixture');
    await tester.tap(find.text('在聊天中确认发送'));
    await tester.pumpAndSettle();
    expect(backend.calls.contains('confirmChatSend'), isFalse);
    expect(find.text('收件人：lin@example.test'), findsOneWidget);
    await capture(tester, 'flutter-confirm-fixture');
    await c.act('dismissSend');
    await c.act('back');
    await c.act('tab', {'index': 3});
    await tester.pumpAndSettle();
    await capture(tester, 'flutter-settings-fixture');
    await tester.tap(find.text('添加邮箱'));
    await tester.pumpAndSettle();
    await capture(tester, 'flutter-account-fixture');
    const mailboxLabels = ['QQ 邮箱', '163 邮箱', '阿里企业邮箱', '阿里个人邮箱', '自定义'];
    final mailboxPositions = {
      for (final label in mailboxLabels)
        label: tester.getRect(find.widgetWithText(ChoiceChip, label)),
    };
    for (final label in mailboxLabels.reversed) {
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pump(const Duration(milliseconds: 75));
      for (final entry in mailboxPositions.entries) {
        expect(
          tester.getRect(find.widgetWithText(ChoiceChip, entry.key)),
          entry.value,
        );
      }
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('阿里企业邮箱'));
    await tester.pumpAndSettle();
    expect(find.text('密码／安全密码'), findsOneWidget);
    await capture(tester, 'flutter-alibaba-fixture');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('返回主页'));
    await tester.pumpAndSettle();
    expect(c.data.number('tab'), 1);
    await tester.enterText(find.byType(TextField), '总结这封邮件的待办');
    await tester.pump();
    await tester.tap(find.byTooltip('发送问题'));
    await until(
      tester,
      () =>
          c.data.text('streaming').length >= 48 &&
          tester.view.viewInsets.bottom == 0 &&
          find.byKey(const ValueKey('streaming-reply')).evaluate().isNotEmpty,
    );
    // Allow the keyboard resize and scroll animation to paint before capture.
    await tester.pump(const Duration(milliseconds: 250));
    expect(c.data.flag('analyzing'), isTrue);
    expect(c.data.text('streaming'), isNotEmpty);
    expect(find.byKey(const ValueKey('streaming-reply')), findsOneWidget);
    await capture(tester, 'flutter-streaming-fixture');
    await until(tester, () => !c.data.flag('analyzing'));
    await tester.pumpAndSettle();
    expect(
      c.data.rows('entries').last.text('text'),
      PreviewBackend.sampleReply,
    );
    await capture(tester, 'flutter-markdown-fixture');
    Navigator.of(tester.element(find.byType(TextField))).push(
      MaterialPageRoute<void>(
        builder: (_) => ModelForm(
          c,
          initial: const {
            'label': '思考模型 · 示例',
            'baseUrl': 'https://api.deepseek.com',
            'model': 'deepseek-v4-pro',
            'provider': 'deepseek',
            'thinkingMode': 'enabled',
            'reasoningEffort': 'high',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('高级参数'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('高级参数'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('思考模式'));
    await tester.pumpAndSettle();
    await capture(tester, 'flutter-thinking-fixture');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await c.act('theme', {'value': 'dark'});
    await c.act('tab', {'index': 1});
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(TextField).first)).brightness,
      Brightness.dark,
    );
    await capture(tester, 'flutter-dark-fixture');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('continuous selection, asynchronous sync and redraft controls', (
    tester,
  ) async {
    final backend = PreviewBackend();
    final c = MailController(backend, initial: backend.data);
    await c.start();
    await tester.pumpWidget(
      MailPilotApp(controller: c, autoStart: false, preview: true),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    backend.data = {
      ...backend.data,
      'entries': [
        {
          'id': 'previous-analysis',
          'role': 'assistant',
          'text': '【界面样例】之前邮件的会议时间是周五，换选资料后仍可继续讨论。',
        },
      ],
    };
    backend.publish();
    await c.act('toggleMessage', {'id': 'm1'});
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('清空选择'));
    await tester.pumpAndSettle();
    expect(c.data.rows('entries').single.text('id'), 'previous-analysis');
    await c.act('toggleMessage', {'id': 'm1'});
    await tester.pumpAndSettle();
    await capture(tester, 'flutter-continuous-chat-fixture');
    await c.act('tab', {'index': 0});
    await c.act('refresh');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.busy, isFalse);
    await tester.tap(find.text('收件箱 ▾'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await capture(tester, 'flutter-sync-folders-fixture');
    await tester.tap(find.text('已发送'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.data.text('folder'), 'Sent');
    expect(c.data.flag('syncing'), isTrue);
    await c.act('cancelSync');
    await tester.pumpAndSettle();
    await c.act('dismissNotice', {'notice': c.data.text('notice')});
    await tester.pumpAndSettle();
    await c.act('reply', {'id': 'm1'});
    await tester.pumpAndSettle();
    await c.act('reviewDraftInChat', c.data.child('editor'));
    await tester.pumpAndSettle();
    final old = c.data.rows('drafts').single;
    await c.act('tab', {'index': 2});
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('草稿操作'));
    await tester.pumpAndSettle();
    await capture(tester, 'flutter-draft-actions-fixture');
    await tester.tap(find.text('重新拟写'));
    await tester.pumpAndSettle();
    expect(c.data.rows('drafts').single['to'], old['to']);
    expect(
      c.data.rows('drafts').single.number('revision'),
      old.number('revision') + 1,
    );
    await c.act('clearSelection');
    await tester.pumpAndSettle();
    await capture(tester, 'flutter-redraft-card-fixture');
    expect(backend.calls, isNot(contains('confirmChatSend')));
    await c.act('tab', {'index': 2});
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('草稿操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除草稿'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(c.data.rows('drafts'), isEmpty);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
    'standalone chat and inspectable summary without mailbox fixtures',
    (tester) async {
      final backend = PreviewBackend(
        initial: {
          ...previewState(),
          'accounts': [],
          'activeAccount': '',
          'messages': [],
        },
      );
      final c = MailController(backend, initial: backend.data);
      await c.start();
      await tester.pumpWidget(
        MailPilotApp(controller: c, autoStart: false, preview: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('有什么想聊的？'), findsOneWidget);
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await capture(tester, 'flutter-general-chat-home-fixture');
      await tester.enterText(find.byType(TextField), '帮我整理学习计划');
      await tester.pump();
      await tester.tap(find.byTooltip('发送问题'));
      await until(tester, () => c.data.rows('entries').isNotEmpty);
      expect(backend.calls.contains('analyze'), isTrue);
      await until(tester, () => !c.data.flag('analyzing'));
      await tester.pumpAndSettle();
      expect(c.data.rows('entries').last.text('text'), contains('邮箱是可选功能'));
      expect(find.text('写成邮件'), findsNothing);
      await capture(tester, 'flutter-general-chat-reply-fixture');
      backend.data = {
        ...backend.data,
        'contextSummary': '【界面样例】用户希望制定学习计划，使用中文，每天留出一小时。尚待确认学习主题。',
        'summarizedEntries': 12,
      };
      backend.publish();
      await tester.pumpAndSettle();
      expect(find.text('已整理 12 条早期消息'), findsNothing);
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('对话摘要'));
      await tester.pumpAndSettle();
      await capture(tester, 'flutter-context-summary-fixture');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
