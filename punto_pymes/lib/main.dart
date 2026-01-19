import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'service/theme_provider.dart';
import 'theme.dart';
import 'pages/splash_screen.dart';
import 'pages/access_selection_page.dart';
import 'pages/login_page/login_page.dart';
import 'pages/login_page/register_page.dart';
import 'pages/empleado/empleado_page.dart';
import 'service/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await SupabaseService.instance.init();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: lightmode,
          darkTheme: darkmode,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          routes: {
            '/access-selection': (_) => const AccessSelectionPage(),
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/empleado': (_) => const EmpleadoPage(),
          },
        );
      },
    );
  }
}
