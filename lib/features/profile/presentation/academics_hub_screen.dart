import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class AcademicsHubScreen extends StatelessWidget {
  const AcademicsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Academic Planning Hub',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Academic Management',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildLinkCard(
              context,
              icon: Icons.school_rounded,
              title: 'Programmes List',
              subtitle: 'Track your degree courses and active options',
              route: '/programmes',
            ),
            const SizedBox(height: 16),
            _buildLinkCard(
              context,
              icon: Icons.calendar_today_rounded,
              title: 'Semester Planning Scenarios',
              subtitle: 'Draft different semester configurations and compare',
              route: '/scenarios',
            ),
            const SizedBox(height: 16),
            _buildLinkCard(
              context,
              icon: Icons.alt_route_rounded,
              title: 'Subject Dependencies',
              subtitle: 'Map prerequisites and prevent conflicts',
              route: '/dependencies',
            ),
            const SizedBox(height: 16),
            _buildLinkCard(
              context,
              icon: Icons.grade_rounded,
              title: 'Course Catalog & Plans',
              subtitle: 'Register interest in upcoming courses',
              route: '/courses',
            ),
            const SizedBox(height: 24),
            const Text(
              'Syllabus & Preparation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildLinkCard(
              context,
              icon: Icons.checklist_rounded,
              title: 'Syllabus Topic Tracking',
              subtitle: 'Track completion and your confidence per topic',
              route: '/topics',
            ),
            const SizedBox(height: 16),
            _buildLinkCard(
              context,
              icon: Icons.menu_book_rounded,
              title: 'Exam Preparation',
              subtitle: 'Plan revisions, deadlines, and study hours',
              route: '/exam-prep',
            ),
            const SizedBox(height: 16),
            _buildLinkCard(
              context,
              icon: Icons.bookmark_rounded,
              title: 'Resource Library',
              subtitle: 'Private links, notes, past papers, and study references',
              route: '/resources',
            ),
            const SizedBox(height: 24),
            const Text(
              'Analytics & Graduation Progress',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildLinkCard(
              context,
              icon: Icons.query_stats_rounded,
              title: 'Graduation Estimate',
              subtitle: 'View deterministic credits and semester progress',
              route: '/graduation',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: GlassContainer(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.accentPurple, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
