import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'stream_state_decoder.dart';

typedef RowData = Map<String, dynamic>;
RowData row(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

extension Fields on RowData {
  String text(String key, [String fallback = '']) =>
      this[key]?.toString() ?? fallback;
  bool flag(String key) => this[key] == true;
  int number(String key, [int fallback = 0]) =>
      (this[key] as num?)?.toInt() ?? fallback;
  RowData child(String key) => row(this[key]);
  List<RowData> rows(String key) =>
      (this[key] as List? ?? []).map(row).toList();
  List<String> strings(String key) =>
      (this[key] as List? ?? []).map((e) => e.toString()).toList();
}

abstract class MailBackend {
  Stream<RowData> get states;
  Future<dynamic> invoke(String method, [RowData args = const {}]);
  void dispose() {}
}

class AndroidBackend extends MailBackend {
  static bool get available =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static const _actions = MethodChannel('mailpilot/actions');
  static const _events = EventChannel('mailpilot/state');
  final _streamDecoder = StreamStateDecoder();
  @override
  Stream<RowData> get states => _events.receiveBroadcastStream().map(
    (e) => _streamDecoder.decode(row(jsonDecode(e as String))),
  );
  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) {
    if (!available) {
      return Future.error(UnsupportedError('邮箱与模型连接需要 Android 设备，请使用界面预览入口。'));
    }
    return _actions.invokeMethod(method, args);
  }
}

class MailController extends ChangeNotifier {
  String chatThinking = 'default';
  bool chatSearch = false;
  void setChatOptions({String? thinking, bool? search}) {
    if (thinking != null) chatThinking = thinking;
    if (search != null) chatSearch = search;
    notifyListeners();
  }

  bool get thinkingEnabled =>
      chatThinking == 'enabled' ||
      (chatThinking == 'default' &&
          currentModel.text('thinkingMode') != 'disabled' &&
          (currentModel.text('thinkingMode') == 'enabled' ||
              currentModel.number('thinkingBudget') > 0 ||
              (currentModel.text('reasoningEffort').isNotEmpty &&
                  currentModel.text('reasoningEffort') != 'none')));
  RowData get requestOptions => {
    'thinking': thinkingEnabled ? 'enabled' : 'disabled',
    'webSearch': chatSearch,
  };
  MailController(this.backend, {RowData? initial})
    : data = initial ?? {'tab': 1};
  final MailBackend backend;
  RowData data;
  String? failure;
  StreamSubscription<RowData>? _subscription;
  bool _disposed = false;
  bool _starting = false;
  bool connected = false;
  int? _sectionTab;
  int _sectionReturnTab = 1;
  bool get canReturnFromSection => _sectionTab == data.number('tab', 1);
  bool get returnsToSettings => canReturnFromSection && _sectionReturnTab == 3;
  bool get busy => data.flag('busy') || data.flag('analyzing');
  RowData get settings => data.child('settings');
  void applyAppLanguage(String code) {
    if (_disposed) return;
    data = {
      ...data,
      'settings': {...settings, 'appLanguage': code},
    };
    notifyListeners();
  }

  List<RowData> get accounts => data.rows('accounts');
  List<RowData> get models => data.rows('models');
  RowData get currentModel =>
      models.where((e) => e['id'] == settings['textModelId']).firstOrNull ??
      models.firstOrNull ??
      {};
  bool selected(String id) =>
      data.rows('selection').any((e) => e['messageId'] == id);
  Future<void> start() async {
    if (_starting || _disposed || connected) return;
    _starting = true;
    failure = null;
    try {
      // Probe before opening EventChannel: unsupported preview hosts otherwise
      // throw an unhandled plugin error while registering their stream.
      final snapshot = await backend.invoke('snapshot');
      if (_disposed) return;
      if (snapshot is String) data = row(jsonDecode(snapshot));
      _subscription = backend.states.listen(
        (state) {
          data = state;
          if (!_disposed) notifyListeners();
        },
        onError: (Object e) {
          failure = _error(e);
          if (!_disposed) notifyListeners();
        },
      );
      connected = true;
      await backend.invoke('tab', {'index': 1});
    } catch (e) {
      failure = _error(e);
    } finally {
      _starting = false;
    }
    if (!_disposed) notifyListeners();
  }

  String _error(Object e) => switch (e) {
    MissingPluginException() =>
      '未连接到 Android 邮件服务。请完全关闭后重新打开最新版 APK；浏览器和 Widget Preview 请使用界面预览入口。',
    PlatformException() => e.message ?? '操作未完成',
    UnsupportedError() => e.message ?? '当前运行环境不支持此功能',
    _ => e.toString(),
  };
  Future<dynamic> request(String method, [RowData args = const {}]) =>
      backend.invoke(method, args);
  Future<void> act(String method, [RowData args = const {}]) async {
    final previousSection = _sectionTab;
    final previousReturn = _sectionReturnTab;
    try {
      final payload = {...args};
      if (method == 'tab') {
        final index = payload.number('index', 1);
        final fromSettings = payload.remove('fromSettings') == true;
        final fromChat = payload.remove('fromChat') == true;
        _sectionTab = (fromSettings || fromChat) && (index == 0 || index == 2)
            ? index
            : null;
        _sectionReturnTab = fromSettings ? 3 : 1;
      }
      if ((method == 'draftFromAnswer' || method == 'redraft') &&
          !payload.containsKey('options')) {
        payload['options'] = requestOptions;
      }
      await request(method, payload);
    } catch (e) {
      if (method == 'tab') {
        _sectionTab = previousSection;
        _sectionReturnTab = previousReturn;
      }
      failure = _error(e);
      if (!_disposed) notifyListeners();
    }
  }

  void clearError() {
    failure = null;
    if (connected) unawaited(act('clearFeedback'));
    notifyListeners();
  }

  Future<Uint8List?> image(String path) async =>
      await request('imageBytes', {'path': path}) as Uint8List?;
  Future<void> back() async {
    if (data['sendPreview'] != null) {
      await act('dismissSend');
    } else if (data['source'] != null) {
      await act('showSource');
    } else if (data['pdfChoice'] != null) {
      await act('dismissPdf');
    } else if (data['detail'] != null || data['editor'] != null) {
      await act('back');
    } else {
      await act('tab', {'index': canReturnFromSection ? _sectionReturnTab : 1});
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    backend.dispose();
    super.dispose();
  }
}
