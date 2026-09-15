import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/reasoning_panel.dart';
import 'package:mailpilot/screens.dart';
import 'package:mailpilot/stream_state_decoder.dart';
import 'package:mailpilot/stream_text.dart';

import 'scroll23_fixture.dart';

void main() {
  testWidgets('reasoning follows smoothly and respects manual reading', (
    tester,
  ) async {
    var text = List.filled(40, '核对每一项资料。\n').join();
    Future<void> show() => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReasoningPanel(
            reasoning: {'text': text, 'state': 'thinking', 'elapsedMs': 100},
          ),
        ),
      ),
    );
    await show();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final area = find.descendant(
      of: find.byType(ReasoningPanel),
      matching: find.byType(SingleChildScrollView),
    );
    final scroll = tester.widget<SingleChildScrollView>(area).controller!;
    final before = scroll.offset;
    text += List.filled(8, '新增的真实思考片段。\n').join();
    await show();
    expect(scroll.offset, closeTo(before, .6));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(scroll.offset, lessThan(scroll.position.maxScrollExtent));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(scroll.position.extentAfter, lessThan(1));
    await tester.drag(area, const Offset(0, 140));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final reading = scroll.offset;
    expect(scroll.position.extentAfter, greaterThan(50));
    text += '用户向上阅读时，新增内容不应改变阅读位置。\n';
    await show();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(scroll.offset, closeTo(reading, 1));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  final initial = <String, dynamic>{
    'activeAccount': 'a',
    'conversationId': 'c',
    'responseId': 'r',
    'entries': [
      {'id': 'old', 'text': '历史资料'},
    ],
    'streaming': '',
    'reasoning': {'text': '核对😀', 'state': 'thinking'},
  };
  Map<String, dynamic> patch(int seq, String text, int at) => {
    'streamFrame': 1,
    'sequence': seq,
    'base': seq - 1,
    'account': 'a',
    'conversation': 'c',
    'response': 'r',
    'streaming': {'at': 0, 'text': ''},
    'reasoning': {
      'text': {'at': at, 'text': text},
      'state': 'thinking',
    },
    'draftPartial': {},
  };
  test('ordered stream frames preserve history, unicode and resets', () {
    final d = StreamStateDecoder();
    final start = d.decode({'streamFrame': 1, 'sequence': 1, 'state': initial});
    final next = d.decode(patch(2, '资料', 4));
    expect(next['entries'], same(start['entries']));
    expect((next['reasoning'] as Map)['text'], '核对😀资料');
    expect((start['reasoning'] as Map)['text'], '核对😀');
    expect((d.decode(patch(3, '重新核对', 0))['reasoning'] as Map)['text'], '重新核对');
    final complete = {
      ...initial,
      'responseId': '',
      'streaming': '',
      'analyzing': false,
    };
    expect(
      d.decode({'streamFrame': 1, 'sequence': 4, 'state': complete}),
      complete,
    );
    expect(d.decode(complete), complete); // Legacy host payload.
  });
  test('a missing frame or changed account cannot append to another run', () {
    final d = StreamStateDecoder();
    d.decode({'streamFrame': 1, 'sequence': 1, 'state': initial});
    expect(() => d.decode(patch(3, '错误', 4)), throwsFormatException);
    expect(
      () => d.decode({...patch(2, '错误', 4), 'account': 'b'}),
      throwsFormatException,
    );
    expect(() => d.decode(patch(2, '错误', 2)), throwsFormatException);
    expect((d.decode(patch(2, '正确', 4))['reasoning'] as Map)['text'], '核对😀正确');
    expect(
      d.decode({'streamFrame': 1, 'sequence': 1, 'state': initial}),
      initial,
    );
  });

  testWidgets('bursts reveal only received graphemes and drain within 80 ms', (
    tester,
  ) async {
    Future<void> show(
      String text, {
      bool active = true,
      bool reduced = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: StreamText(
              text: text,
              active: active,
              builder: (_, value) => Text(value),
            ),
          ),
        ),
      );
    }

    String shown() => tester.widget<Text>(find.byType(Text)).data!;
    await show('开始');
    final target = '开始${List.filled(40, '👩‍💻核对e\u0301').join()}';
    await show(target);
    await tester.pump(const Duration(milliseconds: 16));
    expect(shown().length, greaterThan(2));
    expect(shown().length, lessThan(target.length));
    expect(target.startsWith(shown()), isTrue);
    expect(
      target.characters.take(shown().characters.length).toString(),
      shown(),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(shown(), target);
    await show('$target 更多内容');
    await show('$target 更多内容', active: false);
    expect(shown(), '$target 更多内容');
    await show('新的尝试');
    expect(shown(), '新的尝试');
    await show('新的尝试需要完整显示', reduced: true);
    expect(shown(), '新的尝试需要完整显示');
  });

  for (final systemBack in [false, true]) {
    testWidgets(
      'citation returns to the same chat position, systemBack=$systemBack',
      (tester) async {
        tester.view.physicalSize = const Size(360, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final b = scroll23Fixture();
        final entries = b.data.rows('entries');
        entries[1] = {
          ...entries[1],
          'text': '[T7:S1]\n\n核对原始来源。',
          'reasoning': {
            'text': List.filled(60, '已核对资料和来源。\n').join(),
            'state': 'completed',
            'elapsedMs': 2000,
            'runComplete': true,
          },
          'sources': [
            {
              'id': 'T7:S1',
              'title': '采购要求',
              'text': '**原始资料**\n\n交期和数量。',
              'location': '第 1 段',
            },
          ],
        };
        b.data = {...b.data, 'entries': entries};
        final c = MailController(b, initial: b.data);
        await c.start();
        await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
        await tester.pumpAndSettle();
        final list = find.byKey(const ValueKey('chat-message-list'));
        final controller = tester.widget<ListView>(list).controller!;
        controller.jumpTo(36);
        await tester.pumpAndSettle();
        final panel = find.byType(ReasoningPanel).first;
        await tester.tap(
          find.descendant(of: panel, matching: find.byType(InkWell)).first,
        );
        await tester.pumpAndSettle();
        final inner = tester
            .widget<SingleChildScrollView>(
              find
                  .descendant(
                    of: panel,
                    matching: find.byType(SingleChildScrollView),
                  )
                  .first,
            )
            .controller!;
        inner.jumpTo(60);
        await tester.pumpAndSettle();
        final thoughtPosition = inner.offset;
        final assistant = tester.state(find.byType(Assistant));
        final offset = controller.offset;
        final link = find.textContaining('[T7:S1]', findRichText: true).first;
        final before = tester.getTopLeft(link);
        void open(InlineSpan span) {
          if (span is TextSpan) {
            if (span.text == '[T7:S1]') {
              (span.recognizer as TapGestureRecognizer).onTap!();
            }
            for (final child in span.children ?? <InlineSpan>[]) {
              open(child);
            }
          }
        }

        open(tester.widget<RichText>(link).text);
        await tester.pumpAndSettle();
        expect(b.data.child('source').text('id'), 'T7:S1');
        expect(
          tester.state(find.byType(Assistant, skipOffstage: false)),
          same(assistant),
        );
        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.byTooltip('返回'));
        }
        await tester.pumpAndSettle();
        expect(tester.widget<ListView>(list).controller, same(controller));
        expect(controller.offset, closeTo(offset, .5));
        expect(tester.getTopLeft(link).dy, closeTo(before.dy, .5));
        expect(
          find.descendant(of: panel, matching: find.byType(SelectableText)),
          findsOneWidget,
        );
        expect(inner.offset, closeTo(thoughtPosition, .5));
        expect(
          b.calls.where((v) => v == 'analyze' || v == 'confirmChatSend'),
          isEmpty,
        );
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      },
    );
  }

  testWidgets(
    'unchanged history does not rebuild its markdown during reasoning',
    (tester) async {
      final b = scroll23Fixture();
      final c = MailController(b, initial: b.data);
      await c.start();
      await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
      await tester.pumpAndSettle();
      final scroll = tester
          .widget<ListView>(find.byKey(const ValueKey('chat-message-list')))
          .controller!;
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      final body = tester.widget<MarkdownBody>(find.byType(MarkdownBody).first);
      for (var i = 0; i < 10; i++) {
        b.data = {
          ...b.data,
          'analyzing': true,
          'responseId': 'live',
          'reasoning': {
            'text': '收到的片段 $i',
            'state': 'thinking',
            'elapsedMs': i * 32,
          },
        };
        b.publish();
        await tester.pump(const Duration(milliseconds: 32));
        expect(
          tester.widget<MarkdownBody>(find.byType(MarkdownBody).first),
          same(body),
        );
      }
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
