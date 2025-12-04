import 'package:flutter/material.dart';

final ThemeData lightmode = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFFD92344),
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD92344)),
  scaffoldBackgroundColor: const Color(0xFFF7F7F8),
);

final ThemeData darkmode = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFFD92344),
);
