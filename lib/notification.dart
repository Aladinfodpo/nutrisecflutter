import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
class NotificationHelper {
  bool isInit = false;
  late final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  static final NotificationHelper _singleton = NotificationHelper._internal();
  
  factory NotificationHelper() {
    return _singleton;
  }
  
  NotificationHelper._internal();

  @pragma('vm:entry-point')
  Future<void> init() async{
    if(!isInit){
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      
      isInit = true;
      return flutterLocalNotificationsPlugin.initialize(initializationSettings).then((value) => Future.value(),); 
    }
    return Future.value();
  }

  @pragma('vm:entry-point')
  Future<void> post(String title, String description, [int id = 0, String? payload]) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'general_channel', 'General Notification',
    channelDescription: 'Notifications for NutriSec',
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    id,
    title,
    description,
    platformChannelSpecifics,
    payload: payload,
  );
}
}