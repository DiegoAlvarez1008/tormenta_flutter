import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController dniController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  String errorText = "";

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final dni = dniController.text.trim();
    final password = passwordController.text;

    try {
      // Busca UID por DNI
      final q = await FirebaseFirestore.instance
          .collection('users')
          .where('dni', isEqualTo: dni)
          .limit(1)
          .get();
      if (q.docs.isEmpty) {
        setState(() => errorText = "DNI no registrado");
        return;
      }
      final uid = q.docs.first['uid'] as String;
      final email = q.docs.first['correo'] as String;
      // Autentica con email+password
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      // Guarda uid si pidió recordar
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('savedUid', uid);
      }
      // Navega a root
      Navigator.pushReplacementNamed(
        context,
        '/root',
        arguments: {'dni': dni, 'initialIndex': 0},
      );
    } on FirebaseAuthException catch (e) {
      setState(() => errorText = e.message ?? "Error de autenticación");
    }
  }

  @override
  void dispose() {
    dniController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Iniciar Sesión")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(shrinkWrap: true, children: [
            TextFormField(
              controller: dniController,
              decoration: const InputDecoration(labelText: "DNI (8 dígitos)"),
              keyboardType: TextInputType.number,
              validator: (v) =>
              v != null && v.length == 8 ? null : "DNI inválido",
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Contraseña"),
              obscureText: true,
              validator: (v) =>
              v != null && v.length >= 6 ? null : "Mínimo 6 caracteres",
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: rememberMe,
              onChanged: (v) => setState(() => rememberMe = v ?? false),
              title: const Text("Recordarme en este dispositivo"),
            ),
            if (errorText.isNotEmpty)
              Text(errorText, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text("Entrar")),
          ]),
        ),
      ),
    );
  }
}
