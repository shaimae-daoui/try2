import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/supporter_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maestro - Fan Sync App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Colors.green[700],
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      // Route initiale
      initialRoute: '/login',
      // Définition des routes
      routes: {
        '/login': (context) => LoginScreen(),
        '/supporter': (context) => UserScreen(),
        '/admin': (context) => AdminScreen(),
        '/profile': (context) => ProfileScreen(),
      },
      home: LoginScreen(),
    );
  }
}