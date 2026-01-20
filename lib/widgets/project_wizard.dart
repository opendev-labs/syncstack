import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/gh_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/premium_button.dart';

class ProjectWizard extends StatefulWidget {
  final VoidCallback onProjectCreated;

  const ProjectWizard({super.key, required this.onProjectCreated});

  @override
  State<ProjectWizard> createState() => _ProjectWizardState();
}

class _ProjectWizardState extends State<ProjectWizard> {
  final GHService _ghService = GHService();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _pathController = TextEditingController(text: '/home/cube/syncstack');
  
  int _currentStep = 0;
  String _selectedTemplate = 'Pure HTML';
  bool _isPrivate = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _templates = [
    {'name': 'Pure HTML', 'icon': Icons.html, 'desc': 'Standard HTML5 workspace with semantic markup.'},
    {'name': 'Pure CSS', 'icon': Icons.css, 'desc': 'Design-first workspace with external style.css.'},
    {'name': 'Pure JS', 'icon': Icons.javascript, 'desc': 'Logic-focused workspace with external app.js.'},
    {'name': 'Quantum Combined (Recommended)', 'icon': Icons.auto_awesome_motion, 'desc': 'Ultimate full-stack web workspace: HTML + CSS + JS.'},
    {'name': 'Empty GitHub Repo', 'icon': Icons.horizontal_rule_rounded, 'desc': 'Clean slate with just a README.md.'},
  ];

  Future<void> _createProject() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final desc = _descController.text.trim();

      if (name.isEmpty) {
        throw 'Project name is required';
      }

      final res = await _ghService.createRepo(auth.token!, name, desc, private: _isPrivate);
      
      if (mounted) {
        if (res['success']) {
          final repoPath = '${_pathController.text}/${res['repo']['name']}';
          
          if (_selectedTemplate != 'Empty GitHub Repo') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Repository created! Deploying templates...'), backgroundColor: AppTheme.infoBlue),
            );
            await _ghService.scaffoldRepo(repoPath, _selectedTemplate);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Blank repository established.'), backgroundColor: AppTheme.cyanAccent),
            );
          }
          
          if (mounted) {
             widget.onProjectCreated();
             Navigator.of(context).pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${res['message']}'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.deepBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: const BorderSide(color: AppTheme.cyanAccent, width: 1)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderGlow))),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.cyanAccent),
                  const SizedBox(width: 16),
                  Text('HYPERINTELLIGENT PROJECT WIZARD', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 16, letterSpacing: 2)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 20)),
                ],
              ),
            ),

            // Steps
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.borderGlow))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep == 1)
                    TextButton(onPressed: () => setState(() => _currentStep = 0), child: const Text('BACK', style: TextStyle(color: AppTheme.textGrey)))
                  else
                    const SizedBox(),
                  
                  PremiumButton(
                    onPressed: _isLoading ? null : (_currentStep == 0 ? () => setState(() => _currentStep = 1) : _createProject),
                    isLoading: _isLoading,
                    child: Text(_currentStep == 0 ? 'NEXT: CONFIGURE' : 'ESTABLISH REPOSITORY', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CHOOSE YOUR ARCHITECTURE', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
        const SizedBox(height: 24),
        ..._templates.map((t) => _buildTemplateCard(t)).toList(),
      ],
    ).animate().fadeIn();
  }

  Widget _buildTemplateCard(Map<String, dynamic> t) {
    final isSelected = _selectedTemplate == t['name'];
    return InkWell(
      onTap: () => setState(() => _selectedTemplate = t['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cyanAccent.withOpacity(0.05) : AppTheme.surfaceBlack,
          border: Border.all(color: isSelected ? AppTheme.cyanAccent : AppTheme.borderGlow),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(t['icon'], color: isSelected ? AppTheme.cyanAccent : AppTheme.textGrey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['name'], style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.textGrey)),
                  const SizedBox(height: 4),
                  Text(t['desc'], style: const TextStyle(fontSize: 11, color: AppTheme.textDimmed)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.cyanAccent, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('METADATA & VISIBILITY', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'PROJECT IDENTITY (REPO NAME)', hintText: 'e.g. quantum-app'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'DESCRIPTION (OPTIONAL)', hintText: 'Describe the purpose of this project...'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pathController,
          decoration: InputDecoration(
            labelText: 'LOCAL WORKSPACE ROOT',
            suffixIcon: IconButton(
              icon: const Icon(Icons.folder_open, size: 18),
              onPressed: () {
                // In a real app, use file_picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select directory feature enabled.')),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: _isPrivate,
              onChanged: (v) => setState(() => _isPrivate = v ?? false),
              activeColor: AppTheme.cyanAccent,
              checkColor: Colors.black,
            ),
            const Text('PRIVATE REPOSITORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Private repositories are only visible to you and authorized collaborators.', style: TextStyle(fontSize: 10, color: AppTheme.textDimmed)),
      ],
    ).animate().fadeIn();
  }
}
