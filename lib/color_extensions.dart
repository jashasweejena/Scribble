import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  String getValueStringFromColor() {
    String colorString = this.toString();
    String valueString = colorString.split('(0x')[1].split(')')[0];
    return valueString;
  }
}

extension StringExtensions on String {
  Color getColorFromValueString() {
    int value = int.parse(this, radix: 16);
    Color color = Color(value);
    return color;
  }
}
