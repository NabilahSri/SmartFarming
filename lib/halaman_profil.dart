import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smart_farming/halaman_masuk.dart';
import 'package:smart_farming/halaman_ubah_profil.dart';
import 'package:smart_farming/koneksi.dart';

class HalamanProfil extends StatefulWidget {
  const HalamanProfil({Key? key}) : super(key: key);

  @override
  _HalamanProfilState createState() => _HalamanProfilState();
}

class _HalamanProfilState extends State<HalamanProfil> {
  bool isLoggingOut = false;

  Future<void> logout() async {
    setState(() {
      isLoggingOut = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      try {
        final response = await http.post(
          Uri.parse(koneksi().baseUrl + 'auth/logout/' + '?token=$token'),
        );

        if (response.statusCode == 200) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Yakin ingin keluar?"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text("Ya"),
                      onTap: () {
                        prefs.remove('token');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HalamanMasuk()),
                        );
                      },
                    ),
                    ListTile(
                      title: Text("Tidak"),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }
      } catch (error) {
        print('Error during logout: $error');
      }
    }

    setState(() {
      isLoggingOut = false;
    });
  }

  Future<UserProfile?> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('id');
    String? token = prefs.getString('token');

    if (userId != null && token != null) {
      try {
        final response = await http.get(Uri.parse(
            koneksi().baseUrl + 'auth/show/$userId' + '?token=$token'));

        if (response.statusCode == 200) {
          final dynamic jsonData = jsonDecode(response.body);
          if (jsonData is Map<String, dynamic>) {
            final responseData = jsonData['user'];
            if (responseData != null) {
              return UserProfile.fromJson(responseData);
            } else {
              throw 'Respons tidak mengandung data pengguna';
            }
          } else {
            throw 'Respons tidak valid';
          }
        } else {
          throw 'Gagal load profile';
        }
      } catch (error) {
        print('Error loading user data: $error');
      }
    } else {
      print('ID tidak terpanggil');
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        toolbarHeight: 80.0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Profil',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HalamanUbahProfil(),
                ),
              );
            },
            child: Text(
              'Edit',
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: FutureBuilder<UserProfile?>(
            future: loadUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitChasingDots(
                      color: Colors.green,
                      size: 50.0,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 77, 129, 95),
                      ),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('Terjadi kesalahan: ${snapshot.error}');
              } else {
                final userProfile = snapshot.data;
                return userProfile != null
                    ? Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                NetworkImage(userProfile.profileImageUrl),
                          ),
                          SizedBox(height: 16),
                          Text(userProfile.name,
                              style: TextStyle(fontSize: 20)),
                          SizedBox(height: 16),
                          Card(
                            color: Colors.grey[100],
                            child: Container(
                              padding: EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Identitas Diri',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Email',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Text(userProfile.email,
                                          style: TextStyle(fontSize: 16)),
                                      SizedBox(height: 16),
                                      Text('No Handphone',
                                          style: TextStyle(fontSize: 16)),
                                      Text(userProfile.no_hp,
                                          style: TextStyle(fontSize: 16)),
                                      SizedBox(height: 16),
                                      Text('Alamat',
                                          style: TextStyle(fontSize: 16)),
                                      Text(userProfile.alamat,
                                          style: TextStyle(fontSize: 16)),
                                      SizedBox(height: 16),
                                      Text('Jenis Kelamin',
                                          style: TextStyle(fontSize: 16)),
                                      Text(userProfile.jenis_kelamin,
                                          style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Card(
                            color: Colors.grey[100],
                            child: InkWell(
                              onTap: isLoggingOut
                                  ? null
                                  : () {
                                      logout();
                                    },
                              child: Container(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.login, size: 18),
                                    Text(
                                      ' Keluar',
                                      style: TextStyle(fontSize: 18),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    : Text('Data pengguna kosong');
              }
            },
          ),
        ),
      ),
    );
  }
}

class UserProfile {
  final String name;
  final String alamat;
  final String email;
  final String no_hp;
  final String jenis_kelamin;
  final String profileImageUrl;

  UserProfile({
    required this.name,
    required this.alamat,
    required this.email,
    required this.no_hp,
    required this.jenis_kelamin,
    required this.profileImageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'].toString(),
      alamat: json['alamat'].toString(),
      email: json['email'].toString(),
      no_hp: json['no_hp'].toString(),
      jenis_kelamin: json['jenis_kelamin'].toString(),
      profileImageUrl: json['foto'].toString(),
    );
  }
}
