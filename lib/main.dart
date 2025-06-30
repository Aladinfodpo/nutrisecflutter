import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user.dart';
import 'food.dart';
import 'day.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  User().loadFromData(prefs);

  runApp(const MyApp());
}

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


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: createMaterialColor(Color.fromRGBO(26, 54, 35, 1))),
      ),
      routes: routePages,
      initialRoute: "/",
    );
  }
}

var routePages = {
      '/' : (BuildContext context) => MainPage(null,),
      SettingsPage.routeName: (BuildContext context) => MainPage(0),
      AddFoodPage.routeName: (BuildContext context) => AddFoodPage(food: ((ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{}) as Map)['food'])
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
  String title = titles[0];

  void setIndexPage(int i){setState((){indexDrawer = i; title = titles[i]; });}

  @override
  void initState() {
    super.initState();
    setIndexPage(widget.indexPage ?? 0);
    pages = [
      HomePage(),
      DaysPage(),
      FoodsPage(),
      SettingsPage(),
    ];
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
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Image.asset("icon.png"),
            ),
            ] +List.generate(titles.length, (index){return ListTile(title: Text(titles[index]), onTap: () {setIndexPage(index); Navigator.pop(context);},);}).toList(),
        ),
      ),
      body: Center(
        child: pages[indexDrawer],
      ),
      floatingActionButton: indexDrawer == 0 ? FloatingActionButton(
        onPressed: (){},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      )
      : null, // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  _HomePageState();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Center(child: 
        Padding(padding: EdgeInsets.all(8.0),
          child: Text("Bienvenue")
        )
      );
  }
}