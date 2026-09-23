import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const NarcoXApp());
}

class NarcoXApp extends StatelessWidget {
  const NarcoXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NarcoX',

      theme: ThemeData(
        useMaterial3: true,
      ),

      home: const LoginScreen(),
    );
  }
}