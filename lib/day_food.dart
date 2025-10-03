import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

import 'dart:convert';

class Food {
  final int? id;
  final String name;
  final int defQuantity; //in grams
  final int calories; // per 100g
  final double protein; // per 100g
  final double fat; // per 100g
  final double glucide; // per 100g

  const Food(
    this.name, {
    this.calories = 0,
    this.protein = 0.0,
    this.fat = 0.0,
    this.glucide = 0.0,
    this.defQuantity = 100,
    this.id,
  });

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'glucide': glucide,
      'defQuantity': defQuantity,
      'id': id,
    };
  }

  static Food fromMap(Map<String, Object?> map) {
    return Food(
      map['name'] as String,
      calories: map['calories'] as int,
      protein: map['protein'] as double,
      fat: map['fat'] as double,
      glucide: map['glucide'] as double,
      defQuantity: map['defQuantity'] as int,
      id: map['id'] as int,
    );
  }

  Food copyWith({
    String? inName,
    int? inCalories,
    double? inProtein,
    double? inFat,
    double? inGlucide,
    int? inDefQuantity,
    int? inId,
  }) {
    return Food(
      inName ?? name,
      calories: inCalories ?? calories,
      protein: inProtein ?? protein,
      fat: inFat ?? fat,
      glucide: inGlucide ?? glucide,
      defQuantity: inDefQuantity ?? defQuantity,
      id: inId,
    );
  }

  Food operator +(Food other) {
    return Food(
      "Sum",
      calories: calories + other.calories,
      protein: protein + other.protein,
      fat: fat + other.fat,
      glucide: glucide + other.glucide,
      defQuantity: defQuantity + other.defQuantity,
    );
  }
}

class FoodEaten {
  final int id;
  final int quantity;
  late final int hour;

  FoodEaten(this.id, this.quantity, [int? inHour]){
    hour = inHour ?? DateTime.now().hour;
  }

  Map<String, dynamic> toJson() => {'id': id, 'quantity': quantity, 'hour': hour};
  factory FoodEaten.fromJson(Map<String, dynamic> json) {
    return FoodEaten(json['id'] as int, json['quantity'] as int, (json['hour'] ?? 0) as int);
  }

  Future<Food> calculate() async {
    Food food = await FoodDB().getFood(id) ?? Food("Failed");
    final realQty = quantity / 100.0;
    return food.copyWith(
      inDefQuantity: quantity,
      inCalories: (realQty * food.calories).toInt(),
      inProtein: realQty * food.protein,
      inFat: realQty * food.fat,
      inGlucide: realQty * food.glucide,
    );
  }

  static Future<List<Food>> getFoods(List<FoodEaten> list) async {
    return Future.wait(list.map((e) => FoodDB().getFood(e.id))).then((res) {
      return res.map((e) => e ?? Food("Failed")).toList();
    });
  }
}

class FoodDB {
  static final FoodDB _instance = FoodDB._internal();
  factory FoodDB() => _instance;

