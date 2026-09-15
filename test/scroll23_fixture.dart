import 'package:mailpilot/controller.dart';
import 'package:mailpilot/preview_data.dart';

PreviewBackend scroll23Fixture({String theme = 'light'}) => PreviewBackend(
  initial: {
    ...previewState(),
    'conversationId': 'long-chat-fixture',
    'selection': [],
    'settings': {...previewState().child('settings'), 'theme': theme},
    'entries': [
      for (var i = 0; i < 40; i++) ...[
        {'id': 'q$i', 'role': 'user', 'text': '第 ${i + 1} 轮：项目进展有哪些？'},
        {
          'id': 'a$i',
          'role': 'assistant',
          'text': i == 39
              ? '这是最新的回答。\n\n方案已确认，下一步是完成联调并记录验收结果。'
              : '第 ${i + 1} 轮进展\n\n${List.filled(i % 4 + 1, '已确认项目进度和待办，请继续核对时间安排。').join('\n\n')}',
        },
      ],
    ],
  },
);
