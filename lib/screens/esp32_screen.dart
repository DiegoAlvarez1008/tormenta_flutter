import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';
import 'dart:convert';

class ESP32Screen extends StatefulWidget {
  const ESP32Screen({Key? key}) : super(key: key);

  @override
  State<ESP32Screen> createState() => _ESP32ScreenState();
}

class _ESP32ScreenState extends State<ESP32Screen> {
  final _ble = FlutterReactiveBle();
  late DiscoveredDevice _device;
  late QualifiedCharacteristic _rxChar;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<List<int>>? _dataSub;

  String temperatura = '';
  String frecuenciaCardiaca = '';
  String estado = 'Buscando dispositivo...';

  final serviceUuid = Uuid.parse("0000180d-0000-1000-8000-00805f9b34fb");
  final characteristicUuid = Uuid.parse("00002a37-0000-1000-8000-00805f9b34fb");

  @override
  void initState() {
    super.initState();
    _startScan();
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

    await Future.delayed(const Duration(seconds: 2)); // esperar conexión

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
            final valor = utf8.decode(data); // decodificación correcta UTF-8
            final partes = valor.split("|").map((e) => e.trim()).toList();

            if (partes.length == 2) {
              // Extracción robusta
              final tempRaw = partes[0].replaceAll(RegExp(r'[^0-9.]'), '').trim();
              final fcRaw = partes[1].replaceAll(RegExp(r'[^0-9]'), '').trim();

              setState(() {
                temperatura = '$tempRaw °C';
                frecuenciaCardiaca = '$fcRaw BPM';
                estado = 'Recibiendo datos';
              });
            } else {
              setState(() {
                estado = 'Formato incorrecto de datos';
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
    return Scaffold(
      appBar: AppBar(title: const Text("Datos del ESP32")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Temperatura: $temperatura", style: const TextStyle(fontSize: 20)),
            Text("Frecuencia Cardíaca: $frecuenciaCardiaca", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            Text("Estado: $estado", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
