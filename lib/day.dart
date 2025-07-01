import 'package:nutrisec/food.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'user.dart';

class Day {
    final int day;
    final int month;
    final int year;
    final List<FoodEaten> foodIds;
    final double poids;
    final int cardio;

    final int calories;
    final int steps;

    static String formatDate(int day, int month, int year){
      return "$day/$month/$year";
    }

    String getTitle(){
      return formatDate(day, month, year);
    }

    static int calculateID(int day, int month, int year){
      return year*12*31 + month*31 + day;
    }

    int getID(){
      return calculateID(day, month, year);
    }

    const Day(this.day, this.month, this.year, this.foodIds, {this.cardio = 0, this.poids = 0, this.calories = 0, this.steps = 0});

    Map<String, Object?> toMap() {
        return {'id': getID(), "day" : day, "month" : month, "year" : year, "foods" : jsonEncode(foodIds), "cardio" : cardio, "poids" : poids, "calories" : calories, "steps" : steps};
    }

    static Day fromMap(Map<String, Object?> map){
        return Day(map['day'] as int, map['month'] as int, map['year'] as int, jsonDecode(map['foods'] as String), cardio : map['cardio'] as int, poids : map['poids'] as double, calories : map['calories'] as int, steps: map['steps'] as int);
    }

    Day copyWith(int? inDay, int? inMonth, int? inYear, List<FoodEaten>? inFoodIds, {int? inCardio, double? inPoids, int? inCalories, int? inSteps}){
      return Day(
        inDay ?? day,
        inMonth ?? month,
        inYear ?? year,
        inFoodIds ?? foodIds,
        cardio: inCardio ?? cardio,
        poids: inPoids ?? poids,
        calories: inCalories ?? calories,
        steps: inSteps ?? steps
      );
    }

    static Future<Day> createToday() async{
      DateTime date = DateTime.now();
      final yesterday = await DayDB().getDays(number: 1);
      final poids = yesterday.isEmpty ? 0.0 : yesterday[0].poids; 
      return Day(date.day, date.month, date.year, [], poids: poids);
    }
}

class DayDB {
  static final DayDB _instance = DayDB._internal();
  factory DayDB() => _instance;

  DayDB._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    return openDatabase(
      join(await getDatabasesPath(), 'day.db'),
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE days(id INTEGER PRIMARY KEY, day INTEGER, month INTEGER, year INTEGER, foods TEXT, cardio INTEGER, poids REAL, calories INTEGER, steps INTEGER)',
        );
      },
    );
  }

  Future<void> insertDay(Day day) async {
    final db = await database;
    await db.insert(
      'days',
      day.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Day>> getDays({int? number}) async {
    final db = await database;
    final List<Map<String, Object?>> dayMaps = await db.query('days', limit: number, orderBy: "id DESC");

    return [
      for (final map in dayMaps)
        Day.fromMap(map),
    ];
  }

  Future<Day?> getDay(int id) async {
    final db = await database;
    final List<Map<String, Object?>> dayMaps = await db.query('days', where: "id = ?", whereArgs: [id]);

    final res =[
      for (final map in dayMaps)
        Day.fromMap(map),
    ];

    return res.isEmpty ? null : res[0];
  }

  Future<void> deleteDay(int id) async {
    final db = await database;
    await db.delete('days', where: "id = ?", whereArgs: [id]);
  }

  Future<void> updateDay(Day day) async {
    final db = await database;
    await db.update('days', day.toMap(), where: "id = ?", whereArgs: [day.getID()]);
  }

}

class DaysPage extends StatefulWidget {
  const DaysPage({super.key});

  @override
  State<DaysPage> createState() => _DaysPageState();
}

class _DaysPageState extends State<DaysPage> {
   bool loading = true;
   List<Day> days = [Day(11,11,1998,[], calories: 1500), Day(12,11,1998,[], calories: 1500),];
   _DaysPageState();
   
   void refresh(){
    DayDB().getDays().then((res){setState((){/*days = res;*/ loading = false;});});
   }

   @override
   void initState(){
    super.initState();

    refresh();
   }

  @override
  Widget build(BuildContext context) {
    return loading ? CircularProgressIndicator() : 
      ListView(scrollDirection: Axis.vertical,
        children: 
          days.map((day){
            return SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(6.0),
                  child:Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day.getTitle()),
                      Text('${day.calories}/${User().baseCal} kcal')
                    ],
                  )
                ),
              )
            );
          }).toList()
      );
  }

}

class EditDayPage extends StatefulWidget {
  const EditDayPage({super.key, required this.day});

  static const String routeName = "editDay";
  final Day day;

  @override
  State<EditDayPage> createState() => _EditDayPageState();
}

class _EditDayPageState extends State<EditDayPage> {
  _EditDayPageState();
  late int day;
  late int month;
  late int year;
  late final List<FoodEaten> foods;

  @override
  void initState() {
    super.initState();

    foods = widget.day.foodIds;
    day = widget.day.day;
    month = widget.day.month;
    year = widget.day.year;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () async {
            final DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime(year, month, day), firstDate: DateTime(2025), lastDate: DateTime(2100),);
            if(pickedDate != null){
              day = pickedDate.day;
              month = pickedDate.month;
              year = pickedDate.year;
            }
          },
          child: Card(
            child: Text(Day.formatDate(day, month, year)),
          ),
        )
      ],
    );
  }
}