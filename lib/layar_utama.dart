import 'package:flutter/material.dart';
import 'package:smart_farming/halaman_masuk.dart';

class LayarUtama extends StatelessWidget {
  const LayarUtama({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    SizedBox(height: 40),
                    Text(
                      "Smart Farming",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 24),
                    Container(
                      margin: EdgeInsets.only(right: 70, left: 70),
                      child: Text(
                        "Smart farming adalah pendekatan pertanian dengan teknologi canggih untuk meningkatkan efisiensi dan produktivitas.",
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 140, bottom: 45),
                      child: Image.asset(
                        'assets/images/home_screen.jpg',
                        width: 350,
                        height: 270,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => HalamanMasuk()),
                              (Route<dynamic> route) => false);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Text(
                            'Get Started',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 77, 129, 95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
