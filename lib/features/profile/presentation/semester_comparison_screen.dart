import 'package:flutter/material.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class SemesterComparisonScreen extends StatelessWidget {
  const SemesterComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Semester Comparison',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Compare academic statistics, study consistency, and GPA progress across semesters.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 20),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Performance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildComparisonRow(
                    metric: 'Attendance',
                    sem1: '74.2%',
                    sem2: '81.5%',
                    trend: '+7.3%',
                    isPositive: true,
                  ),
                  const Divider(color: Colors.white12),
                  _buildComparisonRow(
                    metric: 'SGPA',
                    sem1: '8.21',
                    sem2: '8.65',
                    trend: '+0.44',
                    isPositive: true,
                  ),
                  const Divider(color: Colors.white12),
                  _buildComparisonRow(
                    metric: 'Study Time',
                    sem1: '124 hrs',
                    sem2: '142 hrs',
                    trend: '+18 hrs',
                    isPositive: true,
                  ),
                  const Divider(color: Colors.white12),
                  _buildComparisonRow(
                    metric: 'Missed Classes',
                    sem1: '14 classes',
                    sem2: '9 classes',
                    trend: '-5 classes',
                    isPositive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow({
    required String metric,
    required String sem1,
    required String sem2,
    required String trend,
    required bool isPositive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              metric,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            sem1,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(width: 24),
          Text(
            sem2,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPositive
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              trend,
              style: TextStyle(
                color: isPositive ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
