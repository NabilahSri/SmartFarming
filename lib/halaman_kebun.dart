import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farming/halaman_detail_kebun.dart';
import 'dart:convert';

import 'package:smart_farming/halaman_tambah_kebun.dart';
import 'package:smart_farming/koneksi.dart';

class HalamanKebun extends StatefulWidget {
  const HalamanKebun({Key? key});

  @override
  State<HalamanKebun> createState() => _HalamanKebunState();
}

class _HalamanKebunState extends State<HalamanKebun> {
  List<dynamic> kebunData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('id');
    final response = await http
        .get(Uri.parse(koneksi().baseUrl + 'kebun/show/$userId?token=$token'));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      setState(() {
        kebunData = jsonResponse['kebun'];
        isLoading = false;
      });
    } else {
      setState(() {
        kebunData = [];
        isLoading = false;
      });
      throw Exception('Gagal mengambil data kebun');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80.0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: Text(
          'Kebun',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => HalamanTambahKebun(),
                  ),
                );
              },
            ),
          )
        ],
      ),
      body: isLoading
          ? Column(
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
            )
          : kebunData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 50,
                        color: Colors.orange,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Data Kebun Tidak Ditemukan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tambahkan kebun baru untuk memulai.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: kebunData.length,
                    itemBuilder: (context, index) {
                      final kebun = kebunData[index];
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kebun['tanaman']['nama'],
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 77, 129, 95)),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.place,
                                      size: 16,
                                      color: Color.fromARGB(255, 77, 129, 95),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      kebun['alamat'],
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.nature,
                                      size: 16,
                                      color: Color.fromARGB(255, 177, 64, 64),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      kebun['jenis_kebun'],
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 345,
                                      height: 200,
                                      margin: EdgeInsets.only(top: 16),
                                      child: GoogleMap(
                                        initialCameraPosition: CameraPosition(
                                          target: LatLng(
                                            double.tryParse(
                                                    kebun['latitude']) ??
                                                0.0,
                                            double.tryParse(
                                                    kebun['longitude']) ??
                                                0.0,
                                          ),
                                          zoom: 4.0,
                                        ),
                                        markers: {
                                          Marker(
                                            markerId:
                                                MarkerId(kebun['nama_kebun']),
                                            position: LatLng(
                                              double.tryParse(
                                                      kebun['latitude']) ??
                                                  0.0,
                                              double.tryParse(
                                                      kebun['longitude']) ??
                                                  0.0,
                                            ),
                                            infoWindow: InfoWindow(
                                                title: kebun['nama_kebun']),
                                          ),
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    if (kebun['id'] != null &&
                                        kebun['perangkat']['no_seri'] != null) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              HalamanDetailKebun(
                                            kebunId: kebun['id'].toString(),
                                            noSeri: kebun['perangkat']
                                                    ['no_seri']
                                                .toString(),
                                          ),
                                        ),
                                      );
                                    } else {
                                      print('ID atau no seri tidak ada');
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.eco,
                                        size: 24,
                                        color: Color.fromARGB(255, 77, 129, 95),
                                      ),
                                      SizedBox(width: 8),
                                      Column(
                                        children: [
                                          Text('Pemilik',
                                              style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 77, 129, 95),
                                                  fontWeight: FontWeight.bold)),
                                          Text(kebun['nama_pemilik'],
                                              style:
                                                  TextStyle(color: Colors.grey))
                                        ],
                                      ),
                                    ],
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(255, 255, 255, 255),
                                    side: BorderSide(
                                        color:
                                            Color.fromARGB(255, 77, 129, 95)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (kebun['id'] != null &&
                                        kebun['perangkat']['no_seri'] != null) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              HalamanDetailKebun(
                                            kebunId: kebun['id'].toString(),
                                            noSeri: kebun['perangkat']
                                                    ['no_seri']
                                                .toString(),
                                          ),
                                        ),
                                      );
                                    } else {
                                      print('ID atau no seri tidak ada');
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.crop_square,
                                        size: 24,
                                        color: Color.fromARGB(255, 77, 129, 95),
                                      ),
                                      SizedBox(width: 8),
                                      Column(
                                        children: [
                                          Text('Area Kebun',
                                              style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 77, 129, 95),
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                            '${kebun['luas']} ${kebun['satuan']}',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(255, 255, 255, 255),
                                    side: BorderSide(
                                        color:
                                            Color.fromARGB(255, 77, 129, 95)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
