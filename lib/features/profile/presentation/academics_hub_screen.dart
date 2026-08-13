import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';

class AcademicsHubScreen extends StatelessWidget {
  const AcademicsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Academic Hub',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            _sectionHeader('ACADEMIC MANAGEMENT'),
            const SizedBox(height: 10),
            _hubCard(
              context,
              icon: Icons.school_rounded,
              color: const Color(0xFF5B5FEF),
              title: 'Programmes',
              subtitle: 'Track your degree courses and active options',
              badge: null,
              route: '/programmes',
            ),
            _hubCard(
              context,
              icon: Icons.calendar_today_rounded,
              color: const Color(0xFF7BD0FF),
              title: 'Semester Scenarios',
              subtitle: 'Draft and compare different semester configurations',
              badge: null,
              route: '/scenarios',
            ),
            _hubCard(
              context,
              icon: Icons.alt_route_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Subject Dependencies',
              subtitle: 'Map prerequisites and prevent conflicts',
              badge: 'NEW',
              route: '/dependencies',
            ),
            _hubCard(
              context,
              icon: Icons.grade_rounded,
              color: const Color(0xFF10B981),
              title: 'Course Catalog',
              subtitle: 'Register interest in upcoming courses',
              badge: null,
              route: '/courses',
            ),

            const SizedBox(height: 24),
            _sectionHeader('SYLLABUS & PREPARATION'),
            const SizedBox(height: 10),
            _hubCard(
              context,
              icon: Icons.checklist_rounded,
              color: const Color(0xFF8151EB),
              title: 'Topic Tracking',
              subtitle: 'Track completion and confidence per topic',
              badge: null,
              route: '/topics',
            ),
            _hubCard(
              context,
              icon: Icons.menu_book_rounded,
              color: const Color(0xFFEF4444),
              title: 'Exam Preparation',
              subtitle: 'Plan revisions, deadlines, and study hours',
              badge: null,
              route: '/exam-prep',
            ),
            _hubCard(
              context,
              icon: Icons.bookmark_rounded,
              color: const Color(0xFF7BD0FF),
              title: 'Resource Library',
              subtitle: 'Links, notes, past papers, and study references',
              badge: null,
              route: '/resources',
            ),

            const SizedBox(height: 24),
            _sectionHeader('ANALYTICS & PROGRESS'),
            const SizedBox(height: 10),
            _hubCard(
              context,
              icon: Icons.query_stats_rounded,
              color: const Color(0xFF10B981),
              title: 'Graduation Estimate',
              subtitle: 'View credits and semester completion progress',
              badge: null,
              route: '/graduation',
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white30,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  static Widget _hubCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String? badge,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => context.push(route),
        child: GlassContainer(
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B5FEF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: Color(0xFFC0C1FF),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.2), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
