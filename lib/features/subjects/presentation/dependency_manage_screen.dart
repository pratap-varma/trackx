import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/data/dependency_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';

class DependencyManageScreen extends ConsumerStatefulWidget {
  const DependencyManageScreen({super.key});

  @override
  ConsumerState<DependencyManageScreen> createState() =>
      _DependencyManageScreenState();
}

class _DependencyManageScreenState
    extends ConsumerState<DependencyManageScreen> {
  String? _selectedSubjectId;
  String? _selectedReqSubjectId;
  String _selectedType =
      'Prerequisite'; // 'Prerequisite', 'Corequisite', 'Recommended Background'

  void _addDependency() async {
    if (_selectedSubjectId == null || _selectedReqSubjectId == null) {
      _showMsg('Please select both subjects.');
      return;
    }

    final notifier = ref.read(dependencyRepositoryProvider.notifier);
    final error = await notifier.addDependency(
      subjectId: _selectedSubjectId!,
      requiredSubjectId: _selectedReqSubjectId!,
      type: _selectedType,
    );

    if (error != null) {
      _showMsg(error);
    } else {
      _showMsg('Dependency mapped successfully.');
      setState(() {
        _selectedReqSubjectId = null;
      });
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref
        .watch(subjectRepositoryProvider)
        .where((s) => s.status != 'Archived')
        .toList();
    final dependencies = ref.watch(dependencyRepositoryProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Subject Dependencies',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Warning Notice Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Subject dependencies are personal planning information.\nConfirm official requirements with your college.',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form to Add Dependency
            const Text(
              'Add Subject Dependency Link',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Name',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.purple.shade900,
                    initialValue: _selectedSubjectId,
                    hint: const Text(
                      'Select target subject',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: subjects.map((sub) {
                      return DropdownMenuItem(
                        value: sub.id,
                        child: Text(sub.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSubjectId = val;
                        // Avoid selecting same subject as prerequisite
                        if (_selectedReqSubjectId == val) {
                          _selectedReqSubjectId = null;
                        }
                      });
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Requires/Depends On',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.purple.shade900,
                    initialValue: _selectedReqSubjectId,
                    hint: const Text(
                      'Select prerequisite subject',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: subjects
                        .where((sub) => sub.id != _selectedSubjectId)
                        .map((sub) {
                          return DropdownMenuItem(
                            value: sub.id,
                            child: Text(sub.name),
                          );
                        })
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedReqSubjectId = val;
                      });
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dependency Type',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.purple.shade900,
                    initialValue: _selectedType,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: 'Prerequisite',
                        child: Text('Prerequisite'),
                      ),
                      DropdownMenuItem(
                        value: 'Corequisite',
                        child: Text('Corequisite'),
                      ),
                      DropdownMenuItem(
                        value: 'Recommended Background',
                        child: Text('Recommended Background'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedType = val ?? 'Prerequisite';
                      });
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addDependency,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text('Add Dependency'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Dependencies List
            const Text(
              'Active Mapped Dependencies',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            dependencies.isEmpty
                ? const Center(
                    child: Text(
                      'No dependencies configured yet.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dependencies.length,
                    itemBuilder: (context, index) {
                      final dep = dependencies[index];
                      final sourceSub = subjects.firstWhere(
                        (s) => s.id == dep.subjectId,
                        orElse: () => Subject(
                          id: '',
                          userId: '',
                          semesterId: '',
                          name: 'Deleted Subject',
                          facultyName: '',
                          colorValue: 0,
                          type: 'Theory',
                          targetAttendance: 75,
                          presentClasses: 0,
                          absentClasses: 0,
                          status: 'Active',
                          expectedDifficulty: 'Not Set',
                          createdAt: 0,
                          updatedAt: 0,
                        ),
                      );
                      final reqSub = subjects.firstWhere(
                        (s) => s.id == dep.requiredSubjectId,
                        orElse: () => Subject(
                          id: '',
                          userId: '',
                          semesterId: '',
                          name: 'Deleted Subject',
                          facultyName: '',
                          colorValue: 0,
                          type: 'Theory',
                          targetAttendance: 75,
                          presentClasses: 0,
                          absentClasses: 0,
                          status: 'Active',
                          expectedDifficulty: 'Not Set',
                          createdAt: 0,
                          updatedAt: 0,
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${sourceSub.name} (${sourceSub.code ?? "No Code"})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Requires: ${reqSub.name} [${dep.type}]',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  ref
                                      .read(
                                        dependencyRepositoryProvider.notifier,
                                      )
                                      .removeDependency(dep.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
