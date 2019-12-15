import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_presensi/entity/User.dart';
import 'package:flutter_presensi/helper/constant.dart' as Constant;
import 'package:http/http.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class FormPage extends StatefulWidget {
  FormPage({Key key}) : super(key: key);

  @override
  FormPageState createState() => FormPageState();
}

class FormPageState extends State<FormPage> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _canCheckBiometric = false;
  String _biometricsAvailable = '';
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscureText = true;
  String _userId = '';
  String _login = '';

  @override
  void initState() {
    super.initState();
    checkLogin();
    _checkBiometric();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Fintas',
                style: TextStyle(
                  fontSize: 24.0,
                ),
              ),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  icon: Icon(Icons.mail),
                  labelText: 'Email address',
                ),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please input valid email address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                    icon: Icon(Icons.lock_open),
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureText ^= true;
                        });
                      },
                    )),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
                obscureText: _obscureText,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: MaterialButton(
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    // Validate returns true if the form is valid, or false
                    // otherwise.
                    if (_formKey.currentState.validate()) {
                      // If the form is valid, display a Snackbar.
//                        Scaffold.of(context)
//                            .showSnackBar(SnackBar(content: Text('Processing Data')));
                      _loginPostRequest(
                          emailController.text, passwordController.text);
                    }
                  },
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Text(_login),
              Text(_biometricsAvailable)
            ],
          ),
        ),
      )),
    );
  }

  Future<void> _checkBiometric() async {
    bool canCheckBiometric = false;
    try {
      canCheckBiometric = await _localAuthentication.canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) return;

    setState(() {
      _canCheckBiometric = canCheckBiometric;
      if (_canCheckBiometric) _biometricsAvailable = 'Your device support biometrics sensor';
      else _biometricsAvailable = 'Your device does not support biometrics sensor';
    });
  }

  Future checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';

    if (_userId != '' || _userId.isNotEmpty) {
      Navigator.pushReplacementNamed(context, Constant.HOME);
    } else {
      Navigator.pushReplacementNamed(context, Constant.LOGIN_URL);
    }
  }

  Future<bool> _loginPostRequest(String email, String password) async {
    // set up POST request arguments
    String url = Constant.LOGIN_URL;
    Map<String, String> headers = {"Content-type": "application/json"};
    String json = '{"email": "$email", "password": "$password"}';
    // make POST request
    Response response = await post(url, headers: headers, body: json);
    // check the status code for the result
//    int statusCode = response.statusCode;
    // this API passes back the id of the new item added to the body
    String body = response.body;

    Map<String, dynamic> map = jsonDecode(body);

    if (map['success'] == 1) {
      User user = User.fromJson(map);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('userId', user.id);
      prefs.setString('userName', user.name);
      prefs.setBool('userCheck', user.isCheckedIn);
      prefs.setString('userToken', user.token);
      if (user.status == 0)
        prefs.setBool('userStatus', false);
      else
        prefs.setBool('userStatus', true);

      Navigator.pushReplacementNamed(context, Constant.HOME);

      return true;
    } else {
      setState(() {
        _login = "Your email or password might be wrong";
      });
      return false;
    }
  }
}
