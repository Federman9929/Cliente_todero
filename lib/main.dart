import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';
import 'home_screen.dart';

void main() async {
  // Esta línea es obligatoria. Le dice a Flutter que espere a que el motor
  // gráfico esté listo antes de intentar conectar con los servicios nativos de Apple/Android.
  WidgetsFlutterBinding.ensureInitialized();

  // Aquí es donde ocurre la magia: conecta tu app con el servidor de Google
  await Firebase.initializeApp();

  // Arranca la interfaz gráfica
  runApp(const ToderoClienteApp());
}

class ToderoClienteApp extends StatelessWidget {

  const ToderoClienteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToderoExpress Cliente',
      debugShowCheckedModeBanner: false, // Quita la cinta roja de "DEBUG"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}