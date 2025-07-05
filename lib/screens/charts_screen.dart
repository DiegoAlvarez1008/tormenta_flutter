import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  List<QueryDocumentSnapshot> _measurements = [];
  String _selectedRange = '7'; // Default: last 7 days
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMeasurements();
  }

  Future<void> _fetchMeasurements() async {
    setState(() {
      _loading = true;
    });

    final now = DateTime.now();
    final from = now.subtract(Duration(days: int.parse(_selectedRange)));

    final query = await FirebaseFirestore.instance
        .collection('measurements')
        .where('timestamp', isGreaterThanOrEqualTo: from)
        .orderBy('timestamp')
        .get();

    setState(() {
      _measurements = query.docs;
      _loading = false;
    });
  }

  List<FlSpot> _buildTemperatureSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _measurements.length; i++) {
      final temp = _measurements[i]['temperature'] as double;
      spots.add(FlSpot(i.toDouble(), temp));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gráficos de Medición")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text("Rango: "),
                DropdownButton<String>(
                  value: _selectedRange,
                  items: const [
                    DropdownMenuItem(
                        value: '7', child: Text("Últimos 7 días")),
                    DropdownMenuItem(
                        value: '30', child: Text("Últimos 30 días")),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedRange = val!;
                    });
                    _fetchMeasurements();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_measurements.isEmpty)
              const Text("No hay datos disponibles para este rango.")
            else
              SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    borderData: FlBorderData(show: true),
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 &&
                                index < _measurements.length) {
                              final ts = (_measurements[index]
                              ['timestamp'] as Timestamp)
                                  .toDate();
                              return Text(
                                DateFormat('MM/dd')
                                    .format(ts),
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _buildTemperatureSpots(),
                        isCurved: true,
                        color: Colors.blue,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text("Datos recientes:",
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _measurements.length,
                itemBuilder: (context, index) {
                  final m = _measurements[index];
                  final ts =
                  (m['timestamp'] as Timestamp).toDate();
                  return ListTile(
                    title: Text(
                        "Temp: ${m['temperature']} °C, BPM: ${m['bpm']}"),
                    subtitle: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(ts)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
