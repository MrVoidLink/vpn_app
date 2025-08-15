import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePref { dark, light, system, timeBased }

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  static const _kMode = 'theme_mode';
  static const _kFromHour = 'theme_from_hour'; // default 19
  static const _kFromMin  = 'theme_from_min';  // default 0
  static const _kToHour   = 'theme_to_hour';   // default 7
  static const _kToMin    = 'theme_to_min';    // default 0

  late SharedPreferences _sp;
  AppThemePref _pref = AppThemePref.dark;

  TimeOfDay _from = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _to   = const TimeOfDay(hour: 7,  minute: 0);

  Timer? _switchTimer;

  Future<void> init() async {
    _sp = await SharedPreferences.getInstance();

    final modeIndex = _sp.getInt(_kMode);
    if (modeIndex != null && modeIndex >= 0 && modeIndex < AppThemePref.values.length) {
      _pref = AppThemePref.values[modeIndex];
    }

    _from = TimeOfDay(
      hour: _sp.getInt(_kFromHour) ?? 19,
      minute: _sp.getInt(_kFromMin) ?? 0,
    );
    _to = TimeOfDay(
      hour: _sp.getInt(_kToHour) ?? 7,
      minute: _sp.getInt(_kToMin) ?? 0,
    );

    _scheduleNextSwitchIfNeeded();
  }

  AppThemePref get preference => _pref;

  ThemeMode get themeMode {
    switch (_pref) {
      case AppThemePref.dark:
        return ThemeMode.dark;
      case AppThemePref.light:
        return ThemeMode.light;
      case AppThemePref.system:
        return ThemeMode.system;
      case AppThemePref.timeBased:
        return _isNightNow() ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Future<void> setPreference(AppThemePref pref) async {
    _pref = pref;
    await _sp.setInt(_kMode, pref.index);
    _scheduleNextSwitchIfNeeded();
    notifyListeners();
  }

  Future<void> setTimeRange(TimeOfDay from, TimeOfDay to) async {
    _from = from;
    _to = to;
    await _sp.setInt(_kFromHour, from.hour);
    await _sp.setInt(_kFromMin, from.minute);
    await _sp.setInt(_kToHour, to.hour);
    await _sp.setInt(_kToMin, to.minute);
    _scheduleNextSwitchIfNeeded();
    notifyListeners();
  }

  bool get isTimeBased => _pref == AppThemePref.timeBased;
  TimeOfDay get from => _from;
  TimeOfDay get to => _to;

  // --- helpers ---

  bool _isNightNow() {
    final now = TimeOfDay.fromDateTime(DateTime.now());
    final start = _from;
    final end = _to;

    bool isAfterStart = _compare(now, start) >= 0;
    bool isBeforeEnd  = _compare(now, end) <= 0;

    final crossesMidnight = _compare(end, start) < 0; // e.g. 19 → 07

    if (crossesMidnight) {
      // شب از start تا 23:59 و از 00:00 تا end
      return isAfterStart || isBeforeEnd;
    } else {
      // بازه داخل یک روز
      return isAfterStart && isBeforeEnd;
    }
  }

  int _compare(TimeOfDay a, TimeOfDay b) {
    final aMins = a.hour * 60 + a.minute;
    final bMins = b.hour * 60 + b.minute;
    return aMins.compareTo(bMins);
  }

  void _scheduleNextSwitchIfNeeded() {
    _switchTimer?.cancel();
    if (_pref != AppThemePref.timeBased) return;

    final now = DateTime.now();
    final nextBoundary = _nextBoundaryDateTime(now);
    final diff = nextBoundary.difference(now);
    _switchTimer = Timer(diff, () {
      // در لحظه‌ی مرز، حالت عوض می‌شود
      notifyListeners();
      // مرز بعدی را هم زمان‌بندی کن
      _scheduleNextSwitchIfNeeded();
    });
  }

  DateTime _nextBoundaryDateTime(DateTime fromTime) {
    DateTime toDate(TimeOfDay t, DateTime base) =>
        DateTime(base.year, base.month, base.day, t.hour, t.minute);

    final a = toDate(_from, fromTime);
    final b = toDate(_to, fromTime);

    final crossesMidnight = _compare(_to, _from) < 0;

    final candidates = <DateTime>[];
    candidates.add(a.isAfter(fromTime) ? a : a.add(const Duration(days: 1)));
    final bAdj = crossesMidnight && !b.isAfter(fromTime)
        ? b.add(const Duration(days: 1))
        : (b.isAfter(fromTime) ? b : b.add(const Duration(days: 1)));
    candidates.add(bAdj);

    candidates.sort();
    return candidates.first;
  }
}
