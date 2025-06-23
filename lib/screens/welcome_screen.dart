import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';


// Para BLE
// import 'package:flutter_blue/flutter_blue.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String displayName = "";

  // Formulario emergencia
  final _formKeyEmerg = GlobalKey<FormState>();
  final _emerg1Controller = TextEditingController();
  final _emerg2Controller = TextEditingController();
  String _emergError = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dni = ModalRoute.of(context)!.settings.arguments as String;
    _loadUserName(dni);
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
      }, SetOptions(merge:true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Números de emergencia guardados')),
      );
    } catch (e) {
      setState(() => _emergError = "Error al guardar: ${e.toString()}");
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('savedUid');
    Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  Future<void> _onConnectBluetoothPressed() async {
    // EJEMPLO PSEUDO-CÓDIGO BLE usando flutter_blue:

    // final ble = FlutterBlue.instance;
    // var state = await ble.state.first;
    // if (state != BluetoothState.on) {
    //   showDialog(
    //     context: context,
    //     builder: (_) => AlertDialog(
    //       title: const Text("Bluetooth desactivado"),
    //       content: const Text(
    //           "Esta función requiere que tengas el Bluetooth encendido."),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.pop(context),
    //           child: const Text("OK"),
    //         )
    //       ],
    //     ),
    //   );
    //   return;
    // }
    // // Si está activo, iniciar escaneo
    // ble.scan(timeout: const Duration(seconds: 4)).listen((scanResult) {
    //   if (scanResult.device.name == "ESP32MiDispositivo") {
    //     ble.stopScan();
    //     scanResult.device.connect();
    //     // Luego suscribirse a caracteristicas para leer datos
    //   }
    // });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Aquí iniciaremos la conexión Bluetooth…")),
    );
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
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  ElevatedButton(onPressed: _onConnectBluetoothPressed, child: const Text("Conectar al dispositivo ESP32")) ,
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _logout, child: const Text("Cerrar sesión")),
                  ElevatedButton(onPressed: _exitApp, child: const Text("Salir de la app")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
