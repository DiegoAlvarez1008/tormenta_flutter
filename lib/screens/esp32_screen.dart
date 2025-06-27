import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Esp32Screen extends StatefulWidget {
  const Esp32Screen({super.key});

  @override
  State<Esp32Screen> createState() => _Esp32ScreenState();
}

class _Esp32ScreenState extends State<Esp32Screen> {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  String _status = "Desconectado";
  String _receivedData = "";

  bool _isConnecting = false;

  Future<void> _connectToESP32() async {
    setState(() {
      _isConnecting = true;
      _status = "Buscando ESP32...";
    });

    // Asegúrate que Bluetooth está encendido
    final isOn = await FlutterBluePlus.isOn;
    if (!isOn) {
      setState(() {
        _status = "Bluetooth desactivado. Por favor, actívalo.";
        _isConnecting = false;
      });
      return;
    }

    // Escanear dispositivos
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    // Escuchar resultados
    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.name == "ESP32-MAX30102") {
          FlutterBluePlus.stopScan();

          setState(() {
            _status = "Conectando a ${r.device.name}...";
          });

          await r.device.connect();
          _device = r.device;

          // Obtener servicios
          List<BluetoothService> services = await _device!.discoverServices();
          for (var service in services) {
            for (var c in service.characteristics) {
              if (c.uuid.toString().substring(4,8) == "2a37") {
                _characteristic = c;

                await c.setNotifyValue(true);
                c.value.listen((value) {
                  final data = String.fromCharCodes(value);
                  setState(() {
                    _receivedData = data;
                  });
                });

                setState(() {
                  _status = "Conectado a ESP32";
                  _isConnecting = false;
                });
                return;
              }
            }
          }

          setState(() {
            _status = "No se encontró la característica esperada.";
            _isConnecting = false;
          });
          return;
        }
      }

      setState(() {
        _status = "ESP32 no encontrado.";
        _isConnecting = false;
      });
    });
  }

  Future<void> _disconnect() async {
    if (_device != null) {
      await _device!.disconnect();
      setState(() {
        _status = "Desconectado";
        _receivedData = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Conexión ESP32")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Estado: $_status",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isConnecting ? null : _connectToESP32,
              child: const Text("Conectarse al ESP32"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _disconnect,
              child: const Text("Desconectar"),
            ),
            const SizedBox(height: 30),
            const Text("Datos recibidos:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _receivedData.isEmpty ? "Aún no hay datos." : _receivedData,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
