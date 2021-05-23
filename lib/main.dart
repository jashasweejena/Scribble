import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:scribbl_clone/paint_data.dart';

import 'custom_painter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ColoredPaint> points = [];
  Color selectedColor;
  double strokeWidth;

  bool _readOnly = false;

  FirebaseFirestore firestore;

  @override
  void initState() {
    selectedColor = Colors.black;
    strokeWidth = 2.0;
    firestore = FirebaseFirestore.instance;
    super.initState();
  }

  void selectColor() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Color"),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: selectedColor,
              onColorChanged: (value) {
                setState(() {
                  selectedColor = value;
                });
                Navigator.of(context).pop();
              },
            ),
          ),
          actions: [
            OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Close"))
          ],
        );
      },
    );
  }

  void clearAll() {
    setState(() {
      points = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                  Color.fromRGBO(136, 35, 135, 1.0),
                  Color.fromRGBO(233, 64, 87, 1.0),
                  Color.fromRGBO(242, 113, 33, 1.0)
                ])),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: width * 0.80,
                  height: height * 0.80,
                  child: AbsorbPointer(
                    absorbing: !_readOnly,
                    child: GestureDetector(
                      onPanDown: (details) {
                        this.setState(() {
                          Paint paint = Paint();
                          paint..color = selectedColor;
                          paint..strokeWidth = strokeWidth;
                          paint..isAntiAlias = true;
                          paint..strokeCap = StrokeCap.round;
                          points.add(ColoredPaint(
                              offset: details.localPosition, paint: paint));
                        });
                      },
                      onPanUpdate: (details) {
                        this.setState(() {
                          Paint paint = Paint();
                          paint..color = selectedColor;
                          paint..strokeWidth = strokeWidth;
                          paint.isAntiAlias = true;
                          paint.strokeCap = StrokeCap.round;
                          points.add(ColoredPaint(
                              offset: details.localPosition, paint: paint));
                        });
                      },
                      onPanEnd: (details) {
                        points.add(null);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        child: CustomPaint(
                          painter: MyCustomPainter(
                              points: points,
                              color: selectedColor,
                              strokeWidth: strokeWidth),
                        ),
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 5.0,
                          spreadRadius: 1.0)
                    ],
                    borderRadius: BorderRadius.all(
                      Radius.circular(20.0),
                    ),
                  ),
                ),
                SizedBox(
                  height: 12.0,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(20.0),
                    ),
                  ),
                  width: width * 0.80,
                  child: Row(
                    children: [
                      IconButton(
                          icon: Icon(Icons.color_lens),
                          color: selectedColor,
                          onPressed: selectColor),
                      Expanded(
                        child: Slider(
                          value: strokeWidth,
                          min: 1.0,
                          max: 7.0,
                          inactiveColor: selectedColor.withAlpha(100),
                          activeColor: selectedColor,
                          onChanged: (value) {
                            setState(() {
                              strokeWidth = value;
                            });
                          },
                        ),
                      ),
                      IconButton(
                          icon: Icon(Icons.layers_clear), onPressed: clearAll)
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(_readOnly ? Icons.visibility_off : Icons.visibility),
        onPressed: () {
          setState(() {
            _readOnly = !_readOnly;
          });
          if (_readOnly) {
            SnackBar snackBar = SnackBar(content: Text("Can Draw"));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          } else {
            SnackBar snackBar =
                SnackBar(content: Text("Read only mode, Cannot Draw"));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        },
      ),
    );
  }
}
