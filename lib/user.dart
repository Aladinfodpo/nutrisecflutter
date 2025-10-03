import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'pedo.dart';

class User {
  int baseCal = 0;
  int objectif = 0;

  static final User _singleton = User._internal();

  factory User() {
    return _singleton;
  }

  User._internal();

  Future<void> loadFromData(SharedPreferences pref) async {
    baseCal = pref.getInt("baseCal") ?? 2700;
    objectif = pref.getInt("objectif") ?? 10;
  }

  Future<void> save() async {
    final pref = await SharedPreferences.getInstance();
    pref.setInt("baseCal", baseCal);
    pref.setInt("objectif", objectif);
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const String routeName = "settings";

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final baseColController = TextEditingController(
    text: User().baseCal.toString(),
  );
  final objectifController = TextEditingController(
    text: User().objectif.toString(),
  );

  bool isSaving = false;
  _SettingsPageState();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    baseColController.dispose();
    objectifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 100, child: Text("Base calorie :")),
                SizedBox(
                  width: 70,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: TextField(
                        controller: baseColController,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 100, child: Text("Objectif (-kg) :")),
                SizedBox(
                  width: 70,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: TextField(
                        controller: objectifController,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (!isSaving) {
                      User().baseCal =
                          int.tryParse(baseColController.text) ?? 2400;
                          User().objectif = int.tryParse(objectifController.text) ?? 10;

                      setState(() {
                        isSaving = true;
                      });
                      await User().save();
                      setState(() {
                        isSaving = false;
                      });
                    }
                  },
                  child:
                      isSaving
                          ? CircularProgressIndicator()
                          : const Text("Sauvegarder"),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Pedo().treatLastReset(true);
              },
              child: const Text("Step reset yesterday"),
            ),
            TextButton(
              onPressed: () async {
                Pedo().resetAlarms(await SharedPreferences.getInstance());
              },
              child: const Text("Reset alarms"),
            ),
          ],
        ),
      ),
    );
  }
}
