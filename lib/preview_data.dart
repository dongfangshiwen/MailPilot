// Explicit preview fixtures for unsupported hosts and tests. Never used by the Android entry.
import 'dart:async';
import 'dart:convert';

import 'package:markdown/markdown.dart' as md;

import 'controller.dart';

// Fixture-only renderer for the labelled web preview. Android uses CommonMark.
String previewMailBody(String source) {
  String render(md.Node node) {
    if (node is md.Text) return node.text;
    final e = node as md.Element;
    final text = (e.children ?? []).map(render).join();
    return switch (e.tag) {
      'li' => '• $text\n',
      'br' => '\n',
      'a' => '$text (${e.attributes['href'] ?? ''})',
      'td' || 'th' => '$text | ',
      'p' || 'h1' || 'h2' || 'h3' || 'pre' || 'tr' => '$text\n\n',
      _ => text,
    };
  }

  return md.Document(extensionSet: md.ExtensionSet.gitHubFlavored)
      .parseLines(
        source.replaceAll(RegExp(r'\[(?:T\d+:)?S\d+\]'), '').split('\n'),
      )
      .map(render)
      .join()
      .trimRight();
}

RowData previewState({int tab = 1}) => {
  'appVersion': '1.0.0',
  'buildNumber': 24,
  'tab': tab,
  'ready': true,
  'busy': false,
  'analyzing': false,
  'settings': {
    'theme': 'system',
    'syncMinutes': 0,
    'textModelId': 'model',
    'visionModelId': 'model',
  },
  'activeAccount': 'account',
  'folder': 'INBOX',
  'folders': ['INBOX', 'Sent'],
  'accounts': [
    {
      'id': 'account',
      'label': '工作邮箱 · 示例',
      'email': 'preview@example.test',
      'imapHost': 'imap.example.test',
      'smtpHost': 'smtp.example.test',
      'imapPort': 993,
      'smtpPort': 465,
      'hasSecret': true,
    },
  ],
  'models': [
    {
      'id': 'model',
      'label': '日常助手',
      'model': 'your-vision-model',
      'baseUrl': 'https://api.example.test/v1',
      'hasSecret': true,
      'textVerified': true,
      'supportsVision': true,
      'supportsTools': true,
      'supportsStreaming': true,
      'contextTokens': 32768,
      'outputTokens': 4096,
      'testReport': '预览数据：文字、视觉、工具、流式均可用',
    },
  ],
  'messages': [
    {
      'id': 'm1',
      'accountId': 'account',
      'subject': '示例：项目方案与预算，请确认',
      'sender': '林晓',
      'senderAddress': 'lin@example.test',
      'to': 'preview@example.test',
      'sentAt': 1788763800000,
      'unread': true,
      'attachmentCount': 2,
      'preview': '方案和预算表已更新。请在周五前反馈，我们会据此确定下一步的交付安排。',
      'body': '界面预览样例，不是真实邮件。\n\n你好，方案和预算表已经更新。请核对项目预算以及交付节点，并在周五前反馈。\n\n谢谢！',
    },
    {
      'id': 'm2',
      'accountId': 'account',
      'subject': '示例：周四的设计评审',
      'sender': '陈星',
      'senderAddress': 'chen@example.test',
      'sentAt': 1788750000000,
      'unread': false,
      'attachmentCount': 0,
      'preview': '下午 3 点一起讨论新版界面。欢迎提前留下问题。',
      'body': '界面预览样例。周四下午 3 点设计评审。',
    },
    {
      'id': 'm3',
      'accountId': 'account',
      'subject': '示例：上周工作小结',
      'sender': '产品团队',
      'senderAddress': 'team@example.test',
      'sentAt': 1788690000000,
      'unread': false,
      'attachmentCount': 1,
      'preview': '本周已完成需求梳理与原型评审，后续计划详见附件。',
      'body': '界面预览样例。',
    },
  ],
  'selection': [],
  'selectionLabels': [],
  'entries': [],
  'conversations': [],
  'drafts': [],
  'resultCards': [],
  'conversationId': 'preview',
};