  FoodDB._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    return openDatabase(
      join(await getDatabasesPath(), 'food.db'),
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE foods(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, calories INTEGER, protein REAL, fat REAL, glucide REAL, defQuantity INTEGER)',
        );
      },
    );
  }

  Future<void> insertFood(Food food) async {
    final db = await database;
    await db.insert(
      'foods',
      food.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Food>> getFoods({int? number}) async {
    final db = await database;
    final List<Map<String, Object?>> foodMaps = await db.query(
      'foods',
      limit: number,
      orderBy: "id DESC",
    );

    return [for (final map in foodMaps) Food.fromMap(map)];
  }

  Future<Food?> getFood(int id) async {
    final db = await database;
    final List<Map<String, Object?>> foodMaps = await db.query(
      'foods',
      where: "id = ?",
      whereArgs: [id],
    );

    final res = [for (final map in foodMaps) Food.fromMap(map)];

    return res.isEmpty ? null : res[0];
  }

  Future<void> deleteFood(int? id) async {
    if (id != null) {
      final db = await database;
      await db.delete('foods', where: "id = ?", whereArgs: [id]);
    }
  }

  Future<void> updateFood(Food food) async {
    final db = await database;
    await db.update(
      'foods',
      food.toMap(),
      where: "id = ?",
      whereArgs: [food.id],
    );
  }

  Future<List<Food>> search(String name) async {
    final db = await database;
    final List<Map<String, Object?>> foodMaps = await db.query(
      'foods',
      where: "name LIKE ?",
      whereArgs: ["%$name%"],
      orderBy: "id DESC",
    );

    return [for (final map in foodMaps) Food.fromMap(map)];
  }
}

class Day {
  final int day;
  final int month;
  final int year;
  final List<FoodEaten> foodIds;
  final double poids;
  final int cardio;

  final int calories;
  final int steps;

  static String formatDate(int day, int month, int year) {
    return DateFormat('dd/MM/yyyy').format(DateTime(year, month, day));
  }

  String getTitle() {
    return formatDate(day, month, year);
  }

  static int calculateID(int day, int month, int year) {
    return year * 12 * 31 + month * 31 + day;
  }

  static Future<Food> calculateMeals(List<FoodEaten> foodIds) async {
    return Future.wait(foodIds.map((e) => e.calculate())).then(
      (value) => value.fold<Food>(
        Food("init"),
        (previousValue, element) => previousValue + element,
      ),
    );
  }

  int getID() {
    return calculateID(day, month, year);
  }

  const Day(
    this.day,
    this.month,
    this.year,
    this.foodIds, {
    this.cardio = 0,
    this.poids = 0,
    this.calories = 0,
    this.steps = 0,
    String workout = ""
  });

  Map<String, Object?> toMap() {
    return {
      'id': getID(),
      "day": day,
      "month": month,
      "year": year,
      "foods": jsonEncode(foodIds.map((e) => jsonEncode(e)).toList()),
      "cardio": cardio,
      "poids": poids,
      "calories": calories,
      "steps": steps,
      "workout": "todo"
    };
  }

  static Day fromMap(Map<String, Object?> map) {
    return Day(
      map['day'] as int,
      map['month'] as int,
      map['year'] as int,
      (jsonDecode(map['foods'] as String) as List<dynamic>)
          .map((e) => FoodEaten.fromJson(jsonDecode(e)))
          .toList(),
      cardio: map['cardio'] as int,
      poids: map['poids'] as double,
      calories: map['calories'] as int,
      steps: map['steps'] as int,
      workout: (map['workout'] ?? "") as String
    );
  }

  Day copyWith({
    int? inDay,
    int? inMonth,
    int? inYear,
    List<FoodEaten>? inFoodIds,
    int? inCardio,
    double? inPoids,
    int? inCalories,
    int? inSteps,
  }) {
    return Day(
      inDay ?? day,
      inMonth ?? month,
      inYear ?? year,
      inFoodIds ?? foodIds,
      cardio: inCardio ?? cardio,
      poids: inPoids ?? poids,
      calories: inCalories ?? calories,
      steps: inSteps ?? steps,
    );
  }

  static int getTodayId() {
    DateTime date = DateTime.now();
    return calculateID(date.day, date.month, date.year);
  }

  static Future<Day> createToday() async {
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
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) {
        if(oldVersion == 1){
          return db.execute("ALTER TABLE days ADD workout TEXT;");
        }
      },
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE days(id INTEGER PRIMARY KEY, day INTEGER, month INTEGER, year INTEGER, foods TEXT, cardio INTEGER, poids REAL, calories INTEGER, steps INTEGER, workout TEXT)',
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
    final List<Map<String, Object?>> dayMaps = await db.query(
      'days',
      limit: number,
      orderBy: "id DESC",
    );

    return [for (final map in dayMaps) Day.fromMap(map)];
  }

  Future<Day?> getFirstDay() async {
    final db = await database;
    final List<Map<String, Object?>> dayMaps = await db.query(
      'days',
      limit: 1,
      orderBy: "id",
    );

    return [for (final map in dayMaps) Day.fromMap(map)].firstOrNull;
  }

  Future<Day?> getDay(int id) async {
    final db = await database;
    final List<Map<String, Object?>> dayMaps = await db.query(
      'days',
      where: "id = ?",
      whereArgs: [id],
    );

    final res = [for (final map in dayMaps) Day.fromMap(map)];

    return res.isEmpty ? null : res[0];
  }

  Future<void> deleteDay(int id) async {
    final db = await database;
    await db.delete('days', where: "id = ?", whereArgs: [id]);
  }

  Future<void> updateDay(Day day) async {
    final db = await database;
    await db.update(
      'days',
      day.toMap(),
      where: "id = ?",
      whereArgs: [day.getID()],
    );
  }

  Future<void> recalculateCal() async {
    (await getDays()).forEach(
      (e) async => insertDay(
        e.copyWith(inCalories: (await Day.calculateMeals(e.foodIds)).calories),
      ),
    );
  }
}
