import 'app_language.dart';

import 'package:flutter/widgets.dart';

Map<String, String> get providerLabels => providerLabelsFor(null);
Map<String, String> providerLabelsFor(BuildContext? context) => {
  'auto': strings(context).autoDetect,
  'deepseek': 'DeepSeek',
  'volcengine': strings(context).volcengineArk,
  'aliyun': strings(context).alibabaCloudModelStudio,
  'compatible': strings(context).openaiCompatibleApi,
};
Map<String, String> get effortLabels => effortLabelsFor(null);
Map<String, String> effortLabelsFor(BuildContext? context) => {
  '': strings(context).providerDefault,
  'minimal': strings(context).minimalMinimal,
  'low': strings(context).lowLow,
  'medium': strings(context).mediumMedium,
  'high': strings(context).highHigh,
  'xhigh': strings(context).veryHighXhigh,
  'max': strings(context).maximumMax,
};

bool officialModelEndpoint(String provider, String url) {
  final uri = Uri.tryParse(
    url
        .trim()
        .replaceFirst(RegExp(r'/chat/completions/?$'), '')
        .replaceFirst(RegExp(r'/$'), ''),
  );
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      uri.hasPort) {
    return false;
  }
  return switch (provider) {
    'volcengine' =>
      const [
            'ark.cn-beijing.volces.com',
            'ark.cn-shanghai.volces.com',
          ].contains(uri.host) &&
          uri.path == '/api/v3',
    'aliyun' =>
      const [
            'dashscope.aliyuncs.com',
            'dashscope-intl.aliyuncs.com',
            'dashscope-us.aliyuncs.com',
          ].contains(uri.host) &&
          uri.path == '/compatible-mode/v1',
    'deepseek' =>
      uri.host == 'api.deepseek.com' && const ['', '/v1'].contains(uri.path),
    _ => false,
  };
}

String modelProvider(String provider, String url) {
  if (provider != 'auto') return provider;
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  bool domain(String name) => host == name || host.endsWith('.$name');
  if (domain('deepseek.com')) return 'deepseek';
  if (domain('volces.com') || domain('volcengine.com')) return 'volcengine';
  if (domain('aliyuncs.com')) return 'aliyun';
  return 'compatible';
}

List<String> modelEfforts(String provider, String model) => switch (provider) {
  'deepseek' => ['', 'low', 'high', 'max'],
  'volcengine' => ['', 'minimal', 'low', 'medium', 'high'],
  'aliyun' when model.toLowerCase().startsWith('qwen3.8') => [
    '',
    'low',
    'medium',
    'xhigh',
  ],
  'aliyun'
      when model.toLowerCase().startsWith('qwen') ||
          model.toLowerCase().startsWith('qwq') =>
    [''],
  'aliyun' => ['', 'low', 'high', 'max'],
  _ => effortLabels.keys.toList(),
};
