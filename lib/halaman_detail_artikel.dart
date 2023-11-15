import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smart_farming/koneksi.dart';

class HalamanDetailArtikel extends StatefulWidget {
  final String artikelId;
  const HalamanDetailArtikel({super.key, required this.artikelId});

  @override
  State<HalamanDetailArtikel> createState() => _HalamanDetailArtikelState();
}

class _HalamanDetailArtikelState extends State<HalamanDetailArtikel> {
  Informasi? selectedInformasi;
  Future<void> _fetchSelectedInformasi() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final response = await http.get(
      Uri.parse(
          koneksi().baseUrl + 'info/show/${widget.artikelId}?token=$token'),
    );
    log('widget.artikelId: ${widget.artikelId}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      final informasiData = jsonData['informasi'];
      for (var informasi in informasiData) {
        if (informasi['id'] == int.parse(widget.artikelId)) {
          setState(() {
            selectedInformasi = Informasi(
              id: informasi['id'].toString(),
              judul: informasi['judul'],
              foto: informasi['foto'],
              deskripsi: informasi['deskripsi'],
            );
          });
          log(selectedInformasi!.foto);
          return;
        }
      }
      log('Data informasi dengan ID ${widget.artikelId} tidak ditemukan');
    } else {
      log('Gagal memuat data informasi. Status code: ${response.statusCode}');
    }
  }

  @override
  void initState() {
    _fetchSelectedInformasi();
    super.initState();
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
          'Detail Artikel',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ' ${selectedInformasi?.judul}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    selectedInformasi != null && selectedInformasi?.foto != null
                        ? Image.network(selectedInformasi!.foto,
                            width: 175, height: 200)
                        : Text("Image not available"),
                  ],
                ),
              ],
            ),
            Text(
              '${selectedInformasi?.deskripsi}',
              style: TextStyle(fontSize: 16),
            )
          ],
        ),
      ),
    );
  }
}

class Informasi {
  final String id;
  final String judul;
  final String foto;
  final String deskripsi;

  Informasi({
    required this.id,
    required this.judul,
    required this.foto,
    required this.deskripsi,
  });
}
