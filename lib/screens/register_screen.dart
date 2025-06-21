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
  final TextEditingController dniController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();

  bool showPassword = false;
  String errorText = "";

  void togglePasswordVisibility() {
    setState(() {
      showPassword = !showPassword;
    });
  }

  Future<void> register() async {
    final dni = dniController.text.trim();
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final repeatPassword = repeatPasswordController.text;

    if (!_formKey.currentState!.validate()) return;

    if (password != repeatPassword) {
      setState(() => errorText = "Las contraseñas no coinciden");
      return;
    }

    try {
      // Verificar duplicados
      final dniCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('dni', isEqualTo: dni)
          .get();

      final phoneCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('telefono', isEqualTo: phone)
          .get();

      if (dniCheck.docs.isNotEmpty) {
        setState(() => errorText = "DNI ya registrado.");
        return;
      }

      if (phoneCheck.docs.isNotEmpty) {
        setState(() => errorText = "Número de celular ya registrado.");
        return;
      }

      // Crear usuario
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'dni': dni,
        'nombre': name,
        'correo': email,
        'telefono': phone,
        'uid': userCredential.user!.uid,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso')),
      );
      // Limpiar campos
      dniController.clear();
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      passwordController.clear();
      repeatPasswordController.clear();

      // Navegar al home
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

      // Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      setState(() => errorText = e.message ?? "Error de autenticación");
    } catch (e) {
      setState(() => errorText = "Error: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    dniController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
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
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "DNI (8 dígitos)"),
                validator: (value) {
                  if (value == null || value.length != 8) return 'DNI inválido';
                  return null;
                },
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nombre completo"),
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Correo electrónico"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Celular (9 dígitos)"),
                validator: (value) {
                  if (value == null || value.length != 9) return 'Número inválido';
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: const InputDecoration(labelText: "Contraseña"),
                validator: (value) {
                  if (value == null || value.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              TextFormField(
                controller: repeatPasswordController,
                obscureText: !showPassword,
                decoration: const InputDecoration(labelText: "Repetir contraseña"),
                validator: (value) {
                  if (value != passwordController.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              TextButton(
                onPressed: togglePasswordVisibility,
                child: Text(showPassword ? "Ocultar contraseña" : "Mostrar contraseña"),
              ),
              if (errorText.isNotEmpty)
                Text(errorText, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: register,
                child: const Text("Registrarse"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Volver al inicio"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
