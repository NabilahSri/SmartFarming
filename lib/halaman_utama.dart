import 'dart:convert';
import 'dart:developer';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farming/koneksi.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key, required this.title});

  final String title;

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> {
  bool isSearchActive = false;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> kebunData = [];
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> informasi = [];
  Future<Map<String, dynamic>> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('id');
    String? token = prefs.getString('token');
    final response = await http
        .get(Uri.parse(koneksi().baseUrl + 'auth/show/$userId?token=$token'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return {
        'name': data['user']['name'],
        'foto': data['user']['foto'],
      };
    } else {
      log('Gagal mengambil data dari API');
      return {
        'name': null,
        'foto': null,
      };
    }
  }

  Future<void> fetchDataKebun() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('id');
    final response = await http
        .get(Uri.parse(koneksi().baseUrl + 'kebun/show/$userId?token=$token'));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      setState(() {
        kebunData = jsonResponse['kebun'];
        log('$kebunData');
      });
    } else {
      setState(() {
        kebunData = [];
      });
      log("gagal mengambil data kebun");
    }
  }

  Future<void> fetchInformasi() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final response =
        await http.get(Uri.parse(koneksi().baseUrl + 'info/show?token=$token'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['informasi'];
      setState(() {
        informasi = data.cast<Map<String, dynamic>>();
      });
    } else {
      log('Gagal mengambil data informasi dari API');
    }
  }

  void _performSearch() {
    final String query = _searchController.text.toLowerCase();

    // Hapus penanda yang ada
    _clearMarkers();

    if (query.isEmpty) {
      // Jika query kosong, tampilkan semua marker kebun
      _addAllMarkers();
      isSearchActive = false;
    } else {
      // Temukan kebun dengan nama yang cocok
      final foundKebun = kebunData.firstWhere(
        (kebun) => kebun['nama_kebun'].toLowerCase() == query,
        orElse: () => null,
      );

      if (foundKebun != null) {
        // Tambahkan penanda untuk kebun yang ditemukan
        _addMarker(
          LatLng(
            double.tryParse(foundKebun['latitude']) ?? 0.0,
            double.tryParse(foundKebun['longitude']) ?? 0.0,
          ),
          foundKebun['nama_kebun'],
        );
        isSearchActive = true;
      } else {
        isSearchActive = false;
      }
    }
  }

  void _addAllMarkers() {
    for (var kebun in kebunData) {
      _addMarker(
        LatLng(
          double.tryParse(kebun['latitude']) ?? 0.0,
          double.tryParse(kebun['longitude']) ?? 0.0,
        ),
        kebun['nama_kebun'],
      );
    }
  }

// Helper method to add markers to the map
  void _addMarker(LatLng position, String kebunName) {
    final marker = Marker(
      markerId: MarkerId(kebunName),
      position: position,
      infoWindow: InfoWindow(title: kebunName),
    );

    _markers.add(marker);
  }

// Helper method to clear markers from the map
  void _clearMarkers() {
    setState(() {
      _markers.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    _addAllMarkers();
    fetchInformasi();
    fetchDataKebun();
    isSearchActive = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        toolbarHeight: 80.0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: Image.asset(
          'assets/images/smart_farming.png',
          width: 200,
          height: 200,
        ),
        actions: <Widget>[
          FutureBuilder<Map<String, dynamic>>(
            future: fetchData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return Text('Terjadi kesalahan: ${snapshot.error}');
              } else {
                String? foto = snapshot.data?['foto'];

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(foto ?? ''),
                    radius: 20,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FutureBuilder<Map<String, dynamic>>(
              future: fetchData(),
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
                  return Text('Terjadi kesalahan: ${snapshot.error}');
                } else {
                  String? namaPengguna = snapshot.data?['name'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Hai,',
                            style: TextStyle(
                              fontSize: 20.0,
                              color: Color.fromARGB(255, 92, 105, 99),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            namaPengguna ?? '',
                            style: TextStyle(
                              fontSize: 20.0,
                              color: Color.fromARGB(255, 92, 105, 99),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '👋',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      Text(
                        'Selamat Datang!',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 92, 105, 99),
                        ),
                      ),
                      SizedBox(height: 45),
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 200,
                          autoPlay: true,
                          enlargeCenterPage: true,
                        ),
                        items: informasi.map((item) {
                          return Builder(
                            builder: (BuildContext context) {
                              return GestureDetector(
                                onTap: () {
                                  _showItemDetails(item);
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 5.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        child: CachedNetworkImage(
                                          imageUrl: item['foto'],
                                          placeholder: (context, url) =>
                                              Container(
                                            width: 500.0,
                                            height: 150.0,
                                            color: Colors.grey,
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Icon(Icons.error),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 10,
                                      right: 10,
                                      bottom: 10,
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          item['judul'],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 40),
                      Text(
                        "Lokasi Kebun",
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 92, 105, 99),
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Column(
                            children: [
                              Stack(children: [
                                Container(
                                  height: 300,
                                  child: GoogleMap(
                                    // Konfigurasi GoogleMap Anda yang sudah ada
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(-1.605328, 117.451067),
                                      zoom: 4.0,
                                    ),
                                    markers: isSearchActive
                                        ? _markers
                                        : kebunData.map((kebun) {
                                            return Marker(
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
                                            );
                                          }).toSet(),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 200,
                                    padding: const EdgeInsets.only(
                                        right: 8, left: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        labelText: 'Search Kebun',
                                        border: InputBorder.none,
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            _performSearch();
                                          },
                                          icon: Icon(Icons.search),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ])
                            ],
                          )),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> selectedItem) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedItem['judul'],
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              CachedNetworkImage(
                height: 200,
                width: MediaQuery.of(context).size.width,
                imageUrl: selectedItem['foto'],
                placeholder: (context, url) => Container(
                  width: 200.0,
                  height: 200.0,
                  color: Colors.grey,
                ),
                errorWidget: (context, url, error) => Icon(Icons.error),
                fit: BoxFit.cover,
              ),
              SizedBox(height: 10),
              Text(
                selectedItem['deskripsi'],
                style: TextStyle(fontSize: 18.0),
              ),
            ],
          ),
        );
      },
    );
  }
}
