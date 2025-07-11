import 'package:flutter/material.dart';
import 'package:tormenta_app/resultados_promedio.dart';

class EmergencyRegisterScreen extends StatelessWidget {
  const EmergencyRegisterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = ResultadosPromedio.tempPromedio;
    final bpm = ResultadosPromedio.bpmPromedio;
    final cantidad = ResultadosPromedio.cantidadDatos;

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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 4,
              child: Image.asset(
                "assets/images/tabla_burch.png",
                fit: BoxFit.contain,
                height: 350, // Puedes ajustar esto
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
            if (t != null && bpm != null)
              Column(
                children: [
                  Text(
                    "Temperatura promedio: ${t.toStringAsFixed(1)} °C",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Frecuencia cardiaca promedio: $bpm BPM",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Cantidad de mediciones: $cantidad",
                    textAlign: TextAlign.center,
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
