import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyRegisterScreen extends StatefulWidget {
  final String dni;

  const EmergencyRegisterScreen({super.key, required this.dni});

  @override
  State<EmergencyRegisterScreen> createState() => _EmergencyRegisterScreenState();
}

class _EmergencyRegisterScreenState extends State<EmergencyRegisterScreen> {
  String displayName = "";

  final _formKeyEmerg = GlobalKey<FormState>();
  final _emerg1Controller = TextEditingController();
  final _emerg2Controller = TextEditingController();
  String _emergError = "";

  @override
  void initState() {
    super.initState();
    _loadUserName(widget.dni);
  }

  Future<void> _loadUserName(String dni) async {
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

  Future<void> _saveEmergencyNumbers() async {
    if (!_formKeyEmerg.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'emergencia1': _emerg1Controller.text.trim(),
        'emergencia2': _emerg2Controller.text.trim(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Números de emergencia guardados')),
      );

      // Reinicia RootNavigation mostrando la pestaña 0
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/root',
        arguments: {
          'dni': widget.dni,
          'initialIndex': 0,
        },
            (route) => false,
      );
    } catch (e) {
      setState(() => _emergError = "Error al guardar: ${e.toString()}");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
        ),
        title: const Text("Bienvenida"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text("Bienvenido, $displayName",
                  style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKeyEmerg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Números de emergencia",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    controller: _emerg1Controller,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Emergencia 1 (9 dígitos)"),
                    validator: (v) {
                      if (v == null || v.length != 9) return "Debe tener 9 dígitos";
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emerg2Controller,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Emergencia 2 (9 dígitos)"),
                    validator: (v) {
                      if (v == null || v.length != 9) return "Debe tener 9 dígitos";
                      return null;
                    },
                  ),
                  if (_emergError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _emergError,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _saveEmergencyNumbers,
                    child: const Text("Guardar números de emergencia"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
