import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeService themeService;

  const SettingsScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProgressService _progressService = ProgressService();
  final TtsService _ttsService = TtsService();
  String _appVersion = '';

  // Local state for settings
  double _speechRate = 1.0; // Default value is set to 1.0 (maximum speed)
  double _fontSize = 1.0; // Default value

  @override
  void initState() {
    super.initState();
    // Initialize with current values
    _speechRate = widget.themeService.speechRate;
    _fontSize = widget.themeService.fontSize;

    // Initialize TTS service
    _ttsService.initialize();

    // Get app version
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  // Helper method to create section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          // Theme section
          _buildSectionHeader(context, 'Appearance'),
          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  // Dark mode toggle
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Switch between light and dark theme'),
                    value: widget.themeService.isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        widget.themeService.toggleTheme();
                      });
                    },
                    secondary: Icon(
                      widget.themeService.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  // Accent color selector
                  ListTile(
                    title: const Text('Accent Color'),
                    subtitle: const Text('Choose your preferred accent color'),
                    leading: Icon(Icons.color_lens,
                        color: widget.themeService.accentColor),
                    trailing: _buildColorSelector(),
                  ),
                ],
              ),
            ),
          ),

          // Comment out entire Reading & Typing section
          /*
          // Reading & Typing settings
          _buildSectionHeader(context, 'Reading & Typing'),
          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  // Text-to-speech settings commented out
                  // Font size settings commented out
                ],
              ),
            ),
          ),
          */

          // User Data settings
          _buildSectionHeader(context, 'User Data'),
          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Clear History'),
                    subtitle: const Text('Remove all your saved data'),
                    leading:
                        Icon(Icons.restart_alt, color: Colors.red.shade400),
                    onTap: () => _showResetConfirmation(context),
                  ),
                ],
              ),
            ),
          ),

          // App info
          _buildSectionHeader(context, 'About'),
          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  const ListTile(
                    title: Text('Version'),
                    subtitle: Text('1.0.0'),
                    leading: Icon(Icons.info_outline),
                  ),
                  ListTile(
                    title: const Text('About'),
                    subtitle: const Text('Learn more about this app'),
                    leading: const Icon(Icons.info),
                    onTap: () {
                      // Show about dialog
                      showAboutDialog(
                        context: context,
                        applicationName: 'JusType',
                        applicationVersion: _appVersion,
                        applicationIcon: Image.asset(
                          'assets/icons/app_icon.png',
                          width: 32,
                          height: 32,
                        ),
                        applicationLegalese: '© 2025 JusType',
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'An interactive reading and typing application designed to enhance your experience with digital text.',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _colorOption(Colors.blue),
        const SizedBox(width: 8),
        _colorOption(Colors.green),
        const SizedBox(width: 8),
        _colorOption(Colors.purple),
        const SizedBox(width: 8),
        _colorOption(Colors.orange),
      ],
    );
  }

  Widget _colorOption(Color color) {
    final isSelected = widget.themeService.accentColor == color;

    return GestureDetector(
      onTap: () {
        setState(() {
          widget.themeService.setAccentColor(color);
          // Explicitly notify listeners to ensure UI updates
          widget.themeService.notifyListeners();
        });
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)]
              : null,
        ),
      ),
    );
  }

  String _getFontSizeLabel(double value) {
    if (value <= 0.8) return 'S';
    if (value <= 1.0) return 'M';
    if (value <= 1.2) return 'L';
    return 'XL';
  }

  String _getSpeechRateLabel(double rate) {
    if (rate <= 0.25) return 'Slow';
    if (rate <= 0.5) return 'Normal';
    if (rate <= 0.75) return 'Fast';
    return 'Very Fast';
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all your saved data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Reset all progress
              await _progressService.resetAllProgress();
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('History has been cleared'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
