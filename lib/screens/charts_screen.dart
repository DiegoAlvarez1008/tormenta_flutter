import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    DateTime from;
    if (_selectedRange == 'today') {
      from = DateTime(now.year, now.month, now.day);
    } else {
      from = now.subtract(Duration(days: int.parse(_selectedRange)));
    }

    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mediciones')
        .where('timestamp', isGreaterThanOrEqualTo: from)
        .orderBy('timestamp')
        .get();

    setState(() {
      _measurements = query.docs;
      _loading = false;
    });
  }

  List<BarChartGroupData> _buildStemBars({
    required bool isTemperature,
  }) {
    return List.generate(_measurements.length, (i) {
      final doc = _measurements[i];
      final y = isTemperature
          ? (doc['temperatura_promedio'] as num).toDouble()
          : (doc['fc_promedio'] as num).toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: y,
            fromY: 0,
            width: 4,
            color: isTemperature ? Colors.blue : Colors.red,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    });
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
                        value: 'today', child: Text("Hoy")),
                    DropdownMenuItem(
                        value: '7', child: Text("Últimos 7 días")),
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
              Expanded(
                child: ListView(
                  children: [
                    const Text("Temperatura promedio",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          barGroups:
                          _buildStemBars(isTemperature: true),
                          borderData: FlBorderData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 &&
                                      idx < _measurements.length) {
                                    final ts =
                                    (_measurements[idx]['timestamp']
                                    as Timestamp)
                                        .toDate();
                                    return Text(
                                      DateFormat('dd/MM HH:mm')
                                          .format(ts),
                                      style: const TextStyle(
                                          fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Frecuencia cardiaca promedio",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          barGroups:
                          _buildStemBars(isTemperature: false),
                          borderData: FlBorderData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 &&
                                      idx < _measurements.length) {
                                    final ts =
                                    (_measurements[idx]['timestamp']
                                    as Timestamp)
                                        .toDate();
                                    return Text(
                                      DateFormat('dd/MM HH:mm')
                                          .format(ts),
                                      style: const TextStyle(
                                          fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
