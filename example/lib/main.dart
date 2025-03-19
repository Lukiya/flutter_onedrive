import 'package:flutter/material.dart';
import './examples.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: const Text('OneDrive Demo'), centerTitle: true),
        body: const Padding(padding: EdgeInsets.all(16), child: OneDriveButton()),
      ),
    );
  }
}
