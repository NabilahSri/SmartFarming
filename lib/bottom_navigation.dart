import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:smart_farming/halaman_artikel.dart';
import 'package:smart_farming/halaman_kebun.dart';
import 'package:smart_farming/halaman_profil.dart';
import 'package:smart_farming/halaman_utama.dart';

class SolomonNavigationBar extends StatefulWidget {
  int id;
  SolomonNavigationBar({super.key, required this.id});

  @override
  State<SolomonNavigationBar> createState() => _SolomonNavigationBarState();
}

class _SolomonNavigationBarState extends State<SolomonNavigationBar> {
  var index = 0;
  @override
  void initState() {
    super.initState();
    setState(() {
      index = widget.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      bottomNavigationBar: SalomonBottomBar(
        margin: EdgeInsets.all(18),
        items: [
          SalomonBottomBarItem(
            icon: Icon(Icons.home),
            title: Text("Utama"),
            selectedColor: Color.fromARGB(255, 77, 129, 95),
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.map_rounded),
            title: Text("Kebun"),
            selectedColor: Color.fromARGB(255, 77, 129, 95),
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.article),
            title: Text("Artikel"),
            selectedColor: Color.fromARGB(255, 77, 129, 95),
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.people),
            title: Text("Profil"),
            selectedColor: Color.fromARGB(255, 77, 129, 95),
          ),
        ],
        currentIndex: index,
        onTap: (selectedIndex) {
          setState(() => index = selectedIndex);
        },
      ),
      body: Container(
        color: Colors.white,
        child: getSelectedWidget(index: index),
      ),
    );
  }

  Widget getSelectedWidget({required int index}) {
    Widget widget;
    switch (index) {
      case 0:
        widget = const HalamanUtama(
          title: 'Smart Farming',
        );
        break;
      case 1:
        widget = const HalamanKebun();
        break;
      case 2:
        widget = const HalamanArtikel();
        break;
      case 3:
        widget = const HalamanProfil();
        break;
      default:
        widget = const HalamanUtama(
          title: 'Smart Farming',
        );
        break;
    }
    return widget;
  }
}
