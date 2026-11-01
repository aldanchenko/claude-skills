import 'package:flutter/foundation.dart';

class DayLog {
  final DateTime day;
  final int glasses;

  const DayLog(this.day, this.glasses);
}

/// In-memory store; a real app would persist it.
class WaterStore extends ChangeNotifier {
  WaterStore._();
  static final instance = WaterStore._();

  int goal = 8;
  int today = 3;
  bool reminders = true;

  void addGlass() {
    today++;
    notifyListeners();
  }

  void setGoal(int value) {
    goal = value;
    notifyListeners();
  }

  void setReminders(bool value) {
    reminders = value;
    notifyListeners();
  }

  /// Past days, newest first. Throws when the history can't be read.
  Future<List<DayLog>> loadHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return [
      for (var i = 1; i <= 14; i++)
        DayLog(DateTime(now.year, now.month, now.day - i), (i * 5) % 9 + 2),
    ];
  }
}
