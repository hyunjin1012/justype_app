import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/theme_service.dart';
import '../services/progress_service.dart';
import '../services/app_preferences.dart';
import '../widgets/app_surface.dart';
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
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;

    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  // Helper method to create section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: SectionTitle(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildSectionHeader(context, 'Appearance'),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: AppSurface(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
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
          _buildSectionHeader(context, 'Privacy & Data'),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: AppSurface(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  const ListTile(
                    title: Text('Offline Practice'),
                    subtitle: Text(
                      'Library, generated prompts, phrase packs, and progress stay on this device.',
                    ),
                    leading: Icon(Icons.offline_pin),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    title: Text('Microphone'),
                    subtitle: Text(
                      'Voice input is only used when you tap Record. You can always type instead.',
                    ),
                    leading: Icon(Icons.mic),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Clear Practice History'),
                    subtitle: const Text(
                      'Reset stats, achievements, weak drills, and practiced prompts',
                    ),
                    leading:
                        Icon(Icons.restart_alt, color: Colors.red.shade400),
                    onTap: () => _showResetConfirmation(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Replay Onboarding'),
                    subtitle: const Text('Show the intro flow again'),
                    leading: Icon(
                      Icons.slideshow,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: _replayOnboarding,
                  ),
                ],
              ),
            ),
          ),
          _buildSectionHeader(context, 'About'),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: AppSurface(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Version'),
                    subtitle:
                        Text(_appVersion.isEmpty ? 'Loading...' : _appVersion),
                    leading: const Icon(Icons.info_outline),
                  ),
                  ListTile(
                    title: const Text('About'),
                    subtitle: const Text('Learn more about this app'),
                    leading: const Icon(Icons.info),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'JusType',
                        applicationVersion: _appVersion,
                        applicationIcon: Image.asset(
                          'assets/icons/app_icon.png',
                          width: 32,
                          height: 32,
                        ),
                        applicationLegalese: '© 2026 JusType',
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'An offline-first practice app for text precision, listening recall, and conversation phrase practice.',
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
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)]
              : null,
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Practice History'),
        content: const Text(
          'This resets stats, achievements, weak drills, and practiced prompt history. Appearance and onboarding settings will stay the same.',
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
              if (mounted && context.mounted) {
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

  Future<void> _replayOnboarding() async {
    await AppPreferences.resetOnboarding();

    if (!mounted) return;

    GoRouter.of(context).go('/onboarding');
  }
}