class PreviewBackend extends MailBackend {
  PreviewBackend({RowData? initial, this.simulateReasoning = false})
    : data = initial ?? previewState();
  final bool simulateReasoning;
  RowData data;
  final calls = <String>[];
  final events = StreamController<RowData>.broadcast(sync: true);
  Timer? _stream;
  static const sampleReasoning =
      '【界面样例】正在核对问题中的目标、资料范围和待办事项。随后会组织回答，区分已经确认的信息与需要补充的内容。此文本用于展示交互，未调用模型。';
  static const sampleReply =
      '## 两件事需要确认\n\n'
      '这是**界面预览**，没有调用真实模型。\n\n'
      '| 待办 | 时间 |\n| --- | --- |\n| 核对项目预算 | 周五前 |\n| 确认交付安排 | 反馈时 |\n\n'
      '1. 核对方案与预算。\n2. 回复下一阶段的交付安排。 [S1]\n\n'
      '> 可以先起草回复，检查后再发送。';
  void stopPreview({bool preserve = false}) {
    _stream?.cancel();
    _stream = null;
    if (preserve &&
        (data.text('streaming').isNotEmpty ||
            data.child('reasoning').text('text').isNotEmpty)) {
      data = {
        ...data,
        'entries': [
          ...data.rows('entries'),
          {
            'id': data.text('responseId'),
            'role': 'assistant',
            'text': '${data.text('streaming')}\n\n> 已停止，以上是收到的部分回答。',
            'reasoning': {...data.child('reasoning'), 'state': 'stopped'},
          },
        ],
      };
    }
    data = {
      ...data,
      'analyzing': false,
      'streaming': '',
      'status': '',
      'reasoning': <String, dynamic>{},
      'responseId': '',
    };
  }

  @override
  Stream<RowData> get states => events.stream;
  void updateReviews() {
    data = {
      ...data,
      'entries': data.rows('entries').map((entry) {
        final preview = entry.child('draftPreview');
        if (preview.isEmpty) return entry;
        final d = data
            .rows('drafts')
            .where((d) => d['id'] == preview['id'])
            .firstOrNull;
        String code = 'ready', label = '等待你确认', action = 'send';
        if (d == null) {
          code = 'deleted';
          label = '草稿已删除';
          action = '';
        } else if (['SENDING', 'UNKNOWN', 'SENT'].contains(d.text('status'))) {
          code = d.text('status').toLowerCase();
          label = {
            'SENDING': '正在发送，请勿重复操作',
            'UNKNOWN': '发送结果待核实',
            'SENT': '已提交发送',
          }[d.text('status')]!;
          action = code == 'sending' ? '' : 'edit';
        } else if (entry['id'] != data.rows('entries').last['id'] ||
            d['revision'] != preview['revision']) {
          code = 'outdated';
          label = '此确认已失效，请核对最新版本';
          action = 'latest';
        } else if (d.text('to').isEmpty) {
          code = 'recipient';
          label = '待补充收件人';
          action = 'recipient';
        } else if (d.text('body').isEmpty) {
          code = 'body';
          label = '请补充邮件正文';
          action = 'edit';
        }
        return {
          ...entry,
          'review': {
            'code': code,
            'label': label,
            'action': action,
            'canSend': action == 'send',
          },
        };
      }).toList(),
    };
  }

  List<RowData> fixtureFiles(String messageId) {
    if (data.containsKey('attachments')) {
      return data
          .rows('attachments')
          .where((a) => a['messageId'] == messageId)
          .toList();
    }
    if (data.child('detail').text('id') == messageId &&
        data.containsKey('detailAttachments')) {
      return data.rows('detailAttachments');
    }
    if (messageId != 'm1') return [];
    return [
      {
        'id': 'a1',
        'messageId': messageId,
        'name': '项目方案.docx',
        'mimeType': 'application/octet-stream',
        'size': 420000,
      },
      {
        'id': 'a2',
        'messageId': messageId,
        'name': '预算.pdf',
        'mimeType': 'application/pdf',
        'size': 860000,
      },
    ];
  }

  String fixtureReason(RowData a) {
    if (![
      'docx',
      'xlsx',
      'pptx',
      'pdf',
      'txt',
      'jpg',
      'jpeg',
      'png',
      'webp',
    ].contains(a.text('name').split('.').last.toLowerCase())) {
      return '此格式暂不支持分析';
    }
    return a.number('size', -1) > 20 * 1024 * 1024 ? '超过单文件 20 MB' : '';
  }

