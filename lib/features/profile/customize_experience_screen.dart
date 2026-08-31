import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/theme_provider.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeMode = Provider.of<ThemeProvider>(context, listen: false).themeMode;
    if (themeMode == ThemeMode.light) {
      _selectedTheme = 'Light';
    } else if (themeMode == ThemeMode.dark) {
      _selectedTheme = 'Dark';
    } else {
      _selectedTheme = 'System Default';
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _compactView = prefs.getBool('compact_view') ?? false;
      _showAnimations = prefs.getBool('show_animations') ?? true;
      _accessibilityMode = prefs.getBool('accessibility_mode') ?? false;
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('compact_view', _compactView);
    await prefs.setBool('show_animations', _showAnimations);
    await prefs.setBool('accessibility_mode', _accessibilityMode);
    await prefs.setString('language', _language);
    
    if (!mounted) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    if (_selectedTheme == 'Light') {
      themeProvider.setThemeMode(ThemeMode.light);
    } else if (_selectedTheme == 'Dark') {
      themeProvider.setThemeMode(ThemeMode.dark);
    } else {
      themeProvider.setThemeMode(ThemeMode.system);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).cardColor, size: 20),
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
        title: Text('Customize My Experience'),
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
                gradient: AppTheme.getHeroGradient(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
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
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Appearance Section
            _buildSectionTitle('Appearance'),
            SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                _buildDropdownRow(
                  icon: Icons.brightness_6_outlined,
                  label: 'Theme',
                  value: _selectedTheme,
                  items: ['Light', 'Dark', 'System Default'],
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
            SizedBox(height: 24),

            // Accessibility Section
            _buildSectionTitle('Accessibility'),
            SizedBox(height: 12),
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
                  items: ['English', 'Tamil', 'Hindi', 'Spanish'],
                  onChanged: (v) => setState(() => _language = v!),
                ),
              ],
            ),
            SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _savePreferences,
              child: Text('Save Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45))),
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
          SizedBox(width: 14),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
