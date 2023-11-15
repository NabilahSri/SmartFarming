import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smart_farming/bottom_navigation.dart';
import 'package:smart_farming/koneksi.dart';

class HalamanUbahProfil extends StatefulWidget {
  const HalamanUbahProfil({super.key});

  @override
  State<HalamanUbahProfil> createState() => _HalamanUbahProfilState();
}

class _HalamanUbahProfilState extends State<HalamanUbahProfil> {
  File? _imageFile;
  File? _originalImageFile;

  UserProfile? userProfile;
  String? selectedGender;
  Future<UserProfile?>? _userDataFuture;

  Future<UserProfile?> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('id');
    String? token = prefs.getString('token');

    if (userId != null && token != null) {
      final response = await http.get(
          Uri.parse(koneksi().baseUrl + 'auth/show/$userId' + '?token=$token'));

      if (response.statusCode == 200) {
        final dynamic jsonData = jsonDecode(response.body);
        if (jsonData is Map<String, dynamic>) {
          final responseData = jsonData['user'];
          if (responseData != null) {
            return UserProfile.fromJson(responseData);
          } else {
            log('Respons tidak mengandung data pengguna');
          }
        } else {
          log('Respons tidak valid');
        }
      } else {
        log('gagal load profile');
      }
    } else {
      log('id tidak terpanggil');
    }
    return null;
  }

  Future<void> updateProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('id');
    String? token = prefs.getString('token');

    if (userId != null && token != null) {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(koneksi().baseUrl + 'auth/update/$userId' + '?token=$token'),
      );

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'foto',
          _imageFile!.path,
          // contentType: MediaType('image', 'jpeg'),
        ));
      }

      request.fields['name'] = userProfile?.name ?? '';
      request.fields['alamat'] = userProfile?.alamat ?? '';
      request.fields['email'] = userProfile?.email ?? '';
      request.fields['no_hp'] = userProfile?.no_hp ?? '';
      request.fields['jenis_kelamin'] =
          selectedGender ?? userProfile?.jenis_kelamin ?? '';

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var parsedData = jsonDecode(responseData);

        if (parsedData['success'] == true) {
          final updatedData = parsedData['data'];

          setState(() {
            userProfile?.imagePath = updatedData['foto'];
            userProfile?.name = updatedData['name'];
            userProfile?.alamat = updatedData['alamat'];
            userProfile?.email = updatedData['email'];
            userProfile?.no_hp = updatedData['no_hp'];
            userProfile?.jenis_kelamin = updatedData['jenis_kelamin'];
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profil berhasil diperbarui'),
              duration: Duration(seconds: 2),
            ),
          );

          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => SolomonNavigationBar(id: 3),
          ));

          log('Profil berhasil diperbarui');
          log(responseData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui profil'),
              duration: Duration(seconds: 2),
            ),
          );
          log('Gagal memperbarui profil');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ada kesalahan saat menghubungi server'),
            duration: Duration(seconds: 2),
          ),
        );
        log("ada kesalahan");
      }
    } else {
      log('ID Pengguna atau token tidak tersedia');
    }
  }

  void _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _originalImageFile = File(pickedFile.path);
      });
    }
  }

  void _takePicture() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _originalImageFile = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pilih Sumber Gambar"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.photo),
                title: Text("Ambil dari Galeri"),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Ambil Foto"),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePicture();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _userDataFuture = loadUserData();
    _userDataFuture?.then((userData) {
      setState(() {
        userProfile = userData;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          toolbarHeight: 80.0,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          title: Text(
            'Edit Profil',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: FutureBuilder(
            future: _userDataFuture,
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
                          color: Color.fromARGB(255, 77, 129, 95)),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('Error:${snapshot.error}');
              } else {
                if (userProfile == null) {
                  userProfile = snapshot.data;
                }
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Diri',
                          style: TextStyle(fontSize: 24),
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : null,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _showImagePickerDialog(context);
                              },
                              child: Text(
                                'Pilih Foto',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 99, 159, 236),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          initialValue: userProfile?.name ?? '',
                          onChanged: (value) {
                            setState(() {
                              userProfile?.name = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap',
                          ),
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Nama lengkap tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          initialValue: userProfile?.email ?? '',
                          onChanged: (value) {
                            setState(() {
                              userProfile?.email = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Email',
                          ),
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          initialValue: userProfile?.no_hp ?? '',
                          onChanged: (value) {
                            setState(() {
                              userProfile?.no_hp = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'No Handphone',
                          ),
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'No handphone tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          initialValue: userProfile?.alamat ?? '',
                          onChanged: (value) {
                            setState(() {
                              userProfile?.alamat = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Alamat',
                          ),
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Alamat tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration:
                              InputDecoration(labelText: 'Jenis Kelamin'),
                          items: [
                            DropdownMenuItem(
                                value: 'laki-laki', child: Text('Laki-laki')),
                            DropdownMenuItem(
                                value: 'perempuan', child: Text('Perempuan'))
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value!;
                            });
                          },
                          value: selectedGender,
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          child: ElevatedButton(
                            onPressed: () {
                              updateProfile();
                            },
                            child: Text(
                              'Perbarui data',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 77, 129, 95),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }));
  }
}

class UserProfile {
  String? imagePath;
  String name = '';
  String alamat = '';
  String email = '';
  String no_hp = '';
  String jenis_kelamin = '';

  UserProfile({
    this.imagePath,
    required this.name,
    required this.alamat,
    required this.email,
    required this.no_hp,
    required this.jenis_kelamin,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      imagePath: json['foto']?.toString(),
      name: json['name']?.toString() ?? '',
      alamat: json['alamat']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      no_hp: json['no_hp']?.toString() ?? '',
      jenis_kelamin: json['jenis_kelamin']?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return 'UserProfile{name: $name, alamat: $alamat, email: $email, no_hp: $no_hp, jenis_kelamin: $jenis_kelamin}';
  }
}
