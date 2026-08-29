import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';

class CustomizeExperienceScreen extends StatefulWidget {
  const CustomizeExperienceScreen({super.key});

  @override
  State<CustomizeExperienceScreen> createState() => _CustomizeExperienceScreenState();
}

class _CustomizeExperienceScreenState extends State<CustomizeExperienceScreen> {
  String _selectedTheme = 'Light';
  bool _compactView = false;
  bool _showAnimations = true;
  bool _accessibilityMode = false;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('theme') ?? 'Light';
      _compactView = prefs.getBool('compact_view') ?? false;
      _showAnimations = prefs.getBool('show_animations') ?? true;
      _accessibilityMode = prefs.getBool('accessibility_mode') ?? false;
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _selectedTheme);
    await prefs.setBool('compact_view', _compactView);
    await prefs.setBool('show_animations', _showAnimations);
    await prefs.setBool('accessibility_mode', _accessibilityMode);
    await prefs.setString('language', _language);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Preferences saved!'),
          ],
        ),
        backgroundColor: const Color(0xFF1DBF73),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize My Experience'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.palette_outlined, color: AppTheme.primary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Make it yours',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Customize how WorkConnect looks and feels.',
                          style: TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Appearance Section
            _buildSectionTitle('Appearance'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                _buildDropdownRow(
                  icon: Icons.brightness_6_outlined,
                  label: 'Theme',
                  value: _selectedTheme,
                  items: const ['Light', 'Dark', 'System Default'],
                  onChanged: (v) => setState(() => _selectedTheme = v!),
                ),
                const Divider(height: 1, indent: 52),
                _buildSwitchRow(
                  icon: Icons.view_compact_outlined,
                  label: 'Compact View',
                  subtitle: 'Show more content on screen',
                  value: _compactView,
                  onChanged: (v) => setState(() => _compactView = v),
                ),
                const Divider(height: 1, indent: 52),
                _buildSwitchRow(
                  icon: Icons.animation_outlined,
                  label: 'Show Animations',
                  subtitle: 'Smooth transitions and effects',
                  value: _showAnimations,
                  onChanged: (v) => setState(() => _showAnimations = v),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Accessibility Section
            _buildSectionTitle('Accessibility'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                _buildSwitchRow(
                  icon: Icons.accessibility_new_outlined,
                  label: 'Accessibility Mode',
                  subtitle: 'Larger text and high-contrast colors',
                  value: _accessibilityMode,
                  onChanged: (v) => setState(() => _accessibilityMode = v),
                ),
                const Divider(height: 1, indent: 52),
                _buildDropdownRow(
                  icon: Icons.language_outlined,
                  label: 'Language',
                  value: _language,
                  items: const ['English', 'Tamil', 'Hindi', 'Spanish'],
                  onChanged: (v) => setState(() => _language = v!),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _savePreferences,
              child: const Text('Save Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppTheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppTheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
