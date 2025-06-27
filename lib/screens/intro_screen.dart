import 'package:flutter/material.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Información sobre Hipertiroidismo"),
          centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
          "¿Qué es el Hipertiroidismo?",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Image.asset('assets/images/hipertiroidismo1.png'),
        const SizedBox(height: 12),
        const Text(
          "El hipertiroidismo es una afección en la que la glándula tiroides produce demasiada hormona tiroidea. Esto puede acelerar el metabolismo del cuerpo, causando pérdida de peso, ritmo cardíaco rápido o irregular, sudoración, nerviosismo y otros síntomas.",
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 28),
        const Text(
          "¿Qué es la Crisis Tiroidea o Tormenta Tiroidea?",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Image.asset('assets/images/tormenta_tiroidea.png'),
        const SizedBox(height: 12),
        const Text(
          "La crisis tiroidea es una complicación poco frecuente pero potencialmente mortal del hipertiroidismo. Se caracteriza por un empeoramiento repentino y severo de los síntomas del hipertiroidismo.",
          style: TextStyle(fontSize: 16),
        ),

        const SizedBox(height: 28),
        const Text(
          "Síntomas comunes del Hipertiroidismo",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Image.asset('assets/images/sintomas.png'),
        const SizedBox(height: 12),
        const Text(
            "- Pérdida de peso\n- Aceleración del ritmo cardíaco\n- Sudoración excesiva\n- Nerviosismo o irritabilidad\n- Temblores en las manos\n- Dificultad para dormir",
            style: TextStyle(fontSize: 16),
            ),

      const SizedBox(height: 28),
      const Text(
        "Importancia de la Detección Temprana",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      const Text(
        "Detectar a tiempo el hipertiroidismo puede prevenir complicaciones graves, incluyendo la crisis tiroidea. El seguimiento regular de los signos vitales y síntomas es fundamental para asegurar una buena calidad de vida.",
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 32),
      const Center(
        child: Text(
          "Esta app está diseñada para ayudarte a monitorear tu salud y actuar a tiempo.\n¡Tu bienestar es lo más importante!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: 40),
      ],
    ),
    ),
    );
  }
}
