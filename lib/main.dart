// Punto de entrada de la app.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'pantallas/inicio.dart';
import 'pantallas/portal_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Conectar la app con nuestro proyecto de Firebase (sabores-sucre).
  //    Las claves están en firebase_options.dart (lo generó flutterfire).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Firebase trae su propio caché; lo apagamos para que la ÚNICA copia
  //    local sea nuestra base SQLite.
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: false);

  runApp(const SaboresSucreApp());
}

class SaboresSucreApp extends StatelessWidget {
  const SaboresSucreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabores de Sucre',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFFB71C1C)),
      // En el navegador se abre el portal para propietarios; en el celular,
      // la app completa (la web no tiene SQLite).
      home: kIsWeb ? const PortalWebPantalla() : const InicioPantalla(),
    );
  }
}
