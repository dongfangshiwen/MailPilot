import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart' as app;
import 'package:mailpilot/markdown_reply.dart';
import 'package:mailpilot/preview_data.dart';

class MissingNativeBackend extends MailBackend {
  int subscriptions = 0;
  final calls = <String>[];
  @override
  Stream<RowData> get states {
    subscriptions++;
    return const Stream.empty();
  }

  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) async {
    calls.add(method);
    throw MissingPluginException('snapshot');
  }
}

void main() {
  Future<(MailController, PreviewBackend)> mount(WidgetTester tester) async {
    final backend = PreviewBackend();
    final c = MailController(backend, initial: backend.data);
    await c.start();
    await tester.pumpWidget(app.MailPilotApp(controller: c, autoStart: false));
    await tester.pumpAndSettle();
    addTearDown(c.dispose);
    return (c, backend);
  }

  testWidgets(
    'desktop production entry selects labelled preview without native calls',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      app.main();
      await tester.pumpAndSettle();
      expect(find.textContaining('界面预览 · 使用样例数据'), findsOneWidget);
      expect(find.textContaining('MissingPluginException'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );

  test(
    'missing channel is localized and does not subscribe or retry on dismissal',
    () async {
      final b = MissingNativeBackend();
      final c = MailController(b);
      await c.start();
      expect(c.failure, contains('Android 邮件服务'));
      expect(c.failure, isNot(contains('MissingPluginException')));
      expect(b.subscriptions, 0);
      c.clearError();
      expect(c.failure, isNull);
      expect(b.calls, ['snapshot']);
      c.dispose();
    },
  );

  testWidgets('settings has a home button and system back returns home', (
    tester,
  ) async {
    final (c, _) = await mount(tester);
    await c.act('tab', {'index': 3});
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('返回主页'));
    await tester.pumpAndSettle();
    expect(c.data.number('tab'), 1);
    await c.act('tab', {'index': 3});
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(c.data.number('tab'), 1);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets(
    'renders partial Markdown before completion and stop preserves it',
    (tester) async {
      final (c, b) = await mount(tester);
      await tester.enterText(find.byType(TextField), '总结邮件');
      await tester.pump();
      await tester.tap(find.byTooltip('发送问题'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.data.flag('analyzing'), isTrue);
      final partial = c.data.text('streaming');
      expect(partial, isNotEmpty);
      expect(partial.length, lessThan(PreviewBackend.sampleReply.length));
      expect(find.byKey(const ValueKey('streaming-reply')), findsOneWidget);
      expect(find.byType(MarkdownBody), findsOneWidget);
      await tester.tap(find.byTooltip('停止回答'));
      await tester.pumpAndSettle();
      expect(b.calls, contains('cancelAnalysis'));
      expect(c.data.flag('analyzing'), isFalse);
      expect(c.data.rows('entries').last.text('text'), startsWith(partial));
      expect(c.data.rows('entries').last.text('text'), contains('已停止'));
      expect(b.calls, isNot(contains('sendConfirmed')));
    },
  );

  testWidgets(
    'Markdown tables code images and source links are safe at large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final (c, b) = await mount(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: app.mailTheme(false),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: MarkdownReply(
                  controller: c,
                  text:
                      '## 摘要\n\n**重点** [S1]\n\n'
                      '![不加载外部图片](https://tracker.invalid/pixel)\n\n'
                      '| 项目 | 金额 | 备注 |\n| --- | --- | --- |\n| 项目预算 | 12000 | 需要确认 |\n\n'
                      '```dart\nfinal longVariable = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz";\n```',
                  sources: const [
                    {
                      'id': 'S1',
                      'title': '已选邮件',
                      'location': '段 1',
                      'text': '正文',
                    },
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Table), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.text('[图片：不加载外部图片]'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final sourceLink = find.textContaining('[S1]', findRichText: true);
      final rich = tester.widget<RichText>(sourceLink.last);
      void tapSource(InlineSpan span) {
        if (span is TextSpan) {
          if (span.text == '[S1]') (span.recognizer as dynamic).onTap();
          for (final child in span.children ?? <InlineSpan>[]) {
            tapSource(child);
          }
        }
      }

      tapSource(rich.text);
      await tester.pumpAndSettle();
      expect(b.calls, contains('showSource'));
      expect(c.data.child('source').text('id'), 'S1');
    },
  );

  testWidgets('stream finishes without duplicated content and can be copied', (
    tester,
  ) async {
    final (c, _) = await mount(tester);
    await c.act('analyze', {'question': '总结邮件'});
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(c.data.text('streaming'), isEmpty);
    expect(
      c.data.rows('entries').where((e) => e.text('role') == 'assistant').length,
      1,
    );
    expect(
      c.data.rows('entries').last.text('text'),
      PreviewBackend.sampleReply,
    );
    expect(find.byKey(const ValueKey('streaming-reply')), findsNothing);
    // ensureVisible awaits scroll animations; pump fake time while it runs.
    final scroll = tester.ensureVisible(find.byTooltip('复制回答'));
    await tester.pumpAndSettle();
    await scroll;
    await tester.tap(find.byTooltip('复制回答'));
    await tester.pumpAndSettle();
    expect(find.text('已复制 Markdown 原文'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
