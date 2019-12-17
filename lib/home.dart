import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_presensi/entity/Attendance.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_presensi/helper/constant.dart' as Constant;
import 'package:http/http.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_id/device_id.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();

//  String _authorizedOrNot = "Not Authorized";
//  List<BiometricType> _availableBiometricTypes = List<BiometricType>();
  String _userName = '';
  String _userId;
  String _token = '';
  bool _isCheckedIn = false;
  bool _loginStatus = false;
  String _time = '-';
  String _connection = '';

  @override
  void initState() {
    super.initState();
    _getDeviceToken();
    _getPreferences();
  }

  _getPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName');
      _userId = prefs.getString('userId');
      _isCheckedIn = prefs.getBool('userCheck');
      _loginStatus = prefs.getBool('userStatus');
      _time = prefs.getString('userCheckTime');
    });
  }

  _getDeviceToken() async {
    _token = await DeviceId.getID;
    Fluttertoast.showToast(msg: "Login successful");
  }

//  Future<void> _getListOfBiometricTypes() async {
//    List<BiometricType> listofBiometrics;
//    try {
//      listofBiometrics = await _localAuthentication.getAvailableBiometrics();
//    } on PlatformException catch (e) {
//      print(e);
//    }
//
//    if (!mounted) return;
//
//    setState(() {
//      _availableBiometricTypes = listofBiometrics;
//    });
//  }

  Future<void> _authorizeNow() async {
    bool isAuthorized = false;
    try {
      isAuthorized = await _localAuthentication.authenticateWithBiometrics(
        localizedReason:
            "Gently place your finger on the fingerprint sensor to ${_isCheckedIn ? "Checked-In" : "Checked-Out"}",
        useErrorDialogs: true,
        stickyAuth: true,
      );
    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) return;

    if (isAuthorized) {
      _attendancePostRequest(_userId, _token);
    }
  }

  _attendancePostRequest(String userId, String token) async {
    // set up POST request arguments
    String url = Constant.ATTENDANCE_URL;
    Map<String, String> headers = {"Content-type": "application/json"};
    String json = '{"userId": "$userId", "token": "$token"}';
    // make POST request
    Response response;
    try {
      response = await post(url, headers: headers, body: json);
    } on Exception catch(error) {
      setState(() {
        _connection = 'Failed, please check your connection';
      });
    }

    // check the status code for the result
    int statusCode = response.statusCode;
    // this API passes back the id of the new item added to the body
    String body = response.body;

    Map<String, dynamic> map = jsonDecode(body);

    if (statusCode == 200) {
      Attendance attendance = Attendance.fromJson(map);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('attendanceTime', attendance.time);

      setState(() {
        _connection = '';
        _time = attendance.time;
        if (_isCheckedIn)
          _isCheckedIn = false;
        else
          _isCheckedIn = true;
      });

      prefs.setBool('userCheck', _isCheckedIn);
      prefs.setString('userCheckTime', _time);

      return true;
    }
  }

  void _logoutAction(String choice) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    Navigator.pushReplacementNamed(context, Constant.FORM);
  }

  String getDartDateFromNetUTC(String netUtcDate) {
    if (netUtcDate != null) {
      //    print(netUtcDate);
      var dateParts = netUtcDate.split(".");
      var anotherDate = dateParts[0].split('T');
      //    print(anotherDate);
      var actualDate = DateFormat('yyyy-MM-dd - HH:mm')
          .format(DateTime.parse("${anotherDate[0]} ${anotherDate[1]}Z"));
      return actualDate;
    } else {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        actionsIconTheme: IconThemeData(color: Colors.black),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _logoutAction,
            itemBuilder: (context) {
              return Constant.choices.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: 32.0),
              child: Text(
                'Fintas',
                style: TextStyle(
                  fontSize: 48.0,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Welcome, $_userName'),
            ),
            Text(
              'Login status',
              textAlign: TextAlign.center,
            ),
            Text(
              _loginStatus ? 'Success' : 'Failed',
              style: TextStyle(color: _loginStatus ? Colors.green : Colors.red),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: MaterialButton(
                color: Theme.of(context).primaryColor,
                onPressed: _authorizeNow,
                child: Text(
                  _isCheckedIn ? 'Checked-Out' : 'Checked-In',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Text(
              'Last attendance',
              textAlign: TextAlign.center,
            ),
            Text(
              _isCheckedIn
                  ? 'Checked-In\n${getDartDateFromNetUTC(_time)}'
                  : 'Checked-Out\n${getDartDateFromNetUTC(_time)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: _isCheckedIn ? Colors.green : Colors.red),
            ),
            Text(
              _connection,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
//            Text("Can we check Biometric : $_canCheckBiometric"),
//            RaisedButton(
//              onPressed: () { _navigate(Constant.FORM); },
//              child: Text("Check Biometric"),
//              color: Colors.red,
//              colorBrightness: Brightness.light,
//            ),
//            Text("List Of Biometric : ${_availableBiometricTypes.toString()}"),
//            RaisedButton(
//              onPressed: _getListOfBiometricTypes,
//              child: Text("List of Biometric Types"),
//              color: Colors.red,
//              colorBrightness: Brightness.light,
//            ),
//            Text("Authorized : $_authorizedOrNot"),
//            RaisedButton(
//              onPressed: _authorizeNow,
//              child: Text("Authorize now"),
//              color: Colors.red,
//              colorBrightness: Brightness.light,
//            ),
          ],
        ),
      ),
    );
  }
}