  RowData defaultSelection(String id) {
    final files = fixtureFiles(id)
        .where((a) => fixtureReason(a).isEmpty)
        .toList();
    return {
      'messageId': id,
      'attachmentIds': files.map((a) => a['id']).toList(),
      'defaultPdfIds': files
          .where((a) => a.text('name').toLowerCase().endsWith('.pdf'))
          .map((a) => a['id'])
          .toList(),
      'pdfPages': <String, dynamic>{},
    };
  }

  void updateMaterials() {
    final groups = <RowData>[];
    final selected = <RowData>[];
    for (final selection in data.rows('selection')) {
      final files = fixtureFiles(selection.text('messageId'))
          .map(
            (a) => <String, dynamic>{
              ...a,
              'selectionReason': fixtureReason(a),
              'selected': selection.strings('attachmentIds').contains(a['id']),
              'defaultPages': selection
                  .strings('defaultPdfIds')
                  .contains(a['id']),
              'pages': selection.child('pdfPages')[a['id']] ?? [],
            },
          )
          .toList();
      final message =
          data
              .rows('messages')
              .where((m) => m['id'] == selection['messageId'])
              .firstOrNull ??
          {};
      groups.add({
        'messageId': selection['messageId'],
        'subject': message.text('subject'),
        'pending': files.length < message.number('attachmentCount'),
        'attachments': files,
      });
      selected.addAll(files.where((a) => a.flag('selected')));
    }
    selected.addAll(
      data.rows('localMaterials').where((a) => a.flag('selected')),
    );
    final unique = {for (final a in selected) a.text('id'): a}.values.toList();
    final bytes = unique.fold<int>(
      0,
      (n, a) => n + a.number('size', -1).clamp(0, 1 << 40),
    );
    final visuals = unique.fold<int>(
      0,
      (n, a) =>
          n +
          ([
                'jpg',
                'jpeg',
                'png',
                'webp',
              ].contains(a.text('name').split('.').last.toLowerCase())
              ? 1
              : (a['pages'] as List? ?? []).length),
    );
    final issues = <String>[];
    if (unique.length > 10) issues.add('已选 ${unique.length} 个附件，每轮最多 10 个');
    if (bytes > 50 * 1024 * 1024) issues.add('附件合计超过 50 MB');
    if (visuals > 20) issues.add('图片或 PDF 页面合计超过 20 张');
    data = {
      ...data,
      'selectionGroups': groups,
      'selectionBudget': {
        'count': unique.length,
        'bytes': bytes,
        'unknown': unique.where((a) => a.number('size', -1) < 0).length,
        'visuals': visuals,
        'pendingVisuals': true,
        'blocked': issues.isNotEmpty,
        'issues': issues,
      },
    };
  }

  void publish() {
    updateMaterials();
    updateReviews();
    events.add({...data});
  }

