import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Asegúrate de tener esto en pubspec.yaml
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final dniController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;
  bool showPassword = false;
  String errorText = "";

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final dni = dniController.text.trim();

      // 🔍 Buscar el correo por DNI en Firestore (ajusta la colección según tu estructura)
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('dni', isEqualTo: dni)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => errorText = "DNI no encontrado");
        return;
      }

      final email = snapshot.docs.first.get('correo');

      // ✅ Autenticación con el correo encontrado
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: passwordController.text.trim(),
      );

      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('savedUid', userCredential.user!.uid);
      }

      Navigator.pushReplacementNamed(context, '/root');
    } on FirebaseAuthException catch (e) {
      setState(() => errorText = e.message ?? "Error de autenticación");
    } catch (e) {
      setState(() => errorText = "Error inesperado: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Iniciar Sesión")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: dniController,
                decoration: const InputDecoration(labelText: "DNI"),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.length < 7 ? "DNI inválido" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  suffixIcon: IconButton(
                    icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => showPassword = !showPassword),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text("Recordarme"),
                value: rememberMe,
                onChanged: (v) => setState(() => rememberMe = v ?? false),
              ),
              if (errorText.isNotEmpty)
                Text(errorText, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: const Text("Iniciar Sesión"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
