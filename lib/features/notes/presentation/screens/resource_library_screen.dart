import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/notes/data/resource_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class ResourceLibraryScreen extends ConsumerStatefulWidget {
  const ResourceLibraryScreen({super.key});

  @override
  ConsumerState<ResourceLibraryScreen> createState() =>
      _ResourceLibraryScreenState();
}

class _ResourceLibraryScreenState extends ConsumerState<ResourceLibraryScreen> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedType = 'Links'; // 'Links', 'Notes', 'Files'

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showAddResourceDialog() {
    _titleController.clear();
    _urlController.clear();
    _descController.clear();
    _selectedType = 'Links';

    showDialog(
      context: context,
      builder: (context) {
        final dropdownBg = context.isDark ? const Color(0xFF131A2B) : Colors.white;
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassContainer(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bookmark Resource',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _titleController,
                    labelText: 'Title',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: dropdownBg,
                    initialValue: _selectedType,
                    style: TextStyle(color: context.textColor),
                    items: const [
                      DropdownMenuItem(value: 'Links', child: Text('Links')),
                      DropdownMenuItem(value: 'Notes', child: Text('Notes')),
                      DropdownMenuItem(value: 'Files', child: Text('Files')),
                    ],
                    onChanged: (val) => _selectedType = val ?? 'Links',
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _urlController,
                    labelText: 'URL / Path',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _descController,
                    labelText: 'Notes',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: context.subtextColor),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final title = _titleController.text.trim();
                          final url = _urlController.text.trim();
                          final desc = _descController.text.trim();

                          if (title.isNotEmpty) {
                            ref
                                .read(resourceRepositoryProvider.notifier)
                                .createResource(
                                  title: title,
                                  type: _selectedType == 'Links'
                                      ? 'Link'
                                      : (_selectedType == 'Notes'
                                            ? 'Note'
                                            : 'PDF'),
                                  url: url.isNotEmpty ? url : null,
                                  description: desc.isNotEmpty ? desc : null,
                                  tags: [],
                                );
                            Navigator.pop(context);
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
    final list = ref.watch(resourceRepositoryProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Resource Library',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor),
          ),
          iconTheme: IconThemeData(color: context.textColor),
          actions: [
            IconButton(
              icon: Icon(Icons.bookmark_add, color: context.textColor),
              onPressed: _showAddResourceDialog,
            ),
          ],
        ),
        body: list.isEmpty
            ? Center(
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark,
                        color: context.mutedTextColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Resource Library Empty',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep private links, past papers, notes, or references here.',
                        style: TextStyle(color: context.subtextColor, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final res = list[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  res.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: context.isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  res.type,
                                  style: const TextStyle(
                                    color: AppTheme.accentPurple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (res.url != null)
                            SelectableText(
                              res.url!,
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 11,
                              ),
                            ),
                          if (res.description != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              res.description!,
                              style: TextStyle(
                                color: context.subtextColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                onPressed: () => ref
                                    .read(resourceRepositoryProvider.notifier)
                                    .deleteResource(res.id),
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
