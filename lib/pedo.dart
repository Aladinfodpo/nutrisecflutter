import 'package:nutrisec/notification.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'dart:async';

import 'day_food.dart';

@pragma('vm:entry-point')
class Pedo {
  late int lastStepNumber;
  bool needsReset = false;

  static final Pedo _singleton = Pedo._internal();

  factory Pedo() {
    return _singleton;
  }

  Pedo._internal();

  Future<void> loadFromData(SharedPreferences pref) async {
    final read = pref.getInt("lastStepNumber");
    needsReset = pref.getBool("needsReset") ?? false;

    // First start
    if (read == null) {
      lastStepNumber = 0;
      return resetLastStepToNow();
    } else {
      lastStepNumber = read;
    }
  }

  Future<bool> _isEmulator() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return !androidInfo.isPhysicalDevice;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return !iosInfo.isPhysicalDevice;
    }
    return false;
  }

  Future<void> save() async {
    final pref = await SharedPreferences.getInstance();
    pref.setInt("lastStepNumber", lastStepNumber);
    pref.setBool("needsReset", needsReset);
  }

  Future<int> _getStepNumber() async {
    if (kReleaseMode || !await _isEmulator()) {
      final completer = Completer<int>();
      final stream = Pedometer.stepCountStream;
      StreamSubscription<StepCount>? sub;
      sub = stream.listen((event) {
        completer.complete(event.steps);
        sub?.cancel();
      });

      return completer.future;
    } else {
      return Future<int>.value(100);
    }
  }

  Future<void> resetLastStepToNow() async {
    return _getStepNumber().then((res) {
      lastStepNumber = res;
      return save();
    });
  }

  Future<int> getTodayStep() {
    return _getStepNumber().then((value) {
      if (lastStepNumber == 0 || value < lastStepNumber) {
        // Phone have restarted, lost count we need to reset
        lastStepNumber = value;

        return save().then((res) => 0);
      }
      return value - lastStepNumber;
    });
  }

  Future<void> treatLastReset([bool force = false]) async {
    if (force || needsReset) {
      Day day =
          await DayDB().getDay(Day.getTodayId() - 1) ??
          (await Day.createToday()).copyWith(inDay: DateTime.now().day - 1);
      await DayDB().insertDay(day.copyWith(inSteps: await getTodayStep()));
      needsReset = false;
      await NotificationHelper().post(
        "Step update",
        "Yesterday steps have been updated.",
      );
      return resetLastStepToNow();
    }
  }

  static Future<void> resetStepsMidnight() async {
    await Pedo().loadFromData(await SharedPreferences.getInstance());
    Pedo().needsReset = true;
    return Pedo().save();
  }

  Future<void> ensureAlarms(SharedPreferences pref, [bool forceAlarm = false]) {
    if ((pref.getBool("hasAlarm") ?? false) && !forceAlarm) {
      return Future<void>.value();
    }
    final now = DateTime.now();
    final tomorrowMidnight = DateTime(now.year, now.month, now.day + 1);

    return Workmanager().registerPeriodicTask(
      "dailyMidnightTask", // unique name
      "midnightTask", // task name handled in callback
      frequency: const Duration(hours: 24),
      initialDelay: tomorrowMidnight.difference(now),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }
}
