import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'user.dart';
import 'food_edit.dart';
import 'day_edit.dart';
import 'day_food.dart';
import 'pedo.dart';
import 'custom_utils.dart';
import 'notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestNotificationPermission();
  await requestActivityPermission();
  await requestExactAlarmPermission();
  await AndroidAlarmManager.initialize();

  final prefs = await SharedPreferences.getInstance();
  await User().loadFromData(prefs);

  await NotificationHelper().init();

  if (!User().isEmulator) {
    await Pedo().loadFromData(prefs);
    await Pedo().ensureAlarms(prefs);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: createMaterialColor(Color.fromRGBO(26, 54, 35, 1)),
        ),
      ),
      routes: routePages,
      initialRoute: "/",
    );
  }
}

var routePages = {
  '/': (BuildContext context) => MainPage(null),
  SettingsPage.routeName: (BuildContext context) => MainPage(0),
  AddFoodPage.routeName:
      (BuildContext context) => AddFoodPage(
        food:
            ((ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{})
                as Map)['food'],
      ),
  EditDayPage.routeName:
      (BuildContext context) => EditDayPage(
        day:
            ((ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{})
                as Map)['day'],
      ),
};

class MainPage extends StatefulWidget {
  const MainPage(this.indexPage, {super.key});

  final int? indexPage;

  @override
  State<MainPage> createState() => _MainPageState();
}

const titles = ["Home", "Days", "Foods", "Settings"];

class _MainPageState extends State<MainPage> {
  late final List<Widget> pages;
  int indexDrawer = 0;

  void setIndexPage(int i) {
    setState(() {
      indexDrawer = i;
    });
  }

  @override
  void initState() {
    super.initState();
    setIndexPage(widget.indexPage ?? 0);
    pages = [HomePage(), DaysPage(), FoodsPage(), SettingsPage()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(titles[indexDrawer]),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children:
              <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Image.asset("icon.png"),
                ),
              ] +
              List.generate(titles.length, (index) {
                return ListTile(
                  title: Text(titles[index]),
                  onTap: () {
                    setIndexPage(index);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
        ),
      ),
      body: Center(child: pages[indexDrawer]),
      /*floatingActionButton:
          indexDrawer == 1
              ? FloatingActionButton(
                onPressed: () async {
                  if (indexDrawer == 1 && mounted) {
                    Navigator.pushNamed(
                      context,
                      EditDayPage.routeName,
                      arguments: {"day": await Day.createToday()},
                    );
                  }
                },
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              )
              : null,*/ 
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? step;
  _HomePageState();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
  }

  void refresh() {
    setState(() {
      step = null;
    });
    Pedo().safeGetTodayStep().then((res) {
      setState(() => step = res);
    });
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text("Bienvenue"),
            step == null
                ? CircularProgressIndicator()
                : Text("You have walked ${step!} step today !"),
            ElevatedButton(onPressed: refresh, child: const Text("Reload")),
          ],
        ),
      ),
    );
  }
}
