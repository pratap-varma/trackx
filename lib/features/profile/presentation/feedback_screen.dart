import 'package:flutter/material.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Bug Report';
  bool _shareDiagnostics = true;

  @override
  Widget build(BuildContext context) {
    final dropdownBg = context.isDark ? const Color(0xFF131A2B) : Colors.white;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Send Feedback',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor),
          ),
          iconTheme: IconThemeData(color: context.textColor),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'Have an issue or a feature request? Let us know! Your academic notes and credentials are never shared.',
              style: TextStyle(color: context.subtextColor, fontSize: 12),
            ),
            const SizedBox(height: 20),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: TextStyle(
                      color: context.subtextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    dropdownColor: dropdownBg,
                    value: _category,
                    style: TextStyle(color: context.textColor, fontSize: 14),
                    isExpanded: true,
                    items:
                        [
                          'Bug Report',
                          'Feature Request',
                          'UI Feedback',
                          'Performance Issue',
                        ].map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _category = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _titleController,
                    labelText: 'Title',
                    hintText: 'Brief summary of feedback',
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _descController,
                    labelText: 'Description',
                    hintText: 'Describe details or steps to reproduce',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text(
                      'Include Diagnostics',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Includes non-sensitive metadata (app version 1.0.0, schema version 1). No passwords, location, or notes are shared.',
                      style: TextStyle(color: context.mutedTextColor, fontSize: 10),
                    ),
                    value: _shareDiagnostics,
                    activeColor: AppTheme.accentPurple,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _shareDiagnostics = val);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  GlassPrimaryButton(
                    text: 'Submit Feedback',
                    onPressed: () {
                      final title = _titleController.text.trim();
                      final desc = _descController.text.trim();

                      if (title.isNotEmpty && desc.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Feedback submitted successfully! Thank you.',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
