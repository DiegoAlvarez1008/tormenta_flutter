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
  final dniController = TextEditingController();
  final passwordController = TextEditingController();
  bool showPassword = false;
  bool rememberMe = false; // Se declara el flag
  String errorText = "";

  Future<void> login() async {
    final dni = dniController.text.trim();
    final password = passwordController.text.trim();

    if (!_formKey.currentState!.validate()) return;

    try {
      // 1️⃣ Buscamos el correo real asociado al DNI en Firestore:
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('dni', isEqualTo: dni)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => errorText = "No existe un usuario con ese DNI");
        return;
      }

      final email = query.docs.first['correo'] as String;

      // 2️⃣ Autenticamos con FirebaseAuth usando ese correo:
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Guardar preferencia "Recordarme"
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('savedUid', FirebaseAuth.instance.currentUser!.uid);
      }

      // 3️⃣ Si todo ok, navegamos a Welcome
      Navigator.pushReplacementNamed(context, '/root', arguments: dni);
    } on FirebaseAuthException catch (e) {
      setState(() => errorText = e.message ?? "Error de login");
    } catch (e) {
      setState(() => errorText = "Ocurrió un error inesperado");
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
      appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
          ),
      title: const Text("Iniciar sesión"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: dniController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "DNI"),
              validator: (value) =>
              value == null || value.length != 8 ? 'DNI inválido' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: passwordController,
              obscureText: !showPassword,
              decoration: InputDecoration(
                labelText: "Contraseña",
                suffixIcon: IconButton(
                  icon: Icon(showPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Contraseña requerida' : null,
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              title: const Text("Recordarme en este dispositivo"),
              value: rememberMe,
              onChanged: (v) => setState(() => rememberMe = v!),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (errorText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(errorText,
                    style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: const Text("Entrar")),

          ]),
        ),
      ),
    );
  }
}
