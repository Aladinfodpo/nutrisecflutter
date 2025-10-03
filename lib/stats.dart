import 'package:flutter/material.dart';
import 'package:nutrisec/user.dart';
import 'day_food.dart';
import 'dart:math';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  static const String routeName = "stats";

  @override
  State<StatsPage> createState() => _StatsPageState();
}

Duration getTimeToObj(Day day1, Day today){
  final t0 = DateTime(day1.year, day1.month, day1.day);
  final t1 = DateTime(today.year, today.month, today.day);
  final dt = t1.difference(t0).inDays;

  final b = max(0.05, day1.poids-today.poids);
  return Duration(days: (User().objectif / b * dt).ceil()-dt);
}

const List<String> listStat = <String>['Weight', 'Calorie'];
final List<Function> listCBStat = [(Day day) => day.poids, (Day day) => day.calories - User().baseCal.toDouble()];

class _StatsPageState extends State<StatsPage> {
  _StatsPageState();
  late List<Day> days;
  bool isLoading = true;
  late RangeValues _currentRangeValues;
  final TransformationController _controllerTransf = TransformationController();
  String statString = listStat.first;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return 
        isLoading
        ? CircularProgressIndicator()
        : Padding(
          padding: EdgeInsetsGeometry.all(8.0),
          child: Column(
            children: [
              DropdownButton<String>(
          value: statString,
          icon: const Icon(Icons.keyboard_arrow_down),
          elevation: 16,
          style: const TextStyle(color: Colors.red),
          underline: Container(height: 2, color: Colors.red),
          onChanged: (String? value) {
            // This is called when the user selects an item.
            setState(() {
              statString = value!;
            });
          },
          items: listStat.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList()),
              Expanded(
                child: (_currentRangeValues.end == _currentRangeValues.start) ?
                Center(child: const Text("No data selected")) : 
                InteractiveViewer(
                  transformationController: _controllerTransf,
                  boundaryMargin: EdgeInsets.all(0),
                  minScale: 0.01,
                  maxScale: 5.0,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CurvePainter(
                      days
                          .sublist(
                            _currentRangeValues.start.toInt(),
                            _currentRangeValues.end.toInt() + 1,
                          )
                          .map(
                            (day) => DataCurve.fromDay(day, statString)
                          )
                          .toList(),
                          statString == listStat[0] ? days[_currentRangeValues.start.toInt()].poids - User().objectif.toDouble() : null
                    ),
                  ),
                ),
              ),
              (_currentRangeValues.end.toInt() + 1 - _currentRangeValues.start.toInt() >= 2 ? Text("Objectif reached in ${getTimeToObj(days[_currentRangeValues.start.toInt()], days[_currentRangeValues.end.toInt()]).inDays} days") : SizedBox()),
              RangeSlider(
                values: _currentRangeValues,
                min: 0,
                max: days.length.toDouble() - 1,
                divisions: days.length - 1,
                onChanged: (RangeValues values) {
                  setState(() {
                    _currentRangeValues = values;
                  });
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    _controllerTransf.value = Matrix4.identity();

    DayDB().getDays().then((value) {
      setState(() {
        days = value.reversed.toList();
        _currentRangeValues = RangeValues(0, (days.length - 1).toDouble());
        isLoading = false;
      });
    });
  }
}

class DataCurve {
  double x, y;
  String? xLabel;

  DataCurve(this.x, this.y, [this.xLabel]);

  factory DataCurve.fromDay(Day day, String dataType){
    final iType = listStat.indexWhere((element) => element == dataType);

    return DataCurve(day.getID().toDouble(), listCBStat[iType](day), day.getTitle(),);
  }

  Offset toOffset(
    double minX,
    double maxX,
    double scaleX,
    double minY,
    double maxY,
    double scaleY,
  ) {
    return Offset(
      (x - minX) / (maxX - minX) * scaleX,
      scaleY - max((y - minY) / (maxY - minY), 0.0) * scaleY,
    );
  }
}

class CurvePainter extends CustomPainter {
  final List<DataCurve> data;
  double minY;
  final double maxY;
  final double minX;
  final double maxX;
  final double meanY;
  static const double ratio = 0.00;
  double? objectif;

  CurvePainter(this.data, [this.objectif])
    : minY =
          data.fold(objectif ?? double.infinity, (res, e) => min(e.y, res)) *
          (1 - CurvePainter.ratio),
      maxY =
          data.fold(double.negativeInfinity, (res, e) => max(e.y, res)) *
          (1 + CurvePainter.ratio),
          meanY = data.fold(0.0, (res, e) => res + e.y)/data.length,
      minX = data.firstOrNull?.x ?? 0,
      maxX = data.lastOrNull?.x ?? 0
      {
        if(minY == maxY){
          minY = maxY < 0 ? maxY*2.0 + 0.01 : maxY*0.5 - 0.01;
        }
      }

  @override
  void paint(Canvas canvas, Size size) {
    if (minX == maxX) {
      return;
    }
    canvas.save();
    const scaleX = 0.8;
    canvas.scale(scaleX, 0.85);
    canvas.translate((1.0 - scaleX) * 0.5 * size.width+20, 10);

    Paint painterBack = Paint();
    painterBack.style = PaintingStyle.stroke;
    painterBack.color = Colors.black;
    painterBack.strokeWidth = 3.0;

    canvas.drawRRect(RRect.fromLTRBR(0, 0, size.width, size.height, Radius.zero), painterBack);

    drawYlabel(minY / (1 - CurvePainter.ratio), canvas, size, painterBack);
    drawYlabel(maxY / (1 + CurvePainter.ratio), canvas, size, painterBack);

    if(meanY != minY && meanY != maxY){
      drawYlabel(meanY, canvas, size, painterBack);
    }

    if(objectif != null){
      Paint painterBack = Paint();
      painterBack.style = PaintingStyle.stroke;
      painterBack.color = Colors.blue;
      painterBack.strokeWidth = 3.0;
      Offset maxOff = Offset(
        0.0,
        size.height -
            max((objectif! - minY) / (maxY - minY), 0.0) *
                size.height,
      );
      canvas.drawLine(maxOff.translate(0, 0), maxOff.translate(size.width, 0), painterBack);
    }
  
    Paint painter = Paint();
    painter.style = PaintingStyle.stroke;
    painter.color = const Color.fromARGB(255, 172, 6, 6);
    painter.strokeWidth = 3.0;

    DataCurve? last;
    for (final point in data) {
      if (last != null) {
        canvas.drawLine(
          last.toOffset(minX, maxX, size.width, minY, maxY, size.height),
          point.toOffset(minX, maxX, size.width, minY, maxY, size.height),
          painter,
        );
      }

      if (point.xLabel != null) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: point.xLabel,
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        Offset offset = point.toOffset(
          minX,
          maxX,
          size.width,
          0,
          double.infinity,
          size.height,
        );
        canvas.drawLine(offset, offset.translate(0, 10), painterBack);
        canvas.save();
        canvas.translate(offset.dx, offset.dy);
        canvas.rotate(pi / 2);
        final textOffset = Offset(
          10.0,
          -textPainter.height / 2,
        );
        textPainter.paint(canvas, textOffset);
        canvas.restore();
      }
      last = point;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CurvePainter oldDelegate) {
    return oldDelegate.data != data;
  }

  void drawYlabel(double y, Canvas canvas, Size size, Paint painter){
    final textY = TextPainter(
      text: TextSpan(
        text: y.toStringAsFixed(y.abs() > 100 ? 0 : 1),
        style: TextStyle(color: Colors.black, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    Offset maxOff = Offset(
        -textY.width - 10.0,
        size.height -
            max((y - minY) / (maxY - minY), 0.0) *
                size.height -
            textY.height * 0.5,
      );
    textY.paint(
      canvas,
      maxOff,
    );
    canvas.drawLine(maxOff.translate(textY.width+2, textY.height * 0.5), maxOff.translate(textY.width+10+size.width, textY.height * 0.5), painter);
  }
}
