import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';

class Food {
    final int? id;
    final String name;
    final int defQuantity; //in grams
    final int calories; // per 100g
    final double protein; // per 100g
    final double fat; // per 100g
    final double glucide; // per 100g

    const Food(this.name, {this.calories = 0, this.protein = 0.0, this.fat = 0.0, this.glucide = 0.0, this.defQuantity = 100, this.id});

    Map<String, Object?> toMap() {
        return {'name': name, 'calories' : calories, 'protein' : protein, 'fat' : fat, 'glucide' : glucide, 'defQuantity': defQuantity, 'id' : id};
    }

    static Food fromMap(Map<String, Object?> map){
        return Food(map['name'] as String, calories: map['calories'] as int, protein: map['protein'] as double, fat: map['fat'] as double, glucide: map['glucide'] as double, defQuantity: map['defQuantity'] as int, id: map['id'] as int,);
    }

    Food copyWith({String? inName, int? inCalories, double? inProtein, double? inFat, double? inGlucide, int? inDefQuantity, int? inId}){
      return Food(
        inName ?? name,
        calories: inCalories ?? calories,
        protein: inProtein ?? protein,
        fat: inFat ?? fat,
        glucide: inGlucide ?? glucide,
        defQuantity: inDefQuantity ?? defQuantity,
        id: inId
      );
    }

    Food operator +(Food other) { return Food(
      "Sum",
      calories: calories + other.calories,
      protein: protein + other.protein,
      fat: fat + other.fat,
      glucide: glucide + other.glucide,
      defQuantity: defQuantity + other.defQuantity,
    );}
}

class FoodEaten {
  final int id;
  final int quantity;
  
  const FoodEaten(this.id, this.quantity);

  Future<Food> calculate() async {
    Food food = await FoodDB().getFood(id) ?? Food("Failed");
    final realQty = quantity/100.0 ;
    return food.copyWith(
      inDefQuantity: quantity,
      inCalories: (realQty * food.calories).toInt(),
      inProtein:  realQty * food.protein,
      inFat:      realQty * food.fat,
      inGlucide:  realQty * food.glucide,
    );
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
    final List<Map<String, Object?>> foodMaps = await db.query('foods', limit: number, orderBy: "id DESC");

    return [
      for (final map in foodMaps)
        Food.fromMap(map),
    ];
  }

  Future<Food?> getFood(int id) async {
    final db = await database;
    final List<Map<String, Object?>> foodMaps = await db.query('foods', where: "id = ?", whereArgs: [id]);

    final res = [
      for (final map in foodMaps)
        Food.fromMap(map),
    ];

    return res.isEmpty ? null : res[0];
  }

  Future<void> deleteFood(int? id) async {
    if(id != null){
      final db = await database;
      await db.delete('foods', where: "id = ?", whereArgs: [id]);
    }
  }

  Future<void> updateFood(Food food) async {
    final db = await database;
    await db.update('foods', food.toMap(), where: "id = ?", whereArgs: [food.id]);
  }
}

class FoodsPage extends StatefulWidget {
  const FoodsPage({super.key});

  static const String routeName = "foods";

