import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farming/bottom_navigation.dart';
import 'package:smart_farming/koneksi.dart';

class HalamanTambahKebun extends StatefulWidget {
  const HalamanTambahKebun({super.key});

  @override
  State<HalamanTambahKebun> createState() => _HalamanTambahKebunState();
}

class _HalamanTambahKebunState extends State<HalamanTambahKebun> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isImageSelected = false;
  bool isLocationSelected = false;
  double? selectedLatitude;
  double? selectedLongitude;
  Marker? tappedMarker;
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  File? _imageFile;
  String _searchKeyword = '';
  Future<List<Map<String, dynamic>>>? _perangkatData;
  List<Map<String, dynamic>> _tanamanList = [];
  List<Map<String, dynamic>> _filteredTanamanList = [];
  String? _selectedPlantImageUrl;
  bool _isPlantSelected = false;
  String? _selectedGardenType;
  final TextEditingController _namaKebunController = TextEditingController();
  final TextEditingController _namaPemilikController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _luascontroller = TextEditingController();
  String? selectedPerangkatId;
  String? selectedSatuan;
  Map<String, dynamic>? _selectedPlant;
  Future<void> _fetchPlantData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http
        .get(Uri.parse(koneksi().baseUrl + 'tanaman/show?token=$token'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      final data = jsonData['tanaman'];
      List<Map<String, dynamic>> plantDataList = [];
      for (var item in data) {
        plantDataList.add({
          'id': item['id'],
          'nama': item['nama'],
          'foto': item['foto'],
        });
      }
      setState(() {
        _tanamanList = plantDataList;
        _filteredTanamanList = _tanamanList;
      });
    } else {
      throw Exception('Gagal memuat data tanaman');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPerangkatData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('id');

    final response = await http.get(
      Uri.parse(koneksi().baseUrl + 'perangkat/show/$userId?token=$token'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      final data = jsonData['perangkat'];
      List<Map<String, dynamic>> perangkatDataList = [];

      for (var item in data) {
        perangkatDataList.add({
          'id': item['id'],
          'no_seri': item['no_seri'],
        });
      }

      return perangkatDataList;
    } else {
      throw Exception('Gagal memuat data perangkat');
    }
  }

  Future<void> _addKebun() async {
    log("Tombol simpan di klik");
    final String tanggalSekarang =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? id = prefs.getString('id');

    if (_selectedPlant == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Pilih Tanaman'),
          content: Text('Harap pilih tanaman sebelum menyimpan data kebun.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(koneksi().baseUrl + 'kebun/tambah?token=$token'),
    );

    request.fields['id_user'] = id!;
    request.fields['id_tanaman'] = _selectedPlant!['id'].toString();
    request.fields['jenis_kebun'] = _selectedGardenType!;
    request.fields['nama_kebun'] = _namaKebunController.text;
    request.fields['nama_pemilik'] = _namaPemilikController.text;
    request.fields['id_perangkat'] = selectedPerangkatId!;
    request.fields['alamat'] = _alamatController.text;
    request.fields['luas'] = _luascontroller.text;
    request.fields['satuan'] = selectedSatuan!;
    request.fields['tgl_dibuat'] = tanggalSekarang;
    request.fields['latitude'] = selectedLatitude.toString();
    request.fields['longitude'] = selectedLongitude.toString();

    if (_imageFile != null) {
      final image = await http.MultipartFile.fromPath(
        'foto',
        _imageFile!.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(image);
    }

    setState(() {
      isLoading = true;
    });

    final response = await request.send();

    if (response.statusCode == 201) {
      log("berhasil");
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => SolomonNavigationBar(id: 1),
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data berhasil disimpan!'),
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    } else {
      log("gagal");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data gagal disimpan!'),
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  void _takePicture() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        isImageSelected = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPlantData();
    _perangkatData = _fetchPerangkatData();
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
          'Tambah Kebun',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah detail kebun',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Isi detail kebun dibawah ini',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Card(
                  color: Color.fromARGB(255, 255, 255, 255),
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                child: _selectedPlant != null
                                    ? Text(
                                        _selectedPlant!['nama'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20),
                                      )
                                    : Text(''),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Pilih tanaman yang akan di tanami di lingkungan anda',
                                style: TextStyle(
                                    color: Colors.black.withOpacity(0.6),
                                    fontSize: 15),
                              ),
                              SizedBox(height: 20),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: 33,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isPlantSelected
                                        ? Color.fromARGB(255, 77, 129, 95)
                                        : Colors.grey,
                                    textStyle: TextStyle(fontSize: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  onPressed: () {
                                    _showPlantSelectionDialog();
                                  },
                                  child: Text(
                                    'Pilih Tanaman',
                                    style: TextStyle(
                                      color: _isPlantSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Container(
                          width: 116,
                          height: 116,
                          child: _selectedPlantImageUrl != null
                              ? Image.network(
                                  _selectedPlantImageUrl!,
                                )
                              : Text('Tidak ada gambar'),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  color: Color.fromARGB(255, 255, 255, 255),
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Pilih jenis kebun yang akan dibuat',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                              fontSize: 15),
                        ),
                        SizedBox(height: 16),
                        Container(
                          height: 33,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  _selectedGardenType == 'Green House'
                                      ? Color.fromARGB(255, 77, 129, 95)
                                      : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedGardenType = 'Green House';
                              });
                            },
                            child: Text(
                              'Green House',
                              style: TextStyle(
                                color: _selectedGardenType == 'Green House'
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 33,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  _selectedGardenType == 'Vertical Farming'
                                      ? Color.fromARGB(255, 77, 129, 95)
                                      : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedGardenType = 'Vertical Farming';
                              });
                            },
                            child: Text(
                              'Vertical Farming',
                              style: TextStyle(
                                color: _selectedGardenType == 'Vertical Farming'
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 33,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  _selectedGardenType == 'Tradisional'
                                      ? Color.fromARGB(255, 77, 129, 95)
                                      : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedGardenType = 'Tradisional';
                              });
                            },
                            child: Text(
                              'Tradisional',
                              style: TextStyle(
                                color: _selectedGardenType == 'Tradisional'
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.only(right: 10, left: 10),
                  child: TextFormField(
                    controller: _namaKebunController,
                    decoration: InputDecoration(
                        labelText: 'Nama Kebun',
                        hintText: 'Masukan nama kebun'),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Nama kebun tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(right: 10, left: 10),
                  child: TextFormField(
                    controller: _namaPemilikController,
                    decoration: InputDecoration(
                        labelText: 'Nama Pemilik',
                        hintText: 'Masukan nama pemilik'),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Nama pemilik tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(right: 10, left: 10),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _perangkatData,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('Tidak ada data tersedia');
                      } else {
                        return DropdownButtonFormField<String>(
                          decoration:
                              InputDecoration(labelText: 'Pilih Perangkat'),
                          items: snapshot.data?.map<DropdownMenuItem<String>>(
                            (Map<String, dynamic> perangkat) {
                              return DropdownMenuItem<String>(
                                value: perangkat['id'].toString(),
                                child: Text(perangkat['no_seri']),
                              );
                            },
                          ).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedPerangkatId = value;
                            });
                          },
                          value: selectedPerangkatId,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Pilih perangkat terlebih dahulu';
                            }
                            return null;
                          },
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 10, left: 10),
                  child: TextFormField(
                    controller: _alamatController,
                    decoration: InputDecoration(
                        labelText: 'Alamat', hintText: 'Masukan alamat'),
                    maxLines: 3,
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Alamat tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 10, left: 10),
                  child: TextFormField(
                    controller: _luascontroller,
                    decoration: InputDecoration(
                        labelText: 'Luas Kebun',
                        hintText: 'Masukan luas kebun'),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Luas kebun tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(right: 10, left: 10),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Pilih Satuan'),
                    items: [
                      DropdownMenuItem(value: 'm2', child: Text('m2')),
                      DropdownMenuItem(value: 'hektar', child: Text('hektar'))
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedSatuan = value;
                      });
                    },
                    value: selectedSatuan,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pilih satuan terlebih dahulu';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Text(
                    "Pilih Lokasi",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Container(
                    height: 160,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(-1.605328, 117.451067),
                        zoom: 4.0,
                      ),
                      markers: markers.toSet(),
                      onMapCreated: (controller) {
                        mapController = controller;
                      },
                      onTap: (LatLng latLng) {
                        setState(() {
                          markers.clear();
                          tappedMarker = Marker(
                            markerId: MarkerId("tapped_location"),
                            position: latLng,
                            infoWindow: InfoWindow(
                              title: "Lokasi Dipilih",
                            ),
                          );
                          selectedLatitude = latLng.latitude;
                          selectedLongitude = latLng.longitude;
                          markers.add(tappedMarker!);
                          isLocationSelected = true;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Text(
                    "Foto Kebun",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Container(
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : Center(
                            child: Text(
                              'Tidak ada gambar',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(right: 10, left: 10),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    child: ElevatedButton(
                      onPressed: () {
                        _takePicture();
                      },
                      child: Text(
                        'Buka Kamera',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 183, 184, 183),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10, left: 10),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (!isLocationSelected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Pilih lokasi terlebih dahulu'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else if (!isImageSelected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Pilih gambar terlebih dahulu'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            _addKebun();
                          }
                        }
                      },
                      child: isLoading
                          ? CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              'Simpan',
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
                ),
                SizedBox(height: 30)
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlantSelectionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari Tanaman',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchKeyword = value;
                    _filteredTanamanList = _tanamanList
                        .where((tanaman) => tanaman['nama']
                            .toLowerCase()
                            .contains(_searchKeyword.toLowerCase()))
                        .toList();
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTanamanList.length,
                itemBuilder: (BuildContext context, int index) {
                  final namaTanaman = _filteredTanamanList[index]['nama'];
                  final imageUrl = _filteredTanamanList[index]['foto'];
                  return ListTile(
                    leading: Icon(Icons.add_circle),
                    title: Text(namaTanaman),
                    onTap: () {
                      setState(() {
                        _selectedPlant = _filteredTanamanList[index];
                        _selectedPlantImageUrl = imageUrl;
                        _isPlantSelected = true;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
