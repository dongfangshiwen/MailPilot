/// Applies ordered native stream frames without decoding all history per token.
/// The channel's initial frame and every structural change contain a full state.
class StreamStateDecoder {
  Map<String, dynamic>? _state;
  int _sequence = 0;
  String? _epoch;

  Map<String, dynamic> decode(Map<String, dynamic> frame) {
    if (frame['streamFrame'] != 1) return frame; // Older native/preview hosts.
    final sequence = frame['sequence'] as int;
    final epoch = frame['epoch'] as String?;
    if (_state != null &&
        epoch != null &&
        epoch == _epoch &&
        sequence <= _sequence) {
      return _state!;
    }
    if (frame['state'] case final Map snapshot) {
      _epoch = epoch;
      _sequence = sequence;
      return _state = Map<String, dynamic>.from(snapshot);
    }
    final old = _state;
    if (old == null ||
        epoch != _epoch ||
        frame['base'] != _sequence ||
        sequence != _sequence + 1 ||
        old['activeAccount'] != frame['account'] ||
        old['conversationId'] != frame['conversation'] ||
        old['responseId'] != frame['response']) {
      throw const FormatException('流式界面状态已失步，请重新打开当前对话。');
    }
    final reasoning = Map<String, dynamic>.from(frame['reasoning'] as Map);
    final oldReasoning = old['reasoning'] as Map;
    reasoning['previous'] ??= oldReasoning['previous'] ?? [];
    reasoning['text'] = _text(
      oldReasoning['text'] as String,
      reasoning['text'] as Map,
    );
    final next = <String, dynamic>{
      ...old,
      'streaming': _text(old['streaming'] as String, frame['streaming'] as Map),
      'reasoning': reasoning,
      'draftPartial': frame['draftPartial'],
    };
    _sequence = sequence;
    return _state = next;
  }

  String _text(String previous, Map change) {
    final at = change['at'];
    if (at == 0) return change['text'] as String;
    if (at != previous.length) {
      throw const FormatException('流式内容未完整接收，请重新打开当前对话。');
    }
    return previous + (change['text'] as String);
  }
}
