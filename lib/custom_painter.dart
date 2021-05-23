import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:scribbl_clone/paint_data.dart';

class MyCustomPainter extends CustomPainter {
  List<ColoredPaint> points = [];
  Color color;
  double strokeWidth;

  MyCustomPainter(
      {this.points, this.color = Colors.black, this.strokeWidth = 2.0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint background = Paint()..color = Colors.white;
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawRect(rect, background);

    // Paint paint = Paint();
    // paint.color = color;
    // paint.strokeWidth = strokeWidth;
    // paint.isAntiAlias = true;
    // paint.strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        Paint paint = points[i].paint;
        Offset x1 = points[i].offset;
        Offset x2 = points[i + 1].offset;
        canvas.drawLine(x1, x2, paint);
      } else {
        if (points[i] != null && points[i + 1] == null) {
          Paint paint = points[i].paint;
          Offset x = points[i].offset;
          canvas.drawPoints(PointMode.points, [x], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
