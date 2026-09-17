import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recording_model.dart';
import '../utils/meditation_day.dart';

/// Local persistence for Today's Meditation (device id, active card, history).
class DailyMeditationStore {
  DailyMeditationStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const _prefsKey = 'daily_meditation_state_v1';
  static const historyLimit = 21;

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    final override = _prefsOverride;
    if (override != null) return override;
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static String newDeviceId() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final s = bytes.map(hex).join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-'
        '${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
  }

  Future<DailyMeditationState> load() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      final state = DailyMeditationState(deviceId: newDeviceId());
      await save(state);
      return state;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return DailyMeditationState.fromJson(decoded);
      }
    } catch (_) {}
    final state = DailyMeditationState(deviceId: newDeviceId());
    await save(state);
    return state;
  }

  Future<void> save(DailyMeditationState state) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }
}

class DailyMeditationState {
  DailyMeditationState({
    required this.deviceId,
    this.active,
    List<DailyMeditationHistoryItem>? history,
  }) : history = List.unmodifiable(history ?? const []);

  final String deviceId;
  final DailyMeditationActive? active;
  final List<DailyMeditationHistoryItem> history;

  List<Map<String, String>> excludePayload({bool includeActive = true}) {
    final out = <Map<String, String>>[];
    final seen = <String>{};
    void add(String videoId, String timestamp) {
      final key = '$videoId|$timestamp';
      if (videoId.isEmpty || timestamp.isEmpty || seen.contains(key)) return;
      seen.add(key);
      out.add({'video_id': videoId, 'timestamp': timestamp});
    }

    for (final item in history) {
      add(item.videoId, item.timestamp);
    }
    if (includeActive && active != null) {
      add(active!.result.videoId, active!.result.timestamp);
    }
    return out;
  }

  /// Whether we should call the API for a new recommendation.
  bool needsFetch(DateTime now) {
    final current = active;
    if (current == null) return true;
    if (current.playedAt == null) return false;
    return MeditationDay.isLaterDayThan(current.playedMeditationDayId, now);
  }

  DailyMeditationState copyWith({
    String? deviceId,
    DailyMeditationActive? active,
    List<DailyMeditationHistoryItem>? history,
    bool clearActive = false,
  }) {
    return DailyMeditationState(
      deviceId: deviceId ?? this.deviceId,
      active: clearActive ? null : (active ?? this.active),
      history: history ?? this.history,
    );
  }

  factory DailyMeditationState.fromJson(Map<String, dynamic> json) {
    final historyRaw = json['history'];
    final history = <DailyMeditationHistoryItem>[];
    if (historyRaw is List) {
      for (final item in historyRaw) {
        if (item is Map<String, dynamic>) {
          history.add(DailyMeditationHistoryItem.fromJson(item));
        }
      }
    }
    DailyMeditationActive? active;
    final activeRaw = json['active'];
    if (activeRaw is Map<String, dynamic>) {
      active = DailyMeditationActive.fromJson(activeRaw);
    }
    var deviceId = (json['deviceId'] as String?)?.trim() ?? '';
    if (deviceId.isEmpty) deviceId = DailyMeditationStore.newDeviceId();
    return DailyMeditationState(
      deviceId: deviceId,
      active: active,
      history: history,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        if (active != null) 'active': active!.toJson(),
        'history': history.map((e) => e.toJson()).toList(),
      };
}

class DailyMeditationActive {
  const DailyMeditationActive({
    required this.result,
    required this.assignedAt,
    required this.assignedMeditationDayId,
    this.playedAt,
    this.playedMeditationDayId,
  });

  final RecordingResult result;
  final DateTime assignedAt;
  final String assignedMeditationDayId;
  final DateTime? playedAt;
  final String? playedMeditationDayId;

  bool get wasPlayed => playedAt != null;

  DailyMeditationActive copyWith({
    RecordingResult? result,
    DateTime? assignedAt,
    String? assignedMeditationDayId,
    DateTime? playedAt,
    String? playedMeditationDayId,
  }) {
    return DailyMeditationActive(
      result: result ?? this.result,
      assignedAt: assignedAt ?? this.assignedAt,
      assignedMeditationDayId:
          assignedMeditationDayId ?? this.assignedMeditationDayId,
      playedAt: playedAt ?? this.playedAt,
      playedMeditationDayId:
          playedMeditationDayId ?? this.playedMeditationDayId,
    );
  }

  factory DailyMeditationActive.fromJson(Map<String, dynamic> json) {
    final card = json['card'];
    if (card is! Map<String, dynamic>) {
      throw const FormatException('active.card missing');
    }
    return DailyMeditationActive(
      result: RecordingResult.fromJson(card),
      assignedAt: DateTime.tryParse('${json['assignedAt']}') ?? DateTime.now(),
      assignedMeditationDayId:
          (json['assignedMeditationDayId'] as String?) ?? '',
      playedAt: json['playedAt'] != null
          ? DateTime.tryParse('${json['playedAt']}')
          : null,
      playedMeditationDayId: json['playedMeditationDayId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'card': result.toJson(),
        'assignedAt': assignedAt.toIso8601String(),
        'assignedMeditationDayId': assignedMeditationDayId,
        if (playedAt != null) 'playedAt': playedAt!.toIso8601String(),
        if (playedMeditationDayId != null)
          'playedMeditationDayId': playedMeditationDayId,
      };
}

class DailyMeditationHistoryItem {
  const DailyMeditationHistoryItem({
    required this.videoId,
    required this.timestamp,
    this.playedAt,
  });

  final String videoId;
  final String timestamp;
  final DateTime? playedAt;

  factory DailyMeditationHistoryItem.fromJson(Map<String, dynamic> json) {
    return DailyMeditationHistoryItem(
      videoId: (json['videoId'] ?? json['video_id'] ?? '') as String,
      timestamp: (json['timestamp'] ?? '') as String,
      playedAt: json['playedAt'] != null
          ? DateTime.tryParse('${json['playedAt']}')
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'timestamp': timestamp,
        if (playedAt != null) 'playedAt': playedAt!.toIso8601String(),
      };
}
