import 'package:flutter/material.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';

class ReconciliationScreen extends StatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  State<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends State<ReconciliationScreen> {
  final List<Map<String, dynamic>> _discrepancies = [
    {
      'subject': 'DBMS',
      'date': '2026-07-15',
      'local': 'Present',
      'official': 'Absent',
      'resolved': false,
    },
    {
      'subject': 'Mathematics',
      'date': '2026-07-16',
      'local': 'Absent',
      'official': 'Present',
      'resolved': false,
    },
  ];

  void _resolveRow(int index, String resolution) {
    setState(() {
      _discrepancies[index]['resolved'] = true;
      _discrepancies[index]['local'] = resolution;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Resolved DBMS discrepancy to $resolution.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Reconcile Attendance',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Review differences between your self-reported logs and official university imports.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 20),
            if (_discrepancies.every((d) => d['resolved']))
              const Center(
                child: Text(
                  'All logs are fully synchronized and reconciled!',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 14),
                ),
              )
            else
              ...List.generate(_discrepancies.length, (idx) {
                final item = _discrepancies[idx];
                if (item['resolved']) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['subject']} - ${item['date']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Local: ${item['local']}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Official: ${item['official']}',
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GlassPrimaryButton(
                                text: 'Keep Local',
                                onPressed: () =>
                                    _resolveRow(idx, item['local']),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GlassPrimaryButton(
                                text: 'Use Official',
                                onPressed: () =>
                                    _resolveRow(idx, item['official']),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
