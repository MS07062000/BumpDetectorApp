// import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:bump_detector_app/bump_detector.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bump Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            // Set the border shape of the Card
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.red), // Set the border side
          ),
        ),
        dividerTheme: const DividerThemeData(
          thickness: 2, // Set the thickness of the dividers
          color: Colors.red, // Set the color of the dividers
        ),
      ),
      home: const BumpDetectorPage(),
    );
  }
}
