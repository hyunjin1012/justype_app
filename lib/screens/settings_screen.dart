import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeService themeService;

  const SettingsScreen({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme section
          _buildSectionHeader(context, 'Appearance'),
          Card(
            elevation: 2,
            child: Column(
              children: [
                // Dark mode toggle
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme throughout the app'),
                  value: themeService.isDarkMode,
                  onChanged: (value) {
                    themeService.toggleTheme();
                  },
                  secondary: Icon(
                    themeService.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                ),

                // Theme color picker
                ListTile(
                  title: const Text('Theme Color'),
                  subtitle: const Text('Choose your preferred accent color'),
                  leading: const Icon(Icons.color_lens),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: themeService.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  onTap: () => _showColorPicker(context, themeService),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Practice settings
          _buildSectionHeader(context, 'Practice Settings'),
          Card(
            elevation: 2,
            child: Column(
              children: [
                // Text-to-speech settings
                ListTile(
                  title: const Text('Speech Rate'),
                  subtitle: const Text('Adjust the speed of text-to-speech'),
                  leading: const Icon(Icons.speed),
                  trailing: SizedBox(
                    width: 150,
                    child: Slider(
                      value: themeService.speechRate,
                      min: 0.25,
                      max: 1.0,
                      divisions: 3,
                      label: _getSpeechRateLabel(themeService.speechRate),
                      onChanged: (value) {
                        themeService.setSpeechRate(value);
                      },
                    ),
                  ),
                ),

                // Font size settings
                ListTile(
                  title: const Text('Font Size'),
                  subtitle: const Text('Adjust text size for reading'),
                  leading: const Icon(Icons.format_size),
                  trailing: SizedBox(
                    width: 150,
                    child: Slider(
                      value: themeService.fontSize,
                      min: 0.8,
                      max: 1.4,
                      divisions: 3,
                      label: _getFontSizeLabel(themeService.fontSize),
                      onChanged: (value) {
                        themeService.setFontSize(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account settings
          _buildSectionHeader(context, 'Account'),
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Reset Progress'),
                  subtitle: const Text('Clear all your practice history'),
                  leading: const Icon(Icons.restart_alt),
                  onTap: () => _showResetConfirmation(context),
                ),
                ListTile(
                  title: const Text('About'),
                  subtitle: const Text('Learn more about this app'),
                  leading: const Icon(Icons.info),
                  onTap: () {
                    // Show about dialog
                    showAboutDialog(
                      context: context,
                      applicationName: 'Language Practice',
                      applicationVersion: '1.0.0',
                      applicationIcon: const FlutterLogo(size: 32),
                      applicationLegalese: '© 2023 Language Practice',
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'A language practice app to help improve reading and listening skills through interactive exercises.',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          themeService.toggleTheme();
          // Notify the app to rebuild with the new theme
          (context as Element).markNeedsBuild();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, ThemeService themeService) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme Color'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((color) {
            return InkWell(
              onTap: () {
                themeService.setAccentColor(color);
                Navigator.of(context).pop();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: themeService.accentColor == color
                        ? Colors.white
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: themeService.accentColor == color
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text(
          'Are you sure you want to reset all your progress? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Reset progress logic would go here
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progress has been reset'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  String _getSpeechRateLabel(double rate) {
    if (rate <= 0.25) return 'Slow';
    if (rate <= 0.5) return 'Normal';
    if (rate <= 0.75) return 'Fast';
    return 'Very Fast';
  }

  String _getFontSizeLabel(double size) {
    if (size <= 0.8) return 'Small';
    if (size <= 1.0) return 'Normal';
    if (size <= 1.2) return 'Large';
    return 'Extra Large';
  }
}
