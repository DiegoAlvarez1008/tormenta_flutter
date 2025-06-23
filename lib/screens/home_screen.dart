import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
// Nuevo método para manejar el flujo de "login"
  Future<void> _handleLogin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString('savedUid');

    if (savedUid != null) {
      // Si hay sesión recordada, buscamos el DNI en Firestore
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: savedUid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final dni = query.docs.first['dni'] as String;
        // Vamos directo a WelcomeScreen con el DNI recuperado
        Navigator.pushReplacementNamed(context, '/welcome', arguments: dni);
        return;
      } else {
        // Si no encontramos el documento, limpiamos la preferencia
        await prefs.remove('savedUid');
      }
    }

    // Si no hay sesión guardada o falló la búsqueda, abrimos LoginScreen
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Monitor de Crisis Tiroidea",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text("Registrarse"),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _handleLogin(context);
                },
                child: const Text("Iniciar sesión"),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: ()  => SystemNavigator.pop(),
                child: const Text("Salir de la aplicación"),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}