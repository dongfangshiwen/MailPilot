import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/common.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';
import 'package:mailpilot/mail_search_results.dart';
import 'package:mailpilot/editor.dart';

import 'scroll23_fixture.dart';

PreviewBackend resultsFixture() {
  final b = scroll23Fixture();
  final mails = [
    for (var i = 0; i < 30; i++)
      {
        'id': 'mail$i',
        'subject': '检索邮件 $i',
        'sender': '项目组',
        'preview': '需要核对的项目进度',
        'bodyText': '邮件正文 $i',
        'sentAt': 1789200000000,
      },
  ];
  b.data = {...b.data, 'messages': mails, 'resultCards': mails};
  return b;
}

Future<MailController> mountResults(
  WidgetTester tester,
  PreviewBackend b,
) async {
  final c = MailController(b, initial: b.data);
  addTearDown(c.dispose);
  await c.start();
  await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets(
    'mail picker back preserves the current chat controller and offset',
    (tester) async {
      final b = resultsFixture();
      final c = await mountResults(tester, b);
      final list = find.byKey(const ValueKey('chat-message-list'));
      final scroll = tester.widget<ListView>(list).controller!;
      scroll.jumpTo(200);
      await tester.pumpAndSettle();
      final offset = scroll.offset;
      await c.act('tab', {'index': 0, 'fromChat': true});
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.widget<ListView>(list).controller, same(scroll));
      expect(scroll.offset, closeTo(offset, .5));
    },
  );
  testWidgets('mail detail back keeps conversation viewport and input', (
    tester,
  ) async {
    final b = resultsFixture();
    final c = await mountResults(tester, b);
    final list = find.byKey(const ValueKey('chat-message-list'));
    final scroll = tester.widget<ListView>(list).controller!;
    scroll.jumpTo(200);
    await tester.enterText(find.byType(TextField), '保留未发送输入');
    await tester.pumpAndSettle();
    final offset = scroll.offset;
    await c.act('openMessage', {'id': 'mail0'});
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final returned = tester.widget<ListView>(list).controller!;
    expect(returned, same(scroll));
    expect(returned.offset, closeTo(offset, .5));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '保留未发送输入',
    );
    expect(
      b.calls.where((v) => v == 'analyze' || v == 'confirmChatSend'),
      isEmpty,
    );
  });

  testWidgets('many mail results are bounded instead of flattened into chat', (
    tester,
  ) async {
    final b = resultsFixture();
    b.data = {...b.data, 'entries': <RowData>[]};
    await mountResults(tester, b);
    expect(find.byType(MailTile).evaluate().length, lessThanOrEqualTo(2));
    expect(find.text('30 封邮件'), findsOneWidget);
    expect(find.text('检索邮件 29'), findsNothing);
  });

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      testWidgets('mail card paging and selection width=$width scale=$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final b = resultsFixture();
        b.data = {
          ...b.data,
          'entries': <RowData>[],
          'settings': {
            ...b.data.child('settings'),
            'theme': scale == 2 ? 'dark' : 'light',
          },
        };
        final c = await mountResults(tester, b);
        expect(find.byType(Checkbox), findsNWidgets(2));
        expect(
          tester
              .getSize(find.byKey(const ValueKey('mail-search-results-card')))
              .height,
          lessThan(420),
        );
        await tester.tap(
          find.byKey(const ValueKey('mail-search-results-toggle')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Checkbox), findsNWidgets(5));
        expect(find.text('1 / 6'), findsOneWidget);
        await tester.ensureVisible(find.byTooltip('下一页邮件'));
        await tester.tap(find.byTooltip('下一页邮件'));
        await tester.pumpAndSettle();
        expect(find.text('2 / 6'), findsOneWidget);
        expect(find.text('检索邮件 5'), findsOneWidget);
        expect(c.data.rows('selection'), isEmpty);
        final checkbox = find.byType(Checkbox).first;
        await tester.ensureVisible(checkbox);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
        expect(c.selected('mail5'), isTrue);
        final list = find.byKey(const ValueKey('chat-message-list'));
        final scroll = tester.widget<ListView>(list).controller!;
        await tester.ensureVisible(find.text('检索邮件 5'));
        await tester.pumpAndSettle();
        final offset = scroll.offset;
        final top = tester.getTopLeft(find.text('检索邮件 5')).dy;
        await tester.tap(find.text('检索邮件 5'));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(tester.widget<ListView>(list).controller, same(scroll));
        expect(scroll.offset, closeTo(offset, .5));
        expect(tester.getTopLeft(find.text('检索邮件 5')).dy, closeTo(top, .5));
        expect(find.text('2 / 6'), findsOneWidget);
        expect(c.selected('mail5'), isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets(
    'stream updates while a mail is open do not pull the return view down',
    (tester) async {
      final b = resultsFixture();
      final c = await mountResults(tester, b);
      final list = find.byKey(const ValueKey('chat-message-list'));
      final scroll = tester.widget<ListView>(list).controller!;
      scroll.jumpTo(200);
      await tester.pumpAndSettle();
      final offset = scroll.offset;
      await c.act('openMessage', {'id': 'mail0'});
      await tester.pumpAndSettle();
      b.data = {
        ...b.data,
        'analyzing': true,
        'responseId': 'live42',
        'streaming': List.filled(25, '新的回答内容').join('\n\n'),
      };
      b.publish();
      await tester.pump(const Duration(milliseconds: 400));
      await c.back();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }
      expect(scroll.offset, closeTo(offset, .5));
      b.data = {
        ...b.data,
        'streaming': '${b.data.text('streaming')}\n\n还有新的内容',
      };
      b.publish();
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }
      expect(scroll.offset, closeTo(offset, .5));
      await tester.tap(find.byKey(const ValueKey('chat-scroll-to-latest')));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }
      expect(scroll.position.extentAfter, lessThan(1));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'new results and scope changes preserve isolation and reset paging',
    (tester) async {
      final b = resultsFixture();
      b.data = {...b.data, 'entries': <RowData>[]};
      await mountResults(tester, b);
      await tester.tap(
        find.byKey(const ValueKey('mail-search-results-toggle')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('下一页邮件'));
      await tester.tap(find.byTooltip('下一页邮件'));
      await tester.pumpAndSettle();
      b.data = {
        ...b.data,
        'resultCards': b.data.rows('resultCards').take(3).toList(),
      };
      b.publish();
      await tester.pumpAndSettle();
      expect(find.text('1 / 1'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(3));
      b.data = {
        ...b.data,
        'conversationId': 'another',
        'resultCards': resultsFixture().data.rows('resultCards'),
      };
      b.publish();
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsNWidgets(2));
      expect(find.text('1 / 6'), findsNothing);
      expect(find.byType(MailSearchResults), findsOneWidget);
    },
  );

  testWidgets('hidden draft does not handle the source page back gesture', (
    tester,
  ) async {
    final b = resultsFixture();
    final c = await mountResults(tester, b);
    await c.act('newDraft');
    await tester.pumpAndSettle();
    final editor = tester.state(find.byType(DraftPage));
    await c.act('showSource', {
      'source': {'id': 'T1:S1', 'kind': 'answer', 'title': '引用', 'text': '资料'},
    });
    await tester.pumpAndSettle();
    final before = b.calls.length;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(DraftPage)), same(editor));
    expect(b.calls.skip(before), isNot(contains('back')));
    expect(find.text('放弃未保存的修改？'), findsNothing);
  });
}
