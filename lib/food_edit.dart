import 'package:flutter/material.dart';

import 'day_food.dart';


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

  void refresh() {
    FoodDB().getFoods().then((res) {
      setState(() {
        foods = res;
        loading = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();

    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? CircularProgressIndicator()
        : Row(
          children: [
            Card(
              color: Theme.of(context).colorScheme.primary,
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 45,
                      alignment: Alignment.center,
                      child: Center(
                        child: Text(
                          'Name :',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 150,
                      height: 45,
                      alignment: Alignment.center,
                      child: Center(
                        child: Text(
                          'Calories (kcal/100g) :',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 150,
                      height: 45,
                      alignment: Alignment.center,
                      child: Center(
                        child: Text(
                          'Default quantity (g) :',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 150,
                      height: 45,
                      alignment: Alignment.center,
                      child: Center(
                        child: Text(
                          'Protein (g/100g) :',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 150,
                      height: 45,
                      alignment: Alignment.center,
                      child: Center(
                        child: Text(
                          'Fat (g/100g) :',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 150,
                      height: 45,
                      alignment: Alignment.center,
                      child: Center(
                        child: Text(
                          'Glucide (g/100g) :',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 150,
                      height: 45,
                      alignment: Alignment.center,
                      child: IconButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AddFoodPage.routeName,
                          ).then((res) {
                            if (res != null && res as bool) {
                              setState(() {
                                refresh();
                              });
                            }
                          });
                        },
                        icon: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Colors.black12,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicHeight(
                    child: Row(
                      children: List.generate(foods.length, (index) {
                        final food = foods[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AddFoodPage.routeName,
                              arguments: {'food': food},
                            ).then((res) {
                              if (res != null && res as bool) {
                                setState(() {
                                  refresh();
                                });
                              }
                            });
                          },
                          child: Card(
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 45,
                                  alignment: Alignment.center,
                                  child: Text(
                                    food.name,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  height: 45,
                                  alignment: Alignment.center,
                                  child: Text(
                                    food.calories.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  height: 45,
                                  alignment: Alignment.center,
                                  child: Text(
                                    food.defQuantity.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  height: 45,
                                  alignment: Alignment.center,
                                  child: Text(
                                    food.protein.toStringAsFixed(0),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  height: 45,
                                  alignment: Alignment.center,
                                  child: Text(
                                    food.fat.toStringAsFixed(0),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  height: 45,
                                  alignment: Alignment.center,
                                  child: Text(
                                    food.glucide.toStringAsFixed(0),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  height: 45,
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    onPressed: () {
                                      FoodDB().deleteFood(foods[index].id);
                                      setState(() {
                                        foods.removeAt(index);
                                      });
                                    },
                                    icon: Icon(Icons.delete),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
    proteinController = TextEditingController(
      text: protein.toStringAsPrecision(3),
    );
    fatController = TextEditingController(text: fat.toStringAsPrecision(3));
    glucideController = TextEditingController(
      text: glucide.toStringAsPrecision(3),
    );

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
        title: Text(
          widget.food == null ? "Add new food" : "Edit ${widget.food?.name}",
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 100),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 150, child: const Text("Name :")),
              Container(
                width: 150,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: TextField(
                  controller: nameController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "Fraise",
                    hintStyle: TextStyle(color: Colors.black38),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 100),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 150, child: const Text("Per :")),
              SizedBox(
                width: 100,
                child: const Text("100 g", textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: quantityController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: 'g',
                    suffixStyle: TextStyle(color: Colors.black),
                    hintText: "10",
                    hintStyle: TextStyle(color: Colors.black38),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 150, child: const Text("Calories (kcal) :")),
              Container(
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: TextField(
                  controller: calorieController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "200",
                    hintStyle: TextStyle(color: Colors.black38),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  (calorie / 100.0 * quantity).toStringAsFixed(0),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 150, child: const Text("Protein (g) :")),
              Container(
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: TextField(
                  controller: proteinController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "10",
                    hintStyle: TextStyle(color: Colors.black38),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  (protein / 100.0 * quantity).toStringAsFixed(0),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 150, child: const Text("Fat (g) :")),
              Container(
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: TextField(
                  controller: fatController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "10",
                    hintStyle: TextStyle(color: Colors.black38),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  (fat / 100.0 * quantity).toStringAsFixed(0),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 150, child: const Text("Glucide (g) :")),
              Container(
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: TextField(
                  controller: glucideController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "20",
                    hintStyle: TextStyle(color: Colors.black38),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  (glucide / 100.0 * quantity).toStringAsFixed(0),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (!isSaving &&
                      nameController.text.isNotEmpty &&
                      calorieController.text.isNotEmpty) {
                    setState(() {
                      isSaving = true;
                    });
                    FoodDB()
                        .insertFood(
                          Food(
                            nameController.text,
                            id: widget.food?.id,
                            calories: int.tryParse(calorieController.text) ?? 0,
                            protein:
                                double.tryParse(proteinController.text) ?? 0,
                            defQuantity:
                                int.tryParse(quantityController.text) ?? 100,
                            fat: double.tryParse(fatController.text) ?? 0,
                            glucide:
                                double.tryParse(glucideController.text) ?? 0,
                          ),
                        ).then((res) => DayDB().recalculateCal())
                        .then((res) {
                          if (mounted && Navigator.canPop(context)) {
                            Navigator.pop(context, true);
                          }
                        });
                  }
                },
                child:
                    isSaving ? CircularProgressIndicator() : const Text('Save'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
