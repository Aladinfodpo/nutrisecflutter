import 'package:nutrisec/notification.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'dart:async';

import 'day_food.dart';
import 'user.dart';

@pragma('vm:entry-point')
class Pedo {
  late int lastStepNumber;

  static final Pedo _singleton = Pedo._internal();

  factory Pedo() {
    return _singleton;
  }

  Pedo._internal();

  @pragma('vm:entry-point')
  Future<void> loadFromData(SharedPreferences pref) async {
    final read = pref.getInt("lastStepNumber");

    // First start
    if (read == null) {
      return resetLastStepToNow();
    } else {
      lastStepNumber = read;
    }
  }

  @pragma('vm:entry-point')
  Future<void> save() async {
    final pref = await SharedPreferences.getInstance();
    pref.setInt("lastStepNumber", lastStepNumber);
  }

  @pragma('vm:entry-point')
  Future<int> _getStepNumber() {
    final completer = Completer<int>();
    final stream = Pedometer.stepCountStream;
    StreamSubscription<StepCount>? sub;
    sub = stream.listen((event) {
      completer.complete(event.steps);
      sub?.cancel();
    });

    return completer.future;
  }

  @pragma('vm:entry-point')
  Future<void> resetLastStepToNow() async {
    return _getStepNumber().then((res) {
      lastStepNumber = res;
      return save();
    });
  }

  Future<int> safeGetTodayStep() {
    return User().isEmulator ? Future<int>.value(1000) : _getTodayStep();
  }

  @pragma('vm:entry-point')
  Future<int> _getTodayStep() {
    return _getStepNumber().then((value) {
      if (value < lastStepNumber) {
        // Phone have restarted, lost count we need to reset
        lastStepNumber = value;
        NotificationHelper().post(
          "Step update",
          "Rebooted device let to error.",
          1,
        );
        return save().then((res) => 0);
      }
      return value - lastStepNumber;
    });
  }

  @pragma('vm:entry-point')
  Future<void> midnightReset() async {
    Day day =
        await DayDB().getDay(Day.getTodayId() - 1) ??
        (await Day.createToday()).copyWith(inDay: DateTime.now().day - 1);
    await NotificationHelper().post("Step update", "Midnight step reset, you walked ${await _getTodayStep()} steps today.");
    await DayDB().insertDay(day.copyWith(inSteps: await _getTodayStep()));
    return resetLastStepToNow();
  }

  @pragma('vm:entry-point')
  static Future<void> resetStepsMidnight() async {
    await NotificationHelper().init();
    
    await Pedo().loadFromData(await SharedPreferences.getInstance());
    await Pedo().midnightReset();
  }

  Future<void> ensureAlarms(SharedPreferences pref, [bool forceAlarm = false]) {
    if ((pref.getBool("hasAlarm") ?? false) && !forceAlarm) {
      return Future<void>.value();
    }

    AndroidAlarmManager.cancel(0);

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1, 0, 1);
    //final midnight = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    final durationUntilMidnight = midnight.difference(now);
    NotificationHelper().post("Step update", "Reset programmed in ${durationUntilMidnight.inMinutes} minutes.");
    pref.setBool("hasAlarm", true);

    return AndroidAlarmManager.periodic(
      Duration(days: 1),
      0, // Alarm ID
      resetStepsMidnight,
      startAt: DateTime.now().add(durationUntilMidnight),
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }
}
