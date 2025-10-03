import 'package:flutter/material.dart';

import 'user.dart';
import 'day_food.dart';

import 'food_edit.dart';

class DaysPage extends StatefulWidget {
  const DaysPage({super.key});

  @override
  State<DaysPage> createState() => _DaysPageState();
}

class _DaysPageState extends State<DaysPage> {
  bool loading = true;
  List<Day> days = [];
  _DaysPageState();

  void refresh() {
    DayDB().getDays().then((res) {
      setState(() {
        days = res;
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
        : Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                Day? day = await DayDB().getDay(Day.getTodayId());
                if(day != null){
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    day = await DayDB().getDay(Day.calculateID(pickedDate.day, pickedDate.month, pickedDate.year)) ?? Day(pickedDate.day, pickedDate.month, pickedDate.year, []);
                  }
                }else{
                  day = await Day.createToday();
                }

                if (mounted) {
                  Navigator.pushNamed(
                    context,
                    EditDayPage.routeName,
                    arguments: {"day": day},
                  ).then((value) => refresh());
                }
              },
              child: Icon(Icons.add),
            ),
            Expanded(
              child: ListView(
                scrollDirection: Axis.vertical,
                children:
                    List.generate(days.length, (index) {
                      final day = days[index];
                      return SizedBox(
                        width: double.infinity,
                        child: InkWell(
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                EditDayPage.routeName,
                                arguments: {"day": day},
                              ).then((value) => refresh()),
                          child: Dismissible(
                            confirmDismiss:
                                (direction) => showDialog(
                                  context: context,
                                  builder:
                                      ((context) => AlertDialog(
                                        title: Text('Confirmation'),
                                        content: Text(
                                          'Do you want to delete this day ?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: Text('No'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            child: Text('Yes'),
                                          ),
                                        ],
                                      )),
                                ),
                            key: ValueKey<int>(day.getID()),
                            direction: DismissDirection.horizontal,
                            onDismissed:
                                (direction) => setState(() {
                                  DayDB().deleteDay(day.getID());
                                  days.removeAt(index);
                                }),
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(day.getTitle()),
                                        Spacer(),
                                        Text("${day.steps} steps"),
                                      ],
                                    ),
                                    Text(
                                      '${day.calories}/${User().baseCal} kcal',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
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

  late Food allMeals;

  final quantityController = TextEditingController(text: "0");
  final hourController = TextEditingController(text: DateTime.now().hour.toString());
  final poidsController = TextEditingController(text: "0");
  final cardioController = TextEditingController(text: "0");
  final stepsController = TextEditingController(text: "0");

  late List<FoodEaten> foodEatens;
  List<Food> foods = [];

  Food? currentFood;
  int currentQuantity = 0;

  int indexPage = 0;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    quantityController.dispose();
    cardioController.dispose();
    poidsController.dispose();
    super.dispose();
  }

  void recalculate() {
    setState(() {
      Day.calculateMeals(foodEatens).then((value) => allMeals = value);
    });
  }

  void resetFoods() {
    FoodEaten.getFoods(foodEatens).then((res) => setState(() => foods = res));
  }

  @override
  void initState() {
    super.initState();

    foodEatens = widget.day.foodIds;
    day = widget.day.day;
    month = widget.day.month;
    year = widget.day.year;

    cardioController.text = widget.day.cardio.toString();
    stepsController.text = widget.day.steps.toString();
    poidsController.text = widget.day.poids.toStringAsFixed(1);
    allMeals = Food("", calories: widget.day.calories);

    quantityController.addListener(() => setState(() => currentQuantity = (int.tryParse(quantityController.text) ?? 0)));

    resetFoods();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          await DayDB().insertDay(
            Day(
              day,
              month,
              year,
              foodEatens,
              calories: allMeals.calories,
              steps: int.tryParse(stepsController.text) ?? 0,
              cardio: int.tryParse(cardioController.text) ?? 0,
              poids: double.tryParse(poidsController.text) ?? 0,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: SizedBox(
            child: Padding(
              padding: EdgeInsets.all(6.0),
              child: InkWell(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(year, month, day),
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    day = pickedDate.day;
                    month = pickedDate.month;
                    year = pickedDate.year;
                  }
                },
                child: Text("Edit the ${Day.formatDate(day, month, year)}"),
              ),
            ),
          ),
        ),
        body: SizedBox(
          width: double.infinity,
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                spacing: 30,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => indexPage = 0),
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        indexPage == 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    child: Text(
                      "Food",
                      style: TextStyle(
                        color:
                            indexPage != 0
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => indexPage = 1),
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        indexPage == 1
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    child: Text(
                      "Work out",
                      style: TextStyle(
                        color:
                            indexPage != 1
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  ),
                ],
              ),
              indexPage == 0
                  ? Column(
                    children: [
                      Row(
                        children: [
                          Card(
                            margin: EdgeInsets.all(8.0),
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
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.inversePrimary,
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
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.inversePrimary,
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
                                        'Quantity (g) :',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.inversePrimary,
                                        ),
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
                                    children:
                                        foods.isEmpty
                                            ? [SizedBox(width: 10, height: 143)]
                                            : List.generate(foods.length, (
                                              index,
                                            ) {
                                              final food = foods[index];
                                              final foodEaten =
                                                  foodEatens[index];
                                              return Dismissible(
                                                direction:
                                                    DismissDirection.vertical,
                                                onDismissed: (direction) {
                                                  if (direction ==
                                                      DismissDirection.down) {
                                                    currentFood = food;
                                                    quantityController.text = 
                                                        foodEaten.quantity.toString();
                                                  }
                                                  setState(() {
                                                    foodEatens.removeAt(index);
                                                    foods.removeAt(index);
                                                  });
                                                  recalculate();
                                                },
                                                key: ValueKey<Food>(food),
                                                child: InkWell(
                                                  onDoubleTap: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      AddFoodPage.routeName,
                                                      arguments: {'food': food},
                                                    ).then((res) {
                                                      if (res != null &&
                                                          res as bool) {
                                                        setState(() {
                                                          recalculate();
                                                          resetFoods();
                                                          currentFood = null;
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
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            food.name,
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 100,
                                                          height: 45,
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            food.calories
                                                                .toString(),
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 100,
                                                          height: 45,
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            foodEaten.quantity
                                                                .toString(),
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
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
                      ),
                      SizedBox(height: 30),
                      Text(
                        "${allMeals.calories}${currentFood == null ? "" : " + ${(currentQuantity * currentFood!.calories / 100).toInt()}"}${int.tryParse(cardioController.text) == null || int.tryParse(cardioController.text) == 0 ? "" : " - ${int.tryParse(cardioController.text)}"} kcal",
                      ),
                      SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Card(
                            color: Color.fromARGB(255, 178, 178, 201),
                            child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Column(
                                spacing: 30,
                                children: [
                                  SizedBox(
                                    width: 200,
                                    child: Card(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: 10.0,
                                          right: 0.0,
                                        ),
                                        child: SearchAnchor(
                                          isFullScreen: false,
                                          builder: (
                                            BuildContext context,
                                            SearchController controller,
                                          ) {
                                            return Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    currentFood == null
                                                        ? "Search"
                                                        : currentFood!.name,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.search,
                                                  ),
                                                  onPressed: () {
                                                    controller.openView();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                          suggestionsBuilder: (
                                            BuildContext context,
                                            SearchController controller,
                                          ) async {
                                            final List<Food> options =
                                                await FoodDB().search(
                                                  controller.text,
                                                );

                                            final widgetOptions = List<
                                              ListTile
                                            >.generate(options.length, (
                                              int index,
                                            ) {
                                              final Food item = options[index];
                                              return ListTile(
                                                title: Text(item.name),
                                                subtitle: Text(
                                                  "cals: ${item.calories}kcal",
                                                ),
                                                onTap: () {
                                                  currentFood = item;
                                                  quantityController.text =
                                                      item.defQuantity
                                                          .toString();
                                                  controller.closeView(
                                                    item.name,
                                                  );
                                                },
                                              );
                                            });

                                            return widgetOptions;
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        child: const Text("Quantity (g)"),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: TextField(
                                          controller: quantityController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        child: const Text("Hour"),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: TextField(
                                          controller: hourController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ]),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        child: const Text("Total calories"),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          currentFood == null
                                              ? ""
                                              : '${(currentQuantity * currentFood!.calories / 100).toInt()} kcal',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed:
                                        currentFood == null ||
                                                currentQuantity == 0
                                            ? null
                                            : () {
                                              setState(() {
                                                foodEatens.add(
                                                  FoodEaten(
                                                    currentFood!.id!,
                                                    currentQuantity,
                                                    int.tryParse(hourController.text)
                                                  ),
                                                );
                                                foods.add(currentFood!);
                                                currentFood = null;
                                              });
                                              recalculate();
                                            },
                                    child: const Text("Eat it!"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                  : Card(
                    child: Column(
                      children: [
                        SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                "Steps :",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: stepsController,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                "Poids (kg):",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: poidsController,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                "Cardio (kcal):",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: cardioController,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