  @override
  State<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends State<FoodsPage> {
   bool loading = true;
   List<Food> foods = [];
   _FoodsPageState();
   
   void refresh(){
    FoodDB().getFoods().then((res){setState((){foods = res; loading = false;});});
   }

   @override
   void initState(){
    super.initState();

    refresh();
   }


  @override
  Widget build(BuildContext context) {
    return loading ? CircularProgressIndicator() : 
        Row( children: [
            Card(color: Theme.of(context).colorScheme.primary,
              child: IntrinsicHeight( child:
                Column( mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                      Container(width: 150, height: 45, alignment: Alignment.center,
                          child: Center(child: Text('Name :', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),))
                      ),
                      Container(width: 150, height: 45, alignment: Alignment.center,
                          child: Center(child: Text('Calories (kcal/100g) :', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),))
                      ),
                      Container(width: 150, height: 45, alignment: Alignment.center,
                          child: Center(child: Text('Default quantity (g) :', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),))
                      ),
                      Container(width: 150, height: 45, alignment: Alignment.center,
                          child: Center(child: Text('Protein (g/100g) :', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),))
                      ),
                      Container(width: 150, height: 45, alignment: Alignment.center,
                          child: Center(child: Text('Fat (g/100g) :', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),))
                      ),
                      Container(width: 150, height: 45, alignment: Alignment.center,
                          child: Center(child: Text('Glucide (g/100g) :', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),))
                      ),
                      Container(width: 150, height: 45, alignment: Alignment.center,
                        child: IconButton(onPressed: (){Navigator.pushNamed(context, AddFoodPage.routeName).then((res){if(res != null && res as bool) {setState(() {refresh();});}});}, icon: Icon(Icons.add, color: Theme.of(context).colorScheme.inversePrimary)),
                      )
                      ],
                  )
                )
              ),
              Expanded(child: 
                  Card(
                    color: Colors.black12,
                    child: SingleChildScrollView( 
                        scrollDirection: Axis.horizontal,
                        child: IntrinsicHeight( child:
                          Row(children: 
                            List.generate(foods.length, (index){ final food = foods[index];
                              return 
                              InkWell( onTap: () {Navigator.pushNamed(context, AddFoodPage.routeName, arguments: {'food' : food}).then((res){if(res != null && res as bool) {setState(() {refresh();});}});},
                                child: Card(child: 
                                  Column(children: [
                                    Container(width: 100, height: 45, alignment: Alignment.center, child: Text(food.name, textAlign: TextAlign.center)),
                                    Container(width: 100, height: 45, alignment: Alignment.center, child: Text(food.calories.toString(), textAlign: TextAlign.center)),
                                    Container(width: 100, height: 45, alignment: Alignment.center, child: Text(food.defQuantity.toString(), textAlign: TextAlign.center)),
                                    Container(width: 100, height: 45, alignment: Alignment.center, child: Text(food.protein.toStringAsFixed(0), textAlign: TextAlign.center)),
                                    Container(width: 100, height: 45, alignment: Alignment.center, child: Text(food.fat.toStringAsFixed(0), textAlign: TextAlign.center)),
                                    Container(width: 100, height: 45, alignment: Alignment.center, child: Text(food.glucide.toStringAsFixed(0), textAlign: TextAlign.center)),
                                    Container(width: 100, height: 45, alignment: Alignment.center, child: IconButton(onPressed: (){FoodDB().deleteFood(foods[index].id); setState((){foods.removeAt(index);});}, icon: Icon(Icons.delete)))
                                  ])
                                )
                              );
                            })
                        )
                    )
                  )
                )
              )
        ]
        );
  }
}

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key, this.food});

  static const String routeName = "addfood";
  final Food? food;

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
   late final nameController;
   late final calorieController;
   late final quantityController;
   late final proteinController;
   late final fatController;
   late final glucideController;


   late int calorie;
   late int quantity;
   late double protein;
   late double fat;
   late double glucide;

   bool isSaving = false;
  _AddFoodPageState();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    calorieController.dispose();
    quantityController.dispose();
    proteinController.dispose();
    fatController.dispose();
    glucideController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    Food food = widget.food ?? Food("");
    calorie = food.calories;
    quantity = food.defQuantity;
    protein = food.protein;
    fat = food.fat;
    glucide = food.glucide;

    nameController = TextEditingController(text: food.name);
    calorieController = TextEditingController(text: calorie.toString());
    quantityController = TextEditingController(text: quantity.toString());
    proteinController = TextEditingController(text: protein.toStringAsPrecision(3));
    fatController = TextEditingController(text: fat.toStringAsPrecision(3));
    glucideController = TextEditingController(text: glucide.toStringAsPrecision(3));

    calorieController.addListener(() {
      setState(() {
        calorie = int.tryParse(calorieController.text) ?? 0;
      });
    });
    quantityController.addListener(() {
      setState(() {
        quantity = int.tryParse(quantityController.text) ?? 0;
      });
    });
    proteinController.addListener(() {
      setState(() {
        protein = double.tryParse(proteinController.text) ?? 0;
      });
    });
    fatController.addListener(() {
      setState(() {
        fat = double.tryParse(fatController.text) ?? 0;
      });
    });
    glucideController.addListener(() {
      setState(() {
        glucide = double.tryParse(glucideController.text) ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.food == null ? "Add new food" : "Edit ${widget.food?.name}"),
      ),
      body: 
      Column(children: [
            SizedBox(height: 100,),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 150,
                          child: const Text("Name :")),
                Container(width: 150,
                          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary)),
                          child: TextField(controller: nameController, textAlign: TextAlign.center, decoration: InputDecoration(hintText: "Fraise", hintStyle: TextStyle(color: Colors.black38)))),
            ]),
            SizedBox(height: 100,),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 150,
                          child: const Text("Per :")),
                SizedBox(width: 100,
                          child: const Text("100 g", textAlign: TextAlign.center)),
                SizedBox(width: 100,
                          child: TextFormField(controller: quantityController, textAlign: TextAlign.center, decoration: InputDecoration(suffixText: 'g', suffixStyle: TextStyle(color: Colors.black), hintText: "10", hintStyle: TextStyle(color: Colors.black38)))),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 150,
                       child: const Text("Calories (kcal) :")),
              Container(width: 100,
                        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary)),
                        child: TextField(controller: calorieController, textAlign: TextAlign.center, decoration: InputDecoration(hintText: "200", hintStyle: TextStyle(color: Colors.black38)))),
              SizedBox(width: 100,
                       child: Text((calorie/100.0 * quantity).toStringAsFixed(0), textAlign: TextAlign.center)),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 150,
                          child: const Text("Protein (g) :")),
                Container(width: 100,
                          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary)),
                          child: TextField(controller: proteinController, textAlign: TextAlign.center, decoration: InputDecoration(hintText: "10", hintStyle: TextStyle(color: Colors.black38)))),
                SizedBox(width: 100,
                       child: Text((protein/100.0 * quantity).toStringAsFixed(0), textAlign: TextAlign.center)),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 150,
                          child: const Text("Fat (g) :")),
                Container(width: 100,
                          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary)),
                          child: TextField(controller: fatController, textAlign: TextAlign.center, decoration: InputDecoration(hintText: "10", hintStyle: TextStyle(color: Colors.black38)))),
                SizedBox(width: 100,
                       child: Text((fat/100.0 * quantity).toStringAsFixed(0), textAlign: TextAlign.center)),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 150,
                          child: const Text("Glucide (g) :")),
                Container(width: 100,
                          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary)),
                          child: TextField(controller: glucideController, textAlign: TextAlign.center, decoration: InputDecoration(hintText: "20", hintStyle: TextStyle(color: Colors.black38)))),
                SizedBox(width: 100,
                       child: Text((glucide/100.0 * quantity).toStringAsFixed(0), textAlign: TextAlign.center)),
            ]),
        SizedBox(height: 60,), 
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 20,
          children: [
            ElevatedButton(onPressed: (){
                if(!isSaving && nameController.text.isNotEmpty && calorieController.text.isNotEmpty){
                    setState(() { isSaving = true; });
                    FoodDB().insertFood(Food(nameController.text, 
                      id: widget.food?.id,
                      calories: int.tryParse(calorieController.text) ?? 0,
                      protein: double.tryParse(proteinController.text) ?? 0,
                      defQuantity: int.tryParse(quantityController.text) ?? 100,
                      fat: double.tryParse(fatController.text) ?? 0,
                      glucide: double.tryParse(glucideController.text) ?? 0
                    )).then((res) {setState(() { isSaving = false; }); if (mounted && Navigator.canPop(context)){Navigator.pop(context, true);}});
                }
            }, child: isSaving ? CircularProgressIndicator() : const Text('Save')),
            ElevatedButton(onPressed: (){if (Navigator.canPop(context)){Navigator.pop(context);}}, child: const Text('Cancel')),
        ],)
      ])
    );
  }

}