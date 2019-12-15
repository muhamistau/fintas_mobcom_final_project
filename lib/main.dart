import 'package:flutter/material.dart';
import 'package:flutter_presensi/formPage.dart';
import 'package:flutter_presensi/home.dart';
import 'package:flutter_presensi/helper/constant.dart' as Constant;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fintas',
      routes: {
        Constant.FORM: (context) => FormPage(),
        Constant.HOME: (context) => MyHomePage()
      },
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Work Sans',
      ),
    );
  }
}
