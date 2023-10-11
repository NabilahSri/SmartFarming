import 'package:flutter/material.dart';
import 'package:smart_farming/layar_utama.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 77, 129, 95)),
          useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: LayarUtama(),
    );
  }
}
