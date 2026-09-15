import 'package:mailpilot/controller.dart';
import 'package:mailpilot/preview_data.dart';

PreviewBackend history24Fixture({int count = 8}) {
  final now = DateTime.now();
  final days = [0, 1, 3, 10, 31, 50, 70, 90];
  return PreviewBackend(
    initial: {
      ...previewState(),
      'entries': <RowData>[],
      'conversationId': 'history-0',
      'conversations': List.generate(
        count,
        (i) => {
          'id': 'history-$i',
          'title': i == 0 ? '图片分析与邮件跟进' : '历史对话 $i · 项目资料与附件核对',
          'lastActivityAt': now
              .subtract(Duration(days: days[i % 8] + (i ~/ 8)))
              .millisecondsSinceEpoch,
          'pinnedAt': 0,
        },
      ),
    },
  );
}
