// This is a basic Flutter widget test.
// To perform an interaction with a widget in your test, use the WidgetTester utility that Flutter
// provides. For example, you can send tap and scroll gestures. You can also use WidgetTester to
// find child widgets in the widget tree, read text, and verify that the values of widget properties
// are correct.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifecycle/main.dart';

void main() {
  StreamController<int> controller;
  controller=StreamController<int>.broadcast(
  onListen: (){
    [0,1,2,3,4,5].forEach(controller.add);
  }
  );

  controller.stream.listen(print);

  controller.close();
}
