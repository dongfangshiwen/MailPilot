import 'package:mailpilot/controller.dart';
import 'package:mailpilot/preview_data.dart';

const context22Model = {
  'id': 'context22-model',
  'label': '火山 · 上下文样例',
  'provider': 'volcengine',
  'baseUrl': 'https://ark.cn-beijing.volces.com/api/v3',
  'model': 'doubao-seed-evolving',
  'contextMode': 'auto',
  'contextTokens': 1048576,
  'outputTokens': 4096,
  'thinkingMode': 'disabled',
  'hasSecret': false,
};
const context22Catalog = [
  {
    'provider': 'volcengine',
    'model': 'doubao-seed-evolving',
    'vision': true,
    'contextTokens': 1048576,
    'maxInputTokens': 1048576,
    'maxThinkingInputTokens': 1048576,
    'maxOutputTokens': 262144,
    'verifiedAt': '2026-09-09',
    'source': 'https://docs.volcengine.com/docs/82379/1330310?lang=zh',
  },
  {
    'provider': 'volcengine',
    'model': 'doubao-seed-2-0-lite-260428',
    'vision': true,
    'contextTokens': 262144,
    'maxInputTokens': 229376,
    'maxThinkingInputTokens': 229376,
    'maxOutputTokens': 131072,
    'verifiedAt': '2026-09-09',
  },
];

class Context22Backend extends PreviewBackend {
  Context22Backend({String theme = 'light'})
    : super(
        initial: {
          ...previewState(),
          'models': [context22Model],
          'modelCatalog': context22Catalog,
          'settings': {...previewState().child('settings'), 'theme': theme},
        },
      );
  RowData? saved;
  int diagnostics = 0;
  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) async {
    if (method == 'saveModel') {
      saved = {...args};
      return '模型已保存';
    }
    if (method == 'testModel') {
      diagnostics++;
    }
    return super.invoke(method, args);
  }
}
