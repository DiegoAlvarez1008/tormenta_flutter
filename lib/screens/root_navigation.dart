import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tormenta_app/screens/ble_state_controller.dart';
import 'intro_screen.dart';
import 'emergency_register.dart';
import 'esp32_screen.dart';
import 'charts_screen.dart';
import 'profile_screen.dart';

class RootNavigation extends StatefulWidget {
  const RootNavigation({Key? key}) : super(key: key);

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  bool _isLoading = true;
  String _dni = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Leer DNI desde los argumentos de Navigator
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _dni = args != null ? (args['dni'] as String? ?? '') : '';
    _initScreens();
  }

  Future<void> _initScreens() async {
    // Consultar Firestore si el usuario ya guardó números de emergencia
    final user = FirebaseAuth.instance.currentUser;
    bool hasNumbers = false;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      hasNumbers = data != null &&
          data['emergencyPhone1'] != null &&
          data['emergencyPhone2'] != null;
    }

    // Crear la lista de pantallas, inyectando _dni solo donde se necesita
    _screens = [
      IntroScreen(dni: _dni),
      EmergencyRegisterScreen(),
      const ESP32Screen(),
      const ChartsScreen(),
      const ProfileScreen(),
    ];

    // Si no hay números de emergencia, forzamos que abra la segunda pestaña
    final initialIndex = hasNumbers ? 0 : 1;

    setState(() {
      _currentIndex = initialIndex;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (BLEStateController().bleActivo) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("No puedes navegar mientras STORMI está activo."),
                duration: Duration(seconds: 2),
              ),
            );
            return; // Ignora taps
          }
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.table_chart), label: 'Test'),
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: 'ESP32'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Gráficos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Yo'),
        ],
      ),
    );
  }
}
