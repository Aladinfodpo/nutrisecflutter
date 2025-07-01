import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

import 'day.dart';

class Pedo {
  late int lastStepNumber;

  static final Pedo _singleton = Pedo._internal();
  
  factory Pedo() {
    return _singleton;
  }
  
  Pedo._internal();

  Future<void> loadFromData(SharedPreferences pref) async{
    final read = pref.getInt("lastStepNumber");
    
    // First start
    if(read == null) {
      return resetLastStepToNow();
    }else{
      lastStepNumber = read;
    }
  }

  Future<void> save() async {
    final pref = await SharedPreferences.getInstance();
    pref.setInt("lastStepNumber", lastStepNumber);
  }
  
  Future<int> _getStepNumber(){
    final completer = Completer<int>();
    final stream = Pedometer.stepCountStream;
    StreamSubscription<StepCount>? sub;
    sub = stream.listen((event) {
      completer.complete(event.steps);
      sub?.cancel();
    });

    return completer.future;
  }

  Future<void> resetLastStepToNow() async{
    return _getStepNumber().then((res){lastStepNumber = res; return save();});
  }

  Future<int> getTodayStep(){
    return _getStepNumber().then((value){
      if(value < lastStepNumber){
        // Phone have restarted, lost count we need to reset
        lastStepNumber = value;
        return save().then((res) => 0);
      }
      return value - lastStepNumber;
      });
  }

  Future<void> midnightReset() async{
    Day day = await DayDB().getDay(Day.getTodayId()) ?? await Day.createToday();
    await DayDB().insertDay(day.copyWith(inSteps: await getTodayStep()));
    return resetLastStepToNow();
  }

}