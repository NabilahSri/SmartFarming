import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farming/halaman_masuk.dart';
import 'package:smart_farming/koneksi.dart';
import 'package:http_parser/http_parser.dart';

class HalamanDetailProfil extends StatefulWidget {
  final String? userId;

  HalamanDetailProfil({super.key, required this.userId});

  @override
  State<HalamanDetailProfil> createState() => _HalamanDetailProfilState();
}

class _HalamanDetailProfilState extends State<HalamanDetailProfil> {
  String? _namaLengkap;
  String? _noHp;
  String? _alamat;
  String? selectedGender;
  File? imageFile;

  final TextEditingController _namalengkapController = TextEditingController();
  final TextEditingController _nohpController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  Future<void> saveData(String userId) async {
    final namaLengkap = _namalengkapController.text;
    final noHp = _nohpController.text;
    final alamat = _alamatController.text;

    if (namaLengkap.isEmpty ||
        noHp.isEmpty ||
        alamat.isEmpty ||
        selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harap isi semua kolom!'),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail');
    final password = prefs.getString('userPassword');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(koneksi().baseUrl + 'auth/detailregist/$userId'),
    );

    request.fields.addAll({
      'name': namaLengkap,
      'no_hp': noHp,
      'email': email!,
      'password': password!,
      'alamat': alamat,
      'jenis_kelamin': selectedGender!,
    });

    if (imageFile != null) {
      final image = await http.MultipartFile.fromPath(
        'foto',
        imageFile!.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(image);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih gambar terlebih dahulu!'),
        ),
      );
      return;
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data berhasil disimpan!'),
          ),
        );
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => HalamanMasuk(),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat mengirim data: $e'),
        ),
      );
    }
  }

  void _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  void _takePicture() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        toolbarHeight: 80.0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Text(
          'Detail Profil',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      imageFile != null ? FileImage(imageFile!) : null,
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
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 99, 159, 236),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _namalengkapController,
                onChanged: (value) {
                  setState(() {
                    _namaLengkap = value;
                  });
                },
                decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'Masukan nama lengkap'),
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
                controller: _nohpController,
                onChanged: (value) {
                  setState(() {
                    _noHp = value;
                  });
                },
                decoration: InputDecoration(
                    labelText: 'No Handphone',
                    hintText: 'Masukan no handphone'),
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
                controller: _alamatController,
                onChanged: (value) {
                  setState(() {
                    _alamat = value;
                  });
                },
                decoration: InputDecoration(
                    labelText: 'Alamat', hintText: 'Masukan alamat'),
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
                decoration: InputDecoration(labelText: 'Pilih jenis kelamin'),
                items: [
                  DropdownMenuItem(
                      value: 'laki-laki', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'perempuan', child: Text('Perempuan'))
                ],
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
                value: selectedGender,
              ),
              SizedBox(height: 16),
              Container(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: () async {
                    final id = widget.userId;

                    if (imageFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Pilih gambar terlebih dahulu!'),
                        ),
                      );
                      return;
                    }

                    await saveData(id!);
                  },
                  child: Text(
                    'Simpan data',
                    style: TextStyle(color: Colors.white, fontSize: 16),
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
      ),
    );
  }
}
