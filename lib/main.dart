import 'package:blues_lab/demo.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

/// Root widget - Web-first application (Stage 1: no backend)
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Blue's Lab",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PoMaHomePage(),
    );
  }
}
