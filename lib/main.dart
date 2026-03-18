import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unblockr/screens/splash/splash_screen.dart';

void main() {
  runApp(const UnblockrApp());
}

class UnblockrApp extends StatelessWidget {
  const UnblockrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unblockr',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
      ),

      home: const SplashScreen(),
    );
  }
}