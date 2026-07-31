import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/programmes/data/programme_repository.dart';
import 'package:trackx/features/programmes/domain/programme_model.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class ProgrammeManageScreen extends ConsumerStatefulWidget {
  const ProgrammeManageScreen({super.key});

  @override
  ConsumerState<ProgrammeManageScreen> createState() => _ProgrammeManageScreenState();
}

class _ProgrammeManageScreenState extends ConsumerState<ProgrammeManageScreen> {
  final _nameController = TextEditingController();
  final _degreeController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();
  final _semsController = TextEditingController();
  final _creditsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _degreeController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    _semsController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  void _showAddProgrammeDialog() {
    _nameController.clear();
    _degreeController.clear();
    _branchController.clear();
    _yearController.text = DateTime.now().year.toString();
    _semsController.text = '8';
    _creditsController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassContainer(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add Programme',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _nameController,
                    labelText: 'Programme Name (e.g. B.Tech Computer Science)',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _degreeController,
                    labelText: 'Degree Type (e.g. B.Tech, B.Sc)',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _branchController,
                    labelText: 'Branch / Specialization',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _yearController,
                    labelText: 'Joining Year',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _semsController,
                    labelText: 'Total Semesters',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _creditsController,
                    labelText: 'Total Credits (Optional)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final name = _nameController.text.trim();
                          final degree = _degreeController.text.trim();
                          final branch = _branchController.text.trim();
                          final joiningYear = int.tryParse(_yearController.text.trim()) ?? DateTime.now().year;
                          final totalSemesters = int.tryParse(_semsController.text.trim()) ?? 8;
                          final totalCredits = double.tryParse(_creditsController.text.trim());

                          if (name.isNotEmpty) {
                            await ref.read(programmeRepositoryProvider.notifier).createProgramme(
                                  name: name,
                                  degreeType: degree.isNotEmpty ? degree : null,
                                  branch: branch.isNotEmpty ? branch : null,
                                  joiningYear: joiningYear,
                                  totalSemesters: totalSemesters,
                                  totalCredits: totalCredits,
                                  gradingSystemId: 'GPA_10',
                                );
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(programmeRepositoryProvider);
    final active = ref.watch(activeProgrammeProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Manage Programmes',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _showAddProgrammeDialog,
            ),
          ],
        ),
        body: list.isEmpty
            ? Center(
                child: GlassContainer(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school, color: Colors.white60, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'No Programmes Registered',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add a programme manually to map your curricula.',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showAddProgrammeDialog,
                        child: const Text('Add Programme'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final prog = list[index];
                  final isActive = prog.id == active?.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GlassContainer(
                      borderColor: isActive ? AppTheme.accentPurple : Colors.white10,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  prog.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentPurple.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.accentPurple, width: 0.5),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(color: AppTheme.accentPurple, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (prog.branch != null)
                            Text('Branch: ${prog.branch}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('Joining Year: ${prog.joiningYear} • Total Semesters: ${prog.totalSemesters}',
                              style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          if (prog.totalCredits != null)
                            Text('Total Credits Required: ${prog.totalCredits}',
                                style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          Text('Status: ${prog.status}',
                              style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isActive && prog.status != 'Archived') ...[
                                TextButton(
                                  onPressed: () => ref.read(programmeRepositoryProvider.notifier).setActiveProgramme(prog.id),
                                  child: const Text('Set Active', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (prog.status != 'Archived') ...[
                                TextButton(
                                  onPressed: () => ref.read(programmeRepositoryProvider.notifier).archiveProgramme(prog.id),
                                  child: const Text('Archive', style: TextStyle(color: Colors.amber, fontSize: 12)),
                                ),
                              ] else ...[
                                TextButton(
                                  onPressed: () => ref.read(programmeRepositoryProvider.notifier).restoreProgramme(prog.id),
                                  child: const Text('Restore', style: TextStyle(color: Colors.green, fontSize: 12)),
                                ),
                              ],
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
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
                                              const Text('Delete Programme?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                              const SizedBox(height: 12),
                                              const Text('Are you sure you want to delete this programme? Previous records linked to other modules will not be erased, but the configuration maps will be deleted.',
                                                  style: TextStyle(color: Colors.white60, fontSize: 11)),
                                              const SizedBox(height: 20),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      ref.read(programmeRepositoryProvider.notifier).deleteProgramme(prog.id);
                                                      Navigator.pop(context);
                                                    },
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                                    child: const Text('Delete'),
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
                },
              ),
      ),
    );
  }
}
