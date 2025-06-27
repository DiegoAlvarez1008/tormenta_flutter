import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importa aquí tus pantallas específicas
import 'intro_screen.dart';
import 'emergency_register.dart';
import 'esp32_screen.dart';
import 'charts_screen.dart';
import 'profile_screen.dart';

class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkEmergencyNumbers();
  }

  Future<void> _checkEmergencyNumbers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final hasNumbers = (doc.data()?['emergency1'] != null && doc.data()?['emergency2'] != null);

    _screens = [
      hasNumbers ? const IntroScreen() : const EmergencyRegisterScreen(),
      const EmergencyRegisterScreen(),
      const Esp32Screen(),
      const GraphsScreen(),
      const ProfileScreen(),
    ];

    setState(() => _isLoading = false);
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
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Números'),
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: 'ESP32'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Gráficos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Yo'),
        ],
      ),
    );
  }
}
