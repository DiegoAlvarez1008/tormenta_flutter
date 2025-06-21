import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String displayName = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dni = ModalRoute.of(context)!.settings.arguments as String;
    _loadUserName(dni);
  }

  Future<void> _loadUserName(String dni) async {
    // Buscamos en Firestore el documento donde 'dni' == dni
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('dni', isEqualTo: dni)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final name = query.docs.first['nombre'] as String;
      final parts = name.split(' ');
      if (parts.length >= 4) {
        displayName = "${parts[0]} ${parts[2]}";
      } else if (parts.length >= 2) {
        displayName = "${parts[0]} ${parts[1]}";
      } else {
        displayName = parts[0];
      }
    } else {
      displayName = FirebaseAuth.instance.currentUser?.email ?? "";
    }
    setState(() {});
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bienvenida")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Bienvenido, $displayName",
                style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _logout, child: const Text("Cerrar sesión")),
            ElevatedButton(onPressed: _exitApp, child: const Text("Salir de la app")),
          ],
        ),
      ),
    );
  }
}
