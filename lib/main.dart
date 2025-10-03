import 'package:flutter/material.dart';
import 'package:nutrisec/stats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'stats.dart';
import 'user.dart';
import 'food_edit.dart';
import 'day_edit.dart';
import 'day_food.dart';
import 'pedo.dart';
import 'custom_utils.dart';
import 'notification.dart';
import 'dart:io';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "midnightTask") {
      Pedo.resetStepsMidnight();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestNotificationPermission();
  await requestActivityPermission();
  await requestReminders();

  await NotificationHelper().init();

  final prefs = await SharedPreferences.getInstance();
  await User().loadFromData(prefs);
  await Pedo().loadFromData(prefs);

  if (Platform.isAndroid) {
    await Workmanager().initialize(callbackDispatcher);
    //await Pedo().ensureAlarms(prefs, true);
    await Pedo().treatLastReset();
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
  StatsPage.routeName: (BuildContext context) => StatsPage(),
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

const titles = ["Home", "Days", "Stats", "Foods", "Settings"];

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
    pages = [HomePage(), DaysPage(), StatsPage(), FoodsPage(), SettingsPage()];
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
  List<Day> days = [];
  Day? firstDay;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
  }

  void refreshStep() {
    setState(() {
      step = null;
    });
    Pedo().getTodayStep().then((res) {
      setState(() => step = res);
    });
  }

  void refreshDays() {
    setState(() {
      days = [];
    });
    DayDB().getDays(number: 5).then((value) {
      setState(() {
        days = value.reversed.toList();
      });
    });
    DayDB().getFirstDay().then((value){
      setState(() {
        firstDay = value;
      });
  });
  }

  @override
  void initState() {
    super.initState();
    refreshStep();
    refreshDays();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            step == null
                ? CircularProgressIndicator()
                : Text("You have walked ${step!} step today !"),
            ElevatedButton(onPressed: refreshStep, child: const Text("Reload")),
            SizedBox(height: 20),
            Card(
              child: days.isEmpty ? const Text("No weight data") : Column(
                children: [
                  Text("Weight over the last ${days.length} days"),
                  Padding(
                    padding: EdgeInsetsGeometry.directional(start: 8.0),
                    child: CustomPaint(
                      size: Size(200, 200),
                      painter: CurvePainter(
                        days
                            .map(
                              (day) =>
                                  DataCurve(day.getID().toDouble(), day.poids),
                            )
                            .toList(),
                            firstDay == null ? null : firstDay!.poids - User().objectif.toDouble()
                      ),
                    ),
                  ),
                  firstDay == null ? SizedBox() : Text("Objectif reached in ${getTimeToObj(firstDay!, days.last).inDays} days")
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
