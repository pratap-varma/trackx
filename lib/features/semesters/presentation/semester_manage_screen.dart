import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';

class SemesterManageScreen extends ConsumerStatefulWidget {
  const SemesterManageScreen({super.key});

  @override
  ConsumerState<SemesterManageScreen> createState() =>
      _SemesterManageScreenState();
}

class _SemesterManageScreenState extends ConsumerState<SemesterManageScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddSemesterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassContainer(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'New Semester',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                GlassTextField(
                  controller: _nameController,
                  labelText: 'Semester Name',
                  hintText: 'e.g. Fall 2026',
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        if (name.isNotEmpty) {
                          await ref
                              .read(semesterRepositoryProvider.notifier)
                              .createSemester(name, null, DateTime.now(), null);
                          _nameController.clear();
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(semesterRepositoryProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Manage Semesters',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            GlassPrimaryButton(
              text: 'Add New Semester',
              onPressed: _showAddSemesterDialog,
            ),
            const SizedBox(height: 24),
            if (list.isEmpty)
              const Center(
                child: Text(
                  'No Semesters created yet.',
                  style: TextStyle(color: Colors.white60),
                ),
              )
            else
              ...list.map((sem) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GlassContainer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sem.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (sem.isActive)
                                const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                const Text(
                                  'ARCHIVED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (!sem.isActive)
                              IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.greenAccent,
                                ),
                                onPressed: () {
                                  ref
                                      .read(semesterRepositoryProvider.notifier)
                                      .setActiveSemester(sem.id);
                                },
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.transparent,
                                      content: GlassContainer(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Confirm Deletion',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Are you sure you want to delete ${sem.name}?',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color: Colors.white60,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.redAccent,
                                                      ),
                                                  onPressed: () async {
                                                    await ref
                                                        .read(
                                                          semesterRepositoryProvider
                                                              .notifier,
                                                        )
                                                        .deleteSemester(sem.id);
                                                    if (context.mounted) {
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
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
