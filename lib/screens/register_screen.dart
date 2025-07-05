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
  final dniController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPasswordController = TextEditingController();
  bool showPassword = false;
  String errorText = "";

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    if (passwordController.text != repeatPasswordController.text) {
      setState(() => errorText = "Las contraseñas no coinciden");
      return;
    }

    try {
      final dniCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('dni', isEqualTo: dniController.text.trim())
          .get();

      final phoneCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('telefono', isEqualTo: phoneController.text.trim())
          .get();

      if (dniCheck.docs.isNotEmpty) {
        setState(() => errorText = "DNI ya registrado");
        return;
      }
      if (phoneCheck.docs.isNotEmpty) {
        setState(() => errorText = "Número ya registrado");
        return;
      }

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'dni': dniController.text.trim(),
        'nombre': nameController.text.trim(),
        'correo': emailController.text.trim(),
        'telefono': phoneController.text.trim(),
        'uid': userCredential.user!.uid,
        'createdAt': Timestamp.now(),
      });

      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    } on FirebaseAuthException catch (e) {
      setState(() => errorText = e.message ?? "Error de autenticación");
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
          child: ListView(
            children: [
              TextFormField(
                controller: dniController,
                decoration: const InputDecoration(labelText: "DNI (8 dígitos)"),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.length != 8 ? "DNI inválido" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nombre completo"),
                validator: (v) => v == null || v.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Correo electrónico"),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? "Correo inválido" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Teléfono (9 dígitos)"),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.length != 9 ? "Número inválido" : null,
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
                validator: (v) => v == null || v.length < 6 ? "Mínimo 6 caracteres" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: repeatPasswordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: "Repetir contraseña",
                  suffixIcon: IconButton(
                    icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => showPassword = !showPassword),
                  ),
                ),
                validator: (v) => v != passwordController.text ? "Las contraseñas no coinciden" : null,
              ),
              const SizedBox(height: 12),
              if (errorText.isNotEmpty)
                Text(errorText, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: register,
                child: const Text("Registrarse"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
