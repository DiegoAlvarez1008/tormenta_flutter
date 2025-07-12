import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tormenta_app/resultados_promedio.dart';

class EmergencyRegisterScreen extends StatefulWidget {
  const EmergencyRegisterScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyRegisterScreen> createState() => _EmergencyRegisterScreenState();
}

class _EmergencyRegisterScreenState extends State<EmergencyRegisterScreen> {
  double? temperatura;
  int? bpm;
  int? cantidad;
  int? puntuacionTemp;
  int? puntuacionFC;
  bool datosEnviados = false;

  @override
  void initState() {
    super.initState();
    temperatura = ResultadosPromedio.tempPromedio;
    bpm = ResultadosPromedio.bpmPromedio;
    cantidad = ResultadosPromedio.cantidadDatos;

    if (temperatura != null && bpm != null && cantidad != null && ResultadosPromedio.datosListosParaEnvio == true) {
      puntuacionTemp = calcularPuntuacionTemperatura(temperatura!);
      puntuacionFC = calcularPuntuacionFC(bpm!);
      guardarEnFirestore();
    }
  }

  int calcularPuntuacionTemperatura(double t) {
    if (t >= 40.0) return 30;
    if (t >= 39.3) return 25;
    if (t >= 38.9) return 20;
    if (t >= 38.3) return 15;
    if (t >= 37.8) return 10;
    if (t >= 37.2) return 5;
    return 0;
  }

  int calcularPuntuacionFC(int f) {
    if (f >= 140) return 25;
    if (f >= 130) return 20;
    if (f >= 120) return 15;
    if (f >= 110) return 10;
    if (f >= 90) return 5;
    return 0;
  }

  Future<void> guardarEnFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mediciones')
          .add({
        'timestamp': Timestamp.now(),
        'temperatura_promedio': temperatura,
        'fc_promedio': bpm,
        'cantidad_datos': cantidad,
        'puntuacion_temp': puntuacionTemp,
        'puntuacion_fc': puntuacionFC,
      });

      setState(() {
        datosEnviados = true;
        ResultadosPromedio.datosListosParaEnvio = false;

      });
    } catch (e) {
      print('Error al guardar en Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Resultados Burch-Wartofsky")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Resultados Escala\nBurch-Wartofsky",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 4,
              child: Image.asset(
                "assets/images/tabla_burch.png",
                fit: BoxFit.contain,
                height: 350,
                width: MediaQuery.of(context).size.width * 0.95,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Tabla que relaciona parámetros fisiológicos con una escala de puntajes discreta.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            if (temperatura != null && bpm != null)
              Column(
                children: [
                  Text(
                    "Temperatura promedio: ${temperatura!.toStringAsFixed(1)} °C",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Frecuencia cardiaca promedio: $bpm BPM",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Cantidad de mediciones: $cantidad",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Puntuación de temperatura: $puntuacionTemp",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Puntuación de F.C.: $puntuacionFC",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              )
            else
              const Text(
                "Aún no se ha registrado ninguna medición.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
