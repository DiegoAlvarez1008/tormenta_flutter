import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final dniCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final repeatCtrl = TextEditingController();
  String errorText = "";

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    if (passCtrl.text != repeatCtrl.text) {
      setState(() => errorText = "Contraseñas no coinciden");
      return;
    }
    final dni = dniCtrl.text.trim();
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    // Verifica duplicados
    final d = await FirebaseFirestore.instance
        .collection('users')
        .where('dni', isEqualTo: dni)
        .limit(1)
        .get();
    if (d.docs.isNotEmpty) {
      setState(() => errorText = "DNI ya registrado");
      return;
    }

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: passCtrl.text);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'dni': dni,
        'nombre': name,
        'correo': email,
        'telefono': phone,
        'uid': cred.user!.uid,
        'createdAt': Timestamp.now(),
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Registro exitoso')));
      // Cierra sesión automática
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    } on FirebaseAuthException catch (e) {
      setState(() => errorText = e.message ?? "Error registro");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(shrinkWrap: true, children: [
            TextFormField(
              controller: dniCtrl,
              decoration: const InputDecoration(labelText: "DNI (8 dígitos)"),
              keyboardType: TextInputType.number,
              validator: (v) =>
              v != null && v.length == 8 ? null : "DNI inválido",
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre completo"),
              validator: (v) => v!.isNotEmpty ? null : "Campo obligatorio",
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailCtrl,
              decoration:
              const InputDecoration(labelText: "Correo electrónico"),
              validator: (v) =>
              v != null && v.contains('@') ? null : "Correo inválido",
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: "Celular (9 dígitos)"),
              keyboardType: TextInputType.phone,
              validator: (v) =>
              v != null && v.length == 9 ? null : "Número inválido",
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: "Contraseña"),
              obscureText: true,
              validator: (v) =>
              v != null && v.length >= 6 ? null : "Mínimo 6 caracteres",
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: repeatCtrl,
              decoration:
              const InputDecoration(labelText: "Repetir contraseña"),
              obscureText: true,
              validator: (v) =>
              v == passCtrl.text ? null : "No coinciden",
            ),
            if (errorText.isNotEmpty)
              Text(errorText, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: const Text("Registrar")),
          ]),
        ),
      ),
    );
  }
}
