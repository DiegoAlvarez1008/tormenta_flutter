import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';
import 'dart:convert';
import 'package:tormenta_app/screens/ble_state_controller.dart';
import 'package:tormenta_app/resultados_promedio.dart';

class ESP32Screen extends StatefulWidget {
  const ESP32Screen({Key? key}) : super(key: key);

  @override
  State<ESP32Screen> createState() => _ESP32ScreenState();
}

List<double> temps = [];
List<int> bpms = [];
List<int> spo2s = [];

class _ESP32ScreenState extends State<ESP32Screen> {
  final _ble = FlutterReactiveBle();
  late DiscoveredDevice _device;
  late QualifiedCharacteristic _rxChar;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<List<int>>? _dataSub;

  String temperatura = '';
  String frecuenciaCardiaca = '';
  String saturacionOxigeno = '';
  String estado = 'Buscando dispositivo...';


  final serviceUuid = Uuid.parse("0000180d-0000-1000-8000-00805f9b34fb");
  final characteristicUuid = Uuid.parse("00002a37-0000-1000-8000-00805f9b34fb");

  @override
  void initState() {
    super.initState();
    BLEStateController().bleActivo = false;
    _mostrarDialogoAlInicio();
    _startScan();
  }

  void _mostrarDialogoAlInicio() {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            title: const Text("Aviso importante"),
            content: const Text(
              "El sistema se activará al presionar el botón físico en STORMI.\n\nUna vez iniciado, no podrás navegar por la app hasta detener la toma de datos.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    });
  }

  void _startScan() {
    _scanSub = _ble.scanForDevices(withServices: [serviceUuid]).listen((device) async {
      if (device.name == "ESP32-MAX30102") {
        _device = device;
        _scanSub?.cancel();
        await _connectToDevice();
      }
    }, onError: (err) {
      setState(() => estado = 'Error de escaneo: $err');
    });
  }

  Future<void> _connectToDevice() async {
    setState(() => estado = 'Conectando al ESP32...');

    _ble.connectToDevice(id: _device.id).listen((_) {}, onError: (e) {
      setState(() => estado = "Error de conexión: $e");
    });

    await Future.delayed(const Duration(seconds: 2));

    final services = await _ble.discoverServices(_device.id);
    bool charEncontrada = false;

    for (var service in services) {
      for (var c in service.characteristics) {
        if (c.characteristicId == characteristicUuid) {
          _rxChar = QualifiedCharacteristic(
            serviceId: service.serviceId,
            characteristicId: c.characteristicId,
            deviceId: _device.id,
          );

          _dataSub = _ble.subscribeToCharacteristic(_rxChar).listen((data) {
            final valor = utf8.decode(data).trim();

            if (valor == "FIN") {
              final avgTemp = temps.isNotEmpty
                  ? temps.reduce((a, b) => a + b) / temps.length
                  : 0.0;
              final avgBpm = bpms.isNotEmpty
                  ? bpms.reduce((a, b) => a + b) / bpms.length
                  : 0.0;

              ResultadosPromedio.tempPromedio = avgTemp;
              ResultadosPromedio.bpmPromedio = avgBpm.round();
              ResultadosPromedio.cantidadDatos = temps.length;

              setState(() {
                estado = 'La toma de datos finalizó. Puedes volver a navegar.';
                BLEStateController().bleActivo = false;
              });

              temps.clear();
              bpms.clear();
              return; // salir
            }

            final partes = valor.split("|").map((e) => e.trim()).toList();
            if (partes.length == 3) {
              final tempRaw = partes[0].replaceAll(RegExp(r'[^0-9.]'), '');
              final fcRaw = partes[1].replaceAll(RegExp(r'[^0-9]'), '');
              final spo2Raw = partes[2].replaceAll(RegExp(r'[^0-9]'), '');

              final tempParsed = double.tryParse(tempRaw) ?? 0.0;
              final bpmParsed = int.tryParse(fcRaw) ?? 0;
              final spo2Parsed = int.tryParse(spo2Raw) ?? 0;

              // Guardar datos para promediar
              temps.add(tempParsed);
              bpms.add(bpmParsed);
              spo2s.add(spo2Parsed);

              setState(() {
                temperatura = '$tempParsed °C';
                frecuenciaCardiaca = '$bpmParsed BPM';
                estado = 'Recibiendo datos';
                saturacionOxigeno = '$spo2Parsed %';
                BLEStateController().bleActivo = true;
              });
            }
          });

          charEncontrada = true;
          break;
        }
      }
      if (charEncontrada) break;
    }

    if (!charEncontrada) {
      setState(() => estado = 'Característica no encontrada.');
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _dataSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (BLEStateController().bleActivo = true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No puedes salir mientras STORMI está en funcionamiento."),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Datos del ESP32")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Temperatura: $temperatura", style: const TextStyle(fontSize: 20)),
              Text("Frecuencia Cardíaca: $frecuenciaCardiaca", style: const TextStyle(fontSize: 20)),
              Text("Saturación de Oxígeno: $saturacionOxigeno", style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              Text("Estado: $estado", style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
