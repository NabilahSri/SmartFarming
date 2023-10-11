import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farming/bottom_navigation.dart';
import 'package:http/http.dart' as http;
import 'package:smart_farming/halaman_detail_profil.dart';
import 'package:smart_farming/koneksi.dart';

const users = const {
  'dribbble@gmail.com': '12345',
  'hunter@gmail.com': 'hunter',
};

class HalamanMasuk extends StatelessWidget {
  String? userId;
  Duration get loginTime => Duration(milliseconds: 2250);

  Future<String?> loginUser(BuildContext context, LoginData data) async {
    final response = await http.post(
      Uri.parse(koneksi().baseUrl + 'auth/login'),
      body: {
        'email': data.name,
        'password': data.password,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final user = responseData['user'];
      final token = responseData['token'];
      final id = user['id'].toString();
      final role = user['role'].toString();

      if (role == 'member') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('id', id);
        log(token);
        log(id);
      } else {
        return 'Anda bukan seorang member';
      }
    } else {
      return 'Login gagal, silakan coba lagi';
    }
    return null;
  }

  Future<String?> _signupUser(
      SignupData data, void Function(String id) onSignupSuccess) async {
    final response = await http.post(
      Uri.parse(koneksi().baseUrl + 'auth/register'),
      body: {
        'name': "member",
        'role': "member",
        'email': data.name,
        'password': data.password,
        'alamat': "tasik",
        'no_hp': "098765432199",
        'jenis_kelamin': "perempuan",
      },
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      final id = responseData['user']['id'].toString();
      final email = responseData['user']['email'];
      final password = responseData['user']['password'];
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('userEmail', email);
      prefs.setString('userPassword', password);
      onSignupSuccess(id);
      return null;
    } else {
      log('Registrasi gagal, ada kesalahan pada server');
      return 'Registrasi gagal, ada kesalahan pada server';
    }
  }

  Future<String?> _recoverPassword(String name) {
    debugPrint('Name: $name');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(name)) {
        return 'User not exists';
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isLogin = true;
    String? registrationMessage;

    return FlutterLogin(
      logo: AssetImage('assets/images/smart_farming2.png'),
      onLogin: (loginData) {
        return loginUser(context, loginData);
      },
      onSignup: (signupData) async {
        isLogin = false;
        final errorMessage = await _signupUser(signupData, (id) {
          registrationMessage = null;
          userId = id;
        });
        if (errorMessage != null) {
          registrationMessage = errorMessage;
        }
        return registrationMessage;
      },
      onSubmitAnimationCompleted: () {
        if (isLogin == true) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => SolomonNavigationBar(id: 0),
          ));
        } else if (isLogin == false) {
          if (registrationMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(registrationMessage!),
            ));
          } else {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => HalamanDetailProfil(
                userId: userId,
              ),
            ));
          }
        }
      },
      onRecoverPassword: _recoverPassword,
    );
  }
}
