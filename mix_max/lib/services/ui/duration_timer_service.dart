import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Where a duration parameter's countdown is in its lifecycle.
///   • [idle]    no timer for this parameter — only a "Start" affordance shows
///   • [running] counting down; the end instant is what's persisted
///   • [paused]  frozen with a fixed number of seconds left
///   • [done]    the countdown has reached zero
enum TimerStatus { idle, running, paused, done }

/// An immutable read of one duration timer at a moment in time. [remainingSeconds]
/// is always derived (recomputed from the stored end instant for a running
/// timer), so a snapshot taken after the app was closed for a while reflects the
/// real elapsed time rather than a stale stored count.
class DurationTimerSnapshot {
  final TimerStatus status;

  /// The full duration the timer counts down from, in seconds. Kept across
  /// pauses so "Reset" can re-arm it to the top.
  final int totalSeconds;

  /// Whole seconds left, rounded up while running. Zero once [done].
  final int remainingSeconds;

  const DurationTimerSnapshot({
    required this.status,
    required this.totalSeconds,
    required this.remainingSeconds,
  });

  static const DurationTimerSnapshot idle = DurationTimerSnapshot(
    status: TimerStatus.idle,
    totalSeconds: 0,
    remainingSeconds: 0,
  );

  /// True while a timer exists and is counting or frozen (not idle / done).
  bool get isLive =>
      status == TimerStatus.running || status == TimerStatus.paused;
}

/// Persists per-parameter countdown timers so a duration suggestion's timer keeps
/// running while the app is backgrounded or fully closed, and resumes correctly
/// on return.
///
/// State lives in [SharedPreferences] keyed by an opaque caller-supplied key (the
/// parameter id). A *running* timer stores only the absolute end instant
/// (epoch ms); remaining time is recomputed on every [read], which is what lets a
/// timer survive the app being killed. A *paused* timer stores the frozen seconds
/// left instead.
///
/// Registered as a get_it singleton; await [ready] once before the first [read].
class DurationTimerService {
  SharedPreferences? _prefs;
  Future<void>? _readyFuture;

  /// Completes once the backing store is loaded. Cheap to await repeatedly.
  Future<void> get ready => _readyFuture ??= _init();

  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String _storeKey(String key) => 'duration_timer_$key';

  int get _now => DateTime.now().millisecondsSinceEpoch;

  /// The current state of the timer under [key]. Synchronous, so a 1-second
  /// ticker can call it freely — but only meaningful after [ready] resolves;
  /// before that it reports [DurationTimerSnapshot.idle].
  DurationTimerSnapshot read(String key) {
    final prefs = _prefs;
    if (prefs == null) return DurationTimerSnapshot.idle;
    final raw = prefs.getString(_storeKey(key));
    if (raw == null) return DurationTimerSnapshot.idle;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    final total = (map['total'] as num?)?.toInt() ?? 0;
    switch (map['status'] as String?) {
      case 'running':
        final end = (map['end'] as num?)?.toInt() ?? _now;
        final remaining = ((end - _now) / 1000).ceil();
        if (remaining <= 0) {
          return DurationTimerSnapshot(
            status: TimerStatus.done,
            totalSeconds: total,
            remainingSeconds: 0,
          );
        }
        return DurationTimerSnapshot(
          status: TimerStatus.running,
          totalSeconds: total,
          remainingSeconds: remaining,
        );
      case 'paused':
        return DurationTimerSnapshot(
          status: TimerStatus.paused,
          totalSeconds: total,
          remainingSeconds: (map['remaining'] as num?)?.toInt() ?? total,
        );
      case 'done':
        return DurationTimerSnapshot(
          status: TimerStatus.done,
          totalSeconds: total,
          remainingSeconds: 0,
        );
      default:
        return DurationTimerSnapshot.idle;
    }
  }

  void _write(String key, Map<String, dynamic> map) =>
      _prefs?.setString(_storeKey(key), jsonEncode(map));

  /// Begins counting down [seconds] (out of a [total]-second timer). Used both
  /// to start a fresh timer (seconds == total) and to resume a paused one
  /// (seconds == the frozen remainder).
  void start(String key, {required int seconds, required int total}) {
    _write(key, {
      'status': 'running',
      'total': total,
      'end': _now + seconds * 1000,
    });
  }

  /// Freezes a running timer at its current remaining time.
  void pause(String key) {
    final snap = read(key);
    _write(key, {
      'status': 'paused',
      'total': snap.totalSeconds,
      'remaining': snap.remainingSeconds,
    });
  }

  /// Pins the timer in the finished state so reopening the card still shows
  /// "Done" rather than recomputing a negative remainder.
  void markDone(String key) {
    final snap = read(key);
    _write(key, {'status': 'done', 'total': snap.totalSeconds});
  }

  /// Clears the timer entirely — back to the bare "Start" affordance.
  void clear(String key) => _prefs?.remove(_storeKey(key));
}