  final Map<String, List<RowData>> messageHistory = {};
  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) async {
    calls.add(method);
    if (method == 'snapshot') {
      updateMaterials();
      updateReviews();
      return jsonEncode(data);
    }
    if (['newConversation'].contains(method)) {
      stopPreview();
    }
    final id = args.text('id');
    switch (method) {
      case 'listConversations':
        final query = args.text('search').trim().toLowerCase();
        final items =
            data
                .rows('conversations')
                .where(
                  (e) =>
                      query.isEmpty ||
                      e.text('title').toLowerCase().contains(query) ||
                      (messageHistory[e.text('id')] ?? []).any(
                        (m) => m.text('text').toLowerCase().contains(query),
                      ),
                )
                .toList()
              ..sort((a, b) {
                final pin = b
                    .number('pinnedAt')
                    .compareTo(a.number('pinnedAt'));
                return pin != 0
                    ? pin
                    : b
                          .number('lastActivityAt', b.number('createdAt'))
                          .compareTo(
                            a.number('lastActivityAt', a.number('createdAt')),
                          );
              });
        final cursor = args.child('cursor');
        final after = cursor.isEmpty
            ? 0
            : items.indexWhere((e) => e['id'] == cursor['id']) + 1;
        final page = items.skip(after).take(50).toList();
        return jsonEncode({
          'items': page,
          'cursor': after + page.length < items.length ? page.last : null,
        });
      case 'renameConversation':
        data = {
          ...data,
          'conversations': data
              .rows('conversations')
              .map(
                (e) => e['id'] == id
                    ? {...e, 'title': args.text('title').trim()}
                    : e,
              )
              .toList(),
          'historyRevision': data.number('historyRevision') + 1,
        };
      case 'pinConversations':
        final ids = args.strings('ids');
        data = {
          ...data,
          'conversations': data
              .rows('conversations')
              .map(
                (e) => ids.contains(e.text('id'))
                    ? {
                        ...e,
                        'pinnedAt': args.flag('pin')
                            ? DateTime.now().millisecondsSinceEpoch
                            : 0,
                      }
                    : e,
              )
              .toList(),
          'historyRevision': data.number('historyRevision') + 1,
        };
      case 'deleteConversations':
        data = {
          ...data,
          'conversations': data
              .rows('conversations')
              .where((e) => !args.strings('ids').contains(e.text('id')))
              .toList(),
          'historyRevision': data.number('historyRevision') + 1,
        };
      case 'loadConversation':
        data = {...data, 'conversationId': id, 'tab': 1};
      case 'visualMaterials':
        return jsonEncode(data.rows('visualMaterials'));
      case 'recheckVisual':
        data = {
          ...data,
          'visualMaterials': data
              .rows('visualMaterials')
              .map(
                (e) => e['assetKey'] == args['assetKey']
                    ? {...e, 'pending': !e.flag('pending')}
                    : e,
              )
              .toList(),
        };

      case 'account':
        data = {
          ...data,
          'activeAccount': id,
          'selection': [],
          'selectionLabels': [],
          'entries': [],
        };
      case 'tab':
        data = {...data, 'tab': args['index'], 'detail': null, 'editor': null};
      case 'toggleMessage':
        final selected = data.rows('selection');
        if (selected.any((e) => e['messageId'] == id)) {
          selected.removeWhere((e) => e['messageId'] == id);
        } else {
          selected.add(defaultSelection(id));
        }
        data = {
          ...data,
          'selection': selected,
          'selectionLabels': data
              .rows('messages')
              .where((m) => selected.any((s) => s['messageId'] == m['id']))
              .map((e) => e.text('subject'))
              .toList(),
        };
      case 'openMessage':
        data = {
          ...data,
          'detail': data.rows('messages').where((m) => m['id'] == id).first,
          'detailAttachments': [
            {
              'id': 'a1',
              'messageId': id,
              'name': '项目方案.docx',
              'mimeType': 'application/octet-stream',
              'size': 420000,
            },
            {
              'id': 'a2',
              'messageId': id,
              'name': '预算.pdf',
              'mimeType': 'application/pdf',
              'size': 860000,
            },
          ],
        };
      case 'selectionSummary':
        updateMaterials();
        publish();
        return jsonEncode(data.child('selectionBudget'));
      case 'selectMessageFiles':
        final selected = data.rows('selection')
          ..removeWhere((e) => e['messageId'] == id);
        selected.add(
          args.flag('bodyOnly')
              ? {'messageId': id, 'attachmentIds': <String>[]}
              : defaultSelection(id),
        );
        data = {...data, 'selection': selected};
      case 'selectAttachment':
        final a = [
          ...data.rows('detailAttachments'),
          ...data.rows('selectionGroups').expand((g) => g.rows('attachments')),
        ].where((a) => a['id'] == id).first;
        final selected = data.rows('selection');
        final mid = a.text('messageId', data.child('detail').text('id'));
        var selection = selected
            .where((s) => s['messageId'] == mid)
            .firstOrNull;
        if (selection == null) {
          selection = {'messageId': mid, 'attachmentIds': <String>[]};
          selected.add(selection);
        }
        final ids = selection.strings('attachmentIds'),
            defaults = selection.strings('defaultPdfIds');
        final pages = selection.child('pdfPages');
        if (ids.remove(id)) {
          defaults.remove(id);
          pages.remove(id);
        } else if (fixtureReason(a).isEmpty) {
          ids.add(id);
          if (a.text('name').toLowerCase().endsWith('.pdf')) defaults.add(id);
        }
        selection['attachmentIds'] = ids;
        selection['defaultPdfIds'] = defaults;
        selection['pdfPages'] = pages;
        data = {...data, 'selection': selected};
      case 'editPdf':
      case 'localPdf':
        final a = [
          ...data.rows('detailAttachments'),
          ...data.rows('selectionGroups').expand((g) => g.rows('attachments')),
          ...data.rows('localMaterials'),
        ].where((a) => a['id'] == id).first;
        final selected =
            data
                .rows('selection')
                .where((s) => s.strings('attachmentIds').contains(id))
                .firstOrNull ??
            {};
        final count = a.number('pageCount', 30);
        data = {
          ...data,
          'pdfChoice': {
            'attachment': a,
            'count': count,
            'token': 'preview-$id-${DateTime.now().microsecondsSinceEpoch}',
            'selected':
                selected.child('pdfPages')[id] ??
                (method == 'localPdf' && (a['pages'] as List? ?? []).isNotEmpty
                    ? a['pages']
                    : List.generate(count.clamp(0, 10), (i) => i)),
          },
        };
      case 'pdfThumbnail':
        return base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jR5kAAAAASUVORK5CYII=',
        );
      case 'choosePdf':
        final a = data.child('pdfChoice').child('attachment'),
            pages = args['pages'] as List;
        if (a.text('messageId').isEmpty) {
          data = {
            ...data,
            'localMaterials': data
                .rows('localMaterials')
                .map(
                  (m) => m['id'] == a['id']
                      ? {...m, 'selected': pages.isNotEmpty, 'pages': pages}
                      : m,
                )
                .toList(),
            'pdfChoice': null,
          };
        } else {
          final selections = data.rows('selection');
          var selection = selections
              .where((s) => s['messageId'] == a['messageId'])
              .firstOrNull;
          if (selection == null) {
            selection = {
              'messageId': a['messageId'],
              'attachmentIds': <String>[],
            };
            selections.add(selection);
          }
          final ids = selection.strings('attachmentIds')..remove(a['id']);
          final defaults = selection.strings('defaultPdfIds')..remove(a['id']);
          final p = selection.child('pdfPages')..remove(a['id']);
          if (pages.isNotEmpty) {
            ids.add(a.text('id'));
            p[a.text('id')] = pages;
          }
          selection['attachmentIds'] = ids;
          selection['defaultPdfIds'] = defaults;
          selection['pdfPages'] = p;
          data = {...data, 'selection': selections, 'pdfChoice': null};
        }
      case 'dismissPdf':
        data = {...data, 'pdfChoice': null};
      case 'back':
        data = {...data, 'editor': null, 'detail': null, 'source': null};
      case 'clearSelection':
        data = {
          ...data,
          'selection': [],
          'selectionLabels': [],
          'localMaterials': data
              .rows('localMaterials')
              .map((m) => {...m, 'selected': false})
              .toList(),
          'recheckAssets': [],
        };
      case 'clearFeedback':
        data = {...data, 'error': null, 'notice': null};
      case 'dismissNotice':
        if (data['notice'] == args['notice']) data = {...data, 'notice': null};
      case 'theme':
        data = {
          ...data,
          'settings': {...data.child('settings'), 'theme': args['value']},
        };
      case 'appLanguage':
        data = {
          ...data,
          'settings': {...data.child('settings'), 'appLanguage': args['value']},
        };
      case 'fastCompression':
        data = {
          ...data,
          'settings': {
            ...data.child('settings'),
            'fastCompression': args['enabled'],
          },
        };
      case 'sync':
        data = {
          ...data,
          'settings': {
            ...data.child('settings'),
            'syncMinutes': args['minutes'],
          },
        };
      case 'defaultModel':
        data = {
          ...data,
          'settings': {
            ...data.child('settings'),
            args.flag('vision') ? 'visionModelId' : 'textModelId': id,
          },
        };
      case 'newConversation':
        data = {
          ...data,
          'entries': [],
          'selection': [],
          'selectionLabels': [],
          'resultCards': [],
          'contextSummary': '',
          'summarizedEntries': 0,
        };
      case 'prepareMessageEdit':
        final user = data.rows('entries').firstWhere((e) => e['id'] == id);
        return jsonEncode({
          'id': id,
          'text': user.text('text'),
          'options': {'thinking': 'default', 'webSearch': false},
          'materialLabel': '沿用原问题资料 · 1 封邮件',
        });
      case 'messageVersions':
        final versions = messageHistory[id] ?? [];
        final current = data.rows('entries');
        return jsonEncode(
          versions.map((v) {
            final index = current.indexWhere((e) => e['id'] == v['id']);
            return {
              ...v,
              if (index >= 0)
                'entries': [
                  current[index],
                  ...current
                      .skip(index + 1)
                      .takeWhile((e) => e.text('role') != 'user'),
                ],
            };
          }).toList(),
        );
      case 'editMessage':
        final entries = data.rows('entries');
        final index = entries.indexWhere((e) => e['id'] == id);
        final user = entries[index];
        final versions =
            messageHistory[id] ??
            [
              {
                'id': id,
                'text': user.text('text'),
                'entries': [
                  user,
                  ...entries
                      .skip(index + 1)
                      .takeWhile((e) => e.text('role') != 'user'),
                ],
                'reply': entries
                    .skip(index + 1)
                    .takeWhile((e) => e.text('role') != 'user')
                    .map((e) => e.text('text'))
                    .join('\n\n'),
              },
            ];
        data = {...data, 'entries': entries.take(index).toList()};
        await invoke('analyze', {
          'question': args['question'],
          'options': args['options'],
        });
        final current = data.rows('entries');
        final updated = {
          ...current.last,
          'versionCount': versions.length + 1,
          'canEdit': true,
        };
        messageHistory[updated.text('id')] = [
          ...versions,
          {'id': updated['id'], 'text': args['question'], 'reply': sampleReply},
        ];
        data = {
          ...data,
          'entries': [...current.take(current.length - 1), updated],
        };
      case 'analyze':
        if (data.flag('analyzing')) return null;
        final generalChat = data.rows('accounts').isEmpty;
        final answerId = 'a${calls.length}';
        final reply = generalChat
            ? '## 可以直接聊天\n\n配置模型后即可提问、写作和整理思路，邮箱是可选功能。\n\n这是**界面预览**，未调用真实模型。'
            : sampleReply;
        data = {
          ...data,
          'tab': 1,
          'analyzing': true,
          'streaming': '',
          'reasoning': <String, dynamic>{},
          'responseId': answerId,
          'status': '正在回答 · 样例演示',
          'entries': [
            ...data.rows('entries'),
            {
              'id': 'q${calls.length}',
              'role': 'user',
              'text': args['question'],
            },
          ],
        };
        var offset = 0;
        var reasoningOffset = 0;
        var reasoningMs = 0;
        _stream = Timer.periodic(const Duration(milliseconds: 80), (_) {
          if (simulateReasoning && reasoningOffset < sampleReasoning.length) {
            reasoningOffset = (reasoningOffset + 4).clamp(
              0,
              sampleReasoning.length,
            );
            reasoningMs += 80;
            data = {
              ...data,
              'status': '正在思考 · 样例演示',
              'reasoning': {
                'text': sampleReasoning.substring(0, reasoningOffset),
                'elapsedMs': reasoningMs,
                'state': 'thinking',
              },
            };
            publish();
            return;
          }
          offset = (offset + 8).clamp(0, reply.length);
          data = {
            ...data,
            'streaming': reply.substring(0, offset),
            'status': '正在回答 · 样例演示',
            'reasoning': {...data.child('reasoning'), 'state': 'completed'},
          };
          if (offset == reply.length) {
            final reasoning = data.child('reasoning');
            stopPreview();
            data = {
              ...data,
              'entries': [
                ...data.rows('entries'),
                {
                  'id': answerId,
                  'role': 'assistant',
                  'text': reply,
                  'reasoning': reasoning,
                  'sources': [
                    if (!generalChat)
                      {
                        'id': 'S1',
                        'messageId': 'm1',
                        'title': '示例：项目方案与预算',
                        'location': '邮件正文 · 段 1',
                        'text': '界面预览引用样例。',
                      },
                  ],
                },
              ],
            };
          }
          publish();
        });
      case 'cancelAnalysis':
        stopPreview(preserve: true);
      case 'openLink':
        data = {...data, 'notice': '界面预览不打开外部链接，可使用“复制链接”。'};
      case 'newDraft':
      case 'reply':
        data = {
          ...data,
          'detail': null,
          'editor': {
            'id': 'draft',
            'accountId': 'account',
            'to': method == 'reply' ? 'lin@example.test' : '',
            'subject': 'Re: 项目方案与预算',
            'body': previewMailBody(
              args.text(
                'body',
                method == 'draftFromAnswer'
                    ? data
                          .rows('entries')
                          .firstWhere((e) => e['id'] == args['id'])
                          .text('text')
                    : '林晓，你好：\n\n已收到方案。我会在周五前核对预算，并反馈交付安排。\n\n谢谢！（界面预览样例）',
              ),
            ),
            'cc': '',
            'bcc': '',
            'files': [],
            'revision': 0,
            'status': 'DRAFT',
          },
        };
      case 'draftFromAnswer':
        final answer = data.rows('entries').firstWhere((e) => e['id'] == id);
        final d = {
          'id': 'draft-answer-$id',
          'accountId': 'account',
          'to': '',
          'cc': '',
          'bcc': '',
          'subject': '回答整理',
          'body': previewMailBody(answer.text('text')),
          'files': [],
          'revision': 1,
          'status': 'DRAFT',
        };
        data = {
          ...data,
          'drafts': [...data.rows('drafts'), d],
          'entries': [
            ...data.rows('entries'),
            {
              'id': 'action-$id',
              'role': 'user',
              'text': '将这条回答写成邮件',
              'action': 'draft_answer',
              'targetAnswerId': id,
            },
            {
              'id': 'card-$id',
              'role': 'assistant',
              'text': '已起草，请补充收件人并核对。',
              'draftId': d['id'],
              'draftPreview': {
                ...d,
                'senderEmail': data.rows('accounts').first.text('email'),
              },
            },
          ],
        };
      case 'fillRecipient':
        final entry = data.rows('entries').firstWhere((e) => e['id'] == id);
        final old = data
            .rows('drafts')
            .firstWhere((d) => d['id'] == entry.text('draftId'));
        final d = {
          ...old,
          'to': args.text('address'),
          'revision': old.number('revision') + 1,
        };
        data = {
          ...data,
          'drafts': data
              .rows('drafts')
              .map((v) => v['id'] == d['id'] ? d : v)
              .toList(),
          'entries': [
            ...data.rows('entries'),
            {
              'id': 'address-${calls.length}',
              'role': 'assistant',
              'text': '收件人已更新，请核对新版本后确认发送。',
              'draftId': d['id'],
              'draftPreview': {
                ...d,
                'senderEmail': data.rows('accounts').first.text('email'),
              },
            },
          ],
        };
      case 'latestDraft':
        final d = data.rows('drafts').firstWhere((d) => d['id'] == id);
        data = {
          ...data,
          'entries': [
            ...data.rows('entries'),
            {
              'id': 'latest-${calls.length}',
              'role': 'assistant',
              'text': '这是当前最新版本，请核对后确认。',
              'draftId': d['id'],
              'draftPreview': {
                ...d,
                'senderEmail': data.rows('accounts').first.text('email'),
              },
            },
          ],
        };
      case 'saveService':
        data = {
          ...data,
          args.flag('speech') ? 'speechConfig' : 'searchConfig': {
            ...args,
            'secret': '',
            'hasSecret': args.text('secret').isNotEmpty,
          },
        };
        publish();
        return '配置已保存（界面预览）';
      case 'testService':
        return '预览不调用真实搜索或语音服务';
      case 'pickMaterial':
        data = {
          ...data,
          'localMaterials': [
            ...data.rows('localMaterials'),
            {
              'id': 'local-${calls.length}',
              'name': args.flag('image') ? '手机图片.png' : '手机资料.txt',
              'selected': true,
            },
          ],
        };
      case 'toggleLocal':
        data = {
          ...data,
          'localMaterials': data
              .rows('localMaterials')
              .map(
                (f) =>
                    f['id'] == id ? {...f, 'selected': !f.flag('selected')} : f,
              )
              .toList(),
        };
      case 'updateEditor':
        data = {...data, 'editor': args};
      case 'plainMailBody':
        return previewMailBody(args.text('body'));
      case 'loadFolders':
        data = {
          ...data,
          'folders': [
            'INBOX',
            'Sent Messages',
            'Drafts',
            'Deleted Messages',
            'Junk',
          ],
          'foldersLoading': false,
          'foldersError': '',
        };
      case 'folder':
        data = {...data, 'folder': args.text('value')};
      case 'refresh':
        data = {
          ...data,
          'syncing': true,
          'syncLabel': '同步文件夹 · 界面预览',
          'notice': '已开始后台同步各文件夹，可继续使用',
        };
      case 'cancelSync':
        data = {
          ...data,
          'syncing': false,
          'syncLabel': '',
          'notice': '同步已取消，已下载邮件保留',
        };
      case 'redraft':
        final old = data.rows('drafts').firstWhere((d) => d['id'] == id);
        final revised = {
          ...old,
          'body': '您好：\n\n这是重新拟写后的示例邮件，收件人和附件保持不变。\n\n谢谢！',
          'revision': old.number('revision') + 1,
        };
        data = {
          ...data,
          'tab': 1,
          'editor': null,
          'drafts': data
              .rows('drafts')
              .map((d) => d['id'] == id ? revised : d)
              .toList(),
          'entries': [
            ...data.rows('entries'),
            {
              'id': 'redraft-${calls.length}',
              'role': 'assistant',
              'text': '已重新拟写，请核对后确认发送。',
              'draftId': id,
              'draftPreview': {
                ...revised,
                'senderEmail': data.rows('accounts').first.text('email'),
              },
            },
          ],
        };
      case 'reviewDraftInChat':
        final d = {...args, 'revision': args.number('revision') + 1};
        data = {
          ...data,
          'tab': 1,
          'editor': null,
          'sendPreview': null,
          'drafts': [d],
          'entries': [
            ...data.rows('entries'),
            {
              'id': 'card-${calls.length}',
              'role': 'assistant',
              'text': '请核对邮件卡片，再确认发送。（界面预览）',
              'draftId': d['id'],
              'draftPreview': {
                ...d,
                'senderEmail': data.rows('accounts').first.text('email'),
              },
            },
          ],
        };
      case 'confirmChatSend':
        data = {
          ...data,
          'drafts': [
            for (final d in data.rows('drafts')) {...d, 'status': 'SENT'},
          ],
          'entries': [
            ...data.rows('entries'),
            {
              'id': 'receipt-${calls.length}',
              'role': 'assistant',
              'text': '界面预览：显示发送结果，未实际发送邮件。',
            },
          ],
        };
      case 'saveDraft':
        final d = {...args, 'revision': args.number('revision') + 1};
        data = {
          ...data,
          'editor': d,
          'drafts': [d],
          'sendPreview': args.flag('preview') ? d : null,
          'notice': args.flag('preview') ? null : '草稿已保存',
        };
      case 'sendConfirmed':
        data = {
          ...data,
          'sendPreview': null,
          'editor': {...data.child('editor'), 'status': 'SENT'},
          'notice': '仅预览发送状态，未发送邮件',
        };
      case 'dismissSend':
        data = {...data, 'sendPreview': null};
      case 'editDraft':
        data = {...data, 'editor': data.rows('drafts').first};
      case 'deleteDraft':
        data = {
          ...data,
          'editor': null,
          'drafts': data.rows('drafts').where((d) => d['id'] != id).toList(),
          'notice': '本地草稿已删除',
        };
      case 'showSource':
        data = {...data, 'source': args['source']};
      case 'sourceInfo':
        return jsonEncode(args);
      case 'testAccount':
        return '预览：连接成功（未进行实际测试）';
      case 'testModel':
        return jsonEncode({
          ...data.rows('models').first,
          'testReport': '预览：所有能力通过',
        });
    }
    publish();
    return null;
  }

  @override
  void dispose() {
    _stream?.cancel();
    events.close();
  }
}
