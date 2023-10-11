import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smart_farming/bottom_navigation.dart';
import 'package:smart_farming/halaman_ubah_kebun.dart';
import 'package:smart_farming/koneksi.dart';

class HalamanDetailKebun extends StatefulWidget {
  final String kebunId;
  final String noSeri;
  const HalamanDetailKebun(
      {super.key, required this.kebunId, required this.noSeri});

  @override
  State<HalamanDetailKebun> createState() => _HalamanDetailKebunState();
}

class _HalamanDetailKebunState extends State<HalamanDetailKebun> {
  final scaffoldContext = GlobalKey<ScaffoldState>();
  List<String> daftarKebun = [];
  Kebun? selectedKebun;
  bool isPump1On = false;
  bool isPump2On = false;
  dynamic dht1Temp = '';
  dynamic dht1Hum = '';
  int statusMotor1 = 0;
  int statusMotor2 = 0;
  Timer? _timer;
  int? pump1Value;
  int? pump2Value;

  Future<void> _kontrolpompa1(int pump1Value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final response = await http.post(
      Uri.parse(
          koneksi().baseUrl + 'controlmotor1/${widget.noSeri}/$pump1Value'),
    );
    log(pump1Value.toString());

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final status = jsonResponse['status'];
      final message = jsonResponse['message'];

      if (status == 'success') {
        log('berhasil');
        if (pump1Value == 1) {
          ScaffoldMessenger.of(scaffoldContext.currentContext!).showSnackBar(
            SnackBar(
              content: Text('Pompa 1 diaktifkan: $message'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(scaffoldContext.currentContext!).showSnackBar(
            SnackBar(
              content: Text('Pompa 1 dimatikan: $message'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        log('gagal');
        ScaffoldMessenger.of(scaffoldContext.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Gagal mengaktifkan Pompa 1: $message'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      log('error');
      ScaffoldMessenger.of(scaffoldContext.currentContext!).showSnackBar(
        SnackBar(
          content: Text(
              'Gagal mengaktifkan Pompa 1: Status code ${response.statusCode}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _kontrolpompa2(int pump1Value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final response = await http.post(
      Uri.parse(
          koneksi().baseUrl + 'controlmotor2/${widget.noSeri}/$pump2Value'),
    );
    log(pump1Value.toString());

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final status = jsonResponse['status'];
      final message = jsonResponse['message'];

      if (status == 'success') {
        log('berhasil');
        if (pump2Value == 1) {
          ScaffoldMessenger.of(scaffoldContext.currentContext!).showSnackBar(
            SnackBar(
              content: Text('Pompa 2 diaktifkan: $message'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(scaffoldContext.currentContext!).showSnackBar(
            SnackBar(
              content: Text('Pompa 2 dimatikan: $message'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        log('gagal');
        ScaffoldMessenger.of(scaffoldContext.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Gagal mengaktifkan Pompa 2: $message'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      log('error');
      ScaffoldMessenger.of(scaffoldContext.currentContext!).showSnackBar(
        SnackBar(
          content: Text(
              'Gagal mengaktifkan Pompa 2: Status code ${response.statusCode}'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _fetchSelectedKebun() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final response = await http.get(
      Uri.parse(koneksi().baseUrl +
          'kebun/showidkebun/${widget.kebunId}?token=$token'),
    );
    log('widget.kebunId: ${widget.kebunId}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData.containsKey('kebun')) {
        final kebunData = jsonData['kebun'];
        for (var kebun in kebunData) {
          if (kebun['id'] == int.parse(widget.kebunId)) {
            setState(() {
              selectedKebun = Kebun(
                id: kebun['id'].toString(),
                tanamanNama: kebun['tanaman']['nama'],
                perangkatNoSeri: kebun['perangkat']['no_seri'],
                tanamanFoto: kebun['tanaman']['foto'],
              );
            });
            log(selectedKebun!.tanamanFoto);
            return;
          }
        }
        log('Data kebun dengan ID ${widget.kebunId} tidak ditemukan');
      } else {
        log('Data "kebun" tidak ada dalam respons JSON');
      }
    } else {
      log('Gagal memuat data kebun. Status code: ${response.statusCode}');
    }
  }

  Future<bool> deleteKebun() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse(
              koneksi().baseUrl + 'kebun/hapus/${widget.kebunId}?token=$token'),
        );
        log('Id kebun : ${widget.kebunId}');
        if (response.statusCode == 200) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => SolomonNavigationBar(id: 1),
          ));
          return true;
        } else {
          log('Gagal menghapus kebun. Status code: ${response.statusCode}');
        }
      } catch (error) {
        log('Error during delete: $error');
      }
    } else {
      log('token tidak ada');
    }

    return false;
  }

  Future<void> _fetchDataAlat() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final response = await http.get(
      Uri.parse(koneksi().baseUrl + 'mqtt/${widget.noSeri}?token=$token'),
    );
    log('widget.kebunId: ${widget.noSeri}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final data = jsonResponse['data'];

      if (data != null &&
          data.containsKey('STATUS_MOTOR1') &&
          data.containsKey('STATUS_MOTOR2') &&
          data.containsKey('DHT1Temp') &&
          data.containsKey('DHT1Hum')) {
        if (mounted) {
          setState(() {
            statusMotor1 = data['STATUS_MOTOR1'];
            statusMotor2 = data['STATUS_MOTOR2'];
            dht1Temp = data['DHT1Temp'];
            dht1Hum = data['DHT1Hum'];
          });
        }
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Data tidak tersedia.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        _timer?.cancel();
      }
    } else {
      log('Gagal memuat data alat. Status code: ${response.statusCode}');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSelectedKebun();
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      _fetchDataAlat();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        dispose();
        return true;
      },
      child: Scaffold(
        key: scaffoldContext,
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          toolbarHeight: 80.0,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          title: Text(
            'Detail Kebun',
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: selectedKebun != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedKebun!.tanamanNama,
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => HalamanUbahKebun(
                                    kebunId: selectedKebun!.id),
                              ));
                            },
                            icon: Icon(Icons.edit_note))
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color.fromARGB(255, 232, 238, 236),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: selectedKebun!.tanamanFoto != null
                              ? Image.network(
                                  selectedKebun!.tanamanFoto,
                                  width: 175,
                                  height: 200,
                                )
                              : Text('Tidak Ada Gambar'),
                        ),
                        Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Seri Perangkat: ${selectedKebun!.perangkatNoSeri}',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              'Suhu: ${dht1Temp.toString()} °C',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              'Kelembaban: ${dht1Hum.toString()} %',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              'Status Pompa 1: ${statusMotor1 == 0 ? 'Tidak aktif' : 'Aktif'}',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              'Status Pompa 2: ${statusMotor2 == 0 ? 'Tidak aktif' : 'Aktif'}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 32),
                        Text(
                          'Kontrol Pompa',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Pompa 1',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Switch(
                                    value: isPump1On,
                                    onChanged: (newValue) {
                                      setState(() {
                                        isPump1On = newValue;
                                        pump1Value = isPump1On ? 1 : 0;
                                        _kontrolpompa1(pump1Value!);
                                      });
                                    },
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    isPump1On ? 'ON' : 'OFF',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isPump1On
                                            ? Color.fromARGB(255, 77, 129, 95)
                                            : Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Pompa 2',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Switch(
                                    value: isPump2On,
                                    onChanged: (newValue) {
                                      setState(() {
                                        isPump2On = newValue;
                                        pump2Value = isPump2On ? 1 : 0;
                                        _kontrolpompa2(pump2Value!);
                                      });
                                    },
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    isPump2On ? 'ON' : 'OFF',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isPump2On
                                            ? Color.fromARGB(255, 77, 129, 95)
                                            : Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          child: ElevatedButton(
                            onPressed: () {
                              _showDeleteConfirmationDialog();
                            },
                            child: Text(
                              'Hapus Kebun',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 194, 41, 41),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
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
                ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: scaffoldContext.currentContext!,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus Kebun'),
          content: Text('Apakah Anda yakin ingin menghapus kebun ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final success = await deleteKebun();

                if (success) {
                  ScaffoldMessenger.of(scaffoldContext.currentContext!)
                      .showSnackBar(
                    SnackBar(
                      content: Text('Kebun berhasil dihapus.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(scaffoldContext.currentContext!)
                      .showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus kebun.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}

class Kebun {
  final String id;
  final String tanamanNama;
  final String perangkatNoSeri;
  final String tanamanFoto;

  Kebun({
    required this.id,
    required this.tanamanNama,
    required this.perangkatNoSeri,
    required this.tanamanFoto,
  });
}
