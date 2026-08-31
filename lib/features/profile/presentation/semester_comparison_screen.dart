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
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: context.textColor,
              size: 18,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Semester Comparison',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.textColor,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // Header labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Metric',
                      style: TextStyle(
                        color: context.mutedTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _semLabel('SEM 1', const Color(0xFF7BD0FF)),
                  const SizedBox(width: 8),
                  _semLabel('SEM 2', const Color(0xFF5B5FEF)),
                  const SizedBox(width: 8),
                  _semLabel('Δ', context.mutedTextColor),
                ],
              ),
            ),

            // Section: Performance
            _sectionHeader(context, 'OVERALL PERFORMANCE'),
            _comparisonCard(
              context,
              icon: Icons.how_to_reg_outlined,
              iconColor: const Color(0xFF10B981),
              metric: 'Attendance',
              sem1: '74.2%',
              sem2: '81.5%',
              trend: '+7.3%',
              isPositive: true,
            ),
            _comparisonCard(
              context,
              icon: Icons.grade_outlined,
              iconColor: const Color(0xFF5B5FEF),
              metric: 'SGPA',
              sem1: '8.21',
              sem2: '8.65',
              trend: '+0.44',
              isPositive: true,
            ),
            _comparisonCard(
              context,
              icon: Icons.workspace_premium_outlined,
              iconColor: const Color(0xFFF59E0B),
              metric: 'CGPA',
              sem1: '8.21',
              sem2: '8.43',
              trend: '+0.22',
              isPositive: true,
            ),

            const SizedBox(height: 20),
            _sectionHeader(context, 'CONSISTENCY & EFFORT'),
            _comparisonCard(
              context,
              icon: Icons.timer_outlined,
              iconColor: const Color(0xFF7BD0FF),
              metric: 'Study Time',
              sem1: '124 hrs',
              sem2: '142 hrs',
              trend: '+18 hrs',
              isPositive: true,
            ),
            _comparisonCard(
              context,
              icon: Icons.assignment_turned_in_outlined,
              iconColor: const Color(0xFF8151EB),
              metric: 'Tasks Done',
              sem1: '88%',
              sem2: '94%',
              trend: '+6%',
              isPositive: true,
            ),
            _comparisonCard(
              context,
              icon: Icons.dangerous_outlined,
              iconColor: const Color(0xFFEF4444),
              metric: 'Bunks Left',
              sem1: '4',
              sem2: '7',
              trend: '+3',
              isPositive: true,
            ),

            const SizedBox(height: 24),

            // Summary insight
            GlassContainer(
              borderRadius: 18,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B5FEF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFC0C1FF),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Insight',
                          style: TextStyle(
                            color: Color(0xFFC0C1FF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Your Semester 2 shows a strong upward trend — attendance improved by 7.3% and SGPA grew by 0.44 points. Keep up the momentum!',
                          style: TextStyle(
                            color: context.subtextColor,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
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

  static Widget _semLabel(String text, Color color) {
    return SizedBox(
      width: 54,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: context.mutedTextColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static Widget _comparisonCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String metric,
    required String sem1,
    required String sem2,
    required String trend,
    required bool isPositive,
  }) {
    final trendColor = isPositive
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                metric,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              width: 54,
              child: Text(
                sem1,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.mutedTextColor, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 54,
              child: Text(
                sem2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trend,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: trendColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
