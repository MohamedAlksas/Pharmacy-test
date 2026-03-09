import 'package:flutter/material.dart';
import 'package:graduation_project/views/LoginView.dart';

const String backgroundImagePath =
    'assets/Gemini_Generated_Image_4jaq2t4jaq2t4jaq.png';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const PharmacyLoginApp());
}

class PharmacyLoginApp extends StatelessWidget {
  const PharmacyLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Loginview();
  }
}
