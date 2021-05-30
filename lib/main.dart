import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:scribbl_clone/firestore_object.dart';
import 'package:scribbl_clone/paint_data.dart';
import 'color_extensions.dart';

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

  bool _canDraw = true;
  bool _progressBarVisible = false;
  FirebaseFirestore firestore;

  int serialNumber = 0;

  bool observeFirebase = false;

  CollectionReference<FirestoreData> reference;
  CollectionReference resetButtonReference;

  @override
  void initState() {
    selectedColor = Colors.black;
    strokeWidth = 2.0;
    firestore = FirebaseFirestore.instance;
    reference = firestore.collection('points5').withConverter(
      fromFirestore: (snapshot, _) {
        return FirestoreData.fromJson(snapshot.data());
      },
      toFirestore: (data, _) {
        return data.toJson();
      },
    );
    resetButtonReference = firestore.collection('resetbutton');
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

  void showProgressBar() {
    _progressBarVisible = true;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(
                height: 12.0,
              ),
              Text("Loading..."),
            ],
          ),
        );
      },
    );
  }

  void hideProgressBar() {
    if (_progressBarVisible) Navigator.of(context).pop();
  }

  void uploadPointsToFirestore(FirestoreData firestoreData) {
    if (_canDraw) {
      if (firestoreData != null) {
        // reference.add(firestoreData);
        print('Uploading data: ${firestoreData.dx} ${firestoreData.dy}');
        reference.add(firestoreData);
      } else {
        reference.add(
            FirestoreData(dx: null, dy: null, color: null, strokeWidth: null));
      }
    }
  }

  Future<void> clearFirestore() async{
      showProgressBar();
      await resetButtonReference.doc('is_reset').update({'is_reset': FieldValue.increment(1)});
      WriteBatch batch = FirebaseFirestore.instance.batch();
      var snapshot = await reference.get();
      if (snapshot.docs.length >= 500) {
        for(DocumentSnapshot ds in snapshot.docs) {
          await ds.reference.delete();
        }
      }
      else {
        for(DocumentSnapshot ds in snapshot.docs) {
           batch.delete(ds.reference);
        }
      }

      hideProgressBar();
  }

  void observeFirestore() {
    if (!_canDraw) { // It cannot draw, now observe
      clearAll();

      resetButtonReference.snapshots().listen((snapshot) {
        print(snapshot.docChanges.toString());
        int shouldClear = snapshot.docs[0].get('is_reset') as int;
        if (shouldClear != null) {
          clearAll();
        }
      });

      reference.snapshots().listen((snapshot) {
        for (DocumentChange<FirestoreData> doc in snapshot.docChanges) {
            print("change recd");
            setState(() {

              FirestoreData data = doc.doc.data();

              if (data.dx != null && data.dy != null && data.color != null && data.strokeWidth != null) {
                Paint paint = Paint();
                paint..color = data.color.getColorFromValueString();
                paint..strokeWidth = strokeWidth;
                paint..isAntiAlias = true;
                paint..strokeCap = StrokeCap.round;

                ColoredPaint obj =
                    ColoredPaint(offset: Offset(data.dx, data.dy), paint: paint);
                points.add(obj);
            }
              else {
                points.add(null);
              }
              // print(points);
          });
          }
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    CollectionReference pointsCollection = firestore.collection('points');

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
                    absorbing: !_canDraw,
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
                        FirestoreData data = FirestoreData(
                            dx: details.localPosition.dx,
                            dy: details.localPosition.dy,
                            color: selectedColor.getValueStringFromColor(),
                            strokeWidth: strokeWidth);
                        Offset offset = details.localPosition;
                        // print(offset);
                        uploadPointsToFirestore(data);
                        this.setState(() {
                          Paint paint = Paint();
                          paint..color = selectedColor;
                          paint..strokeWidth = strokeWidth;
                          paint.isAntiAlias = true;
                          paint.strokeCap = StrokeCap.round;
                          // print(selectedColor.value);
                          points.add(ColoredPaint(
                              offset: details.localPosition, paint: paint));
                        });
                      },
                      onPanEnd: (details) {
                        uploadPointsToFirestore(null);
                        setState(() {
                          points.add(null);
                        });
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
                          icon: Icon(Icons.layers_clear), onPressed: (){
                            clearAll();
                            clearFirestore();
                          },)
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(_canDraw ? Icons.visibility_off : Icons.visibility),
        onPressed: () {


          if (_canDraw) {
            setState(() {
              _canDraw = false;
            });
            SnackBar snackBar =
            SnackBar(content: Text("Read only mode, Cannot Draw"));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            // observeFirebase = true;
            observeFirestore();
          } else {
            setState(() {
              _canDraw = true;
            });
            SnackBar snackBar = SnackBar(content: Text("Can Draw"));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            // observeFirebase = false;
            observeFirestore();

          }
        },
      ),
    );
  }
}
