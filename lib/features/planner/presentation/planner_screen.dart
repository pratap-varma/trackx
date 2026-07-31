import 'package:flutter/material.dart';
import 'package:trackx/shared/widgets/glass_container.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planner & Tasks',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            'Keep track of assignments and labs',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Add Task Mock card
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add Lab Record/Assignment...',
                    style: TextStyle(color: Colors.white.withOpacity(0.4)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white10,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Task lists
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final tasks = [
                {
                  'title': 'Socket Programming Report',
                  'sub': 'Computer Networks • Due in 2 days',
                  'completed': false,
                },
                {
                  'title': 'Red-Black Trees Lab Record',
                  'sub': 'Data Structures Lab • Due tomorrow',
                  'completed': true,
                },
                {
                  'title': 'Digital Counter Design Viva',
                  'sub': 'Digital Electronics • Due in 5 days',
                  'completed': false,
                },
              ];
              final t = tasks[index];
              final done = t['completed'] as bool;

              return GlassContainer(
                child: Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? Colors.greenAccent : Colors.white38,
                      size: 22,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['title'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(
                            t['sub'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
