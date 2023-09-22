import 'package:flutter/material.dart';
import './examples.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String redirectURL = '';
  String clientID = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('OneDrive Demo'),
          centerTitle: true,
        ),
        body: const Center(
          child: OneDriveButton(),
        ),
      ),
    );
  }
}
