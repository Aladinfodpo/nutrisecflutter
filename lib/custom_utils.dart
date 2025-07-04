import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

MaterialColor createMaterialColor(Color color) {
  List<double> strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = (color.r*255).toInt(), g = (color.g*255).toInt(), b = (color.b*255).toInt();

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }

  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }

  return MaterialColor(color.toARGB32(), swatch);
}

Future<bool> requestNotificationPermission() async {
  var status = await Permission.notification.status;
  if (!status.isGranted) {
    status = await Permission.notification.request();
  }
  return status.isGranted;
}

Future<bool> requestActivityPermission() async {
  var status = await Permission.activityRecognition.status;
  if (!status.isGranted) {
    status = await Permission.activityRecognition.request();
  }
  return status.isGranted;
}

Future<bool> requestExactAlarmPermission() async {
  var status = await Permission.scheduleExactAlarm.status;
  if (!status.isGranted) {
    status = await Permission.scheduleExactAlarm.request();
  }
  return status.isGranted;
}


