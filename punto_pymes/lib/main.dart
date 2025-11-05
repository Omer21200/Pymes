import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page/login_page.dart';
import 'splash_screen/splash_screen.dart';
import 'test_screen.dart';
import 'access_selection/access_selection_page.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://rcflamgbcjdwdtdwzkrb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjZmxhbWdiY2pkd2R0ZHd6a3JiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzNDgzMDQsImV4cCI6MjA3NzkyNDMwNH0.-QFnA_A1rdMIu9MAJXhf47sGKhZxnXfl_nsaX8WZzj4',
  );

  runApp(const MyApp());
}

// Get a reference to your Supabase client
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mi App con Splash',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Pantalla inicial
      home: const SplashScreen(),
      routes: {
        '/login': (context) => LoginPage(selectedInstitution: ''),
        '/test': (context) => const TestScreen(),
        '/access-selection': (context) => const AccessSelectionPage(),
      },
    );
  }
}
