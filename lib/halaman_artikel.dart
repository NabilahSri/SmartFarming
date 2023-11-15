import 'dart:convert';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farming/halaman_detail_artikel.dart';
import 'package:smart_farming/koneksi.dart';

class HalamanArtikel extends StatefulWidget {
  const HalamanArtikel({super.key});

  @override
  State<HalamanArtikel> createState() => _HalamanArtikelState();
}

class _HalamanArtikelState extends State<HalamanArtikel> {
  List<Map<String, dynamic>> informasi = [];
  List<Map<String, dynamic>> searchResults = [];

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

  @override
  void initState() {
    super.initState();
    fetchInformasi();
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
          'Artikel',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari artikel...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                  onChanged: (query) {
                    setState(() {
                      searchResults = informasi
                          .where((item) => item['judul']
                              .toLowerCase()
                              .contains(query.toLowerCase()))
                          .toList();
                    });
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: searchResults.isNotEmpty
                  ? searchResults.length
                  : informasi.length,
              separatorBuilder: (BuildContext context, int index) {
                return SizedBox(height: 16.0);
              },
              itemBuilder: (BuildContext context, int index) {
                final item = searchResults.isNotEmpty
                    ? searchResults[index]
                    : informasi[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HalamanDetailArtikel(
                            artikelId: item['id'].toString()),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: CachedNetworkImage(
                            imageUrl: item['foto'],
                            width: 500,
                            height: 150,
                            placeholder: (context, url) => Container(
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
            ),
          ),
        ],
      ),
    );
  }
}
