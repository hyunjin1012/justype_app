import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/progress_service.dart';
import '../services/app_preferences.dart';
import '../services/purchase_service.dart';
import '../services/saved_prompt_service.dart';
import '../widgets/app_surface.dart';
import '../widgets/plus_purchase_sheet.dart';
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
          _buildSectionHeader(context, 'JusType Plus'),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Consumer2<PurchaseService, SavedPromptService>(
              builder: (context, purchaseService, savedPromptService, child) {
                return AppSurface(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          purchaseService.isPlusUnlocked
                              ? 'JusType Plus Active'
                              : 'Unlock JusType Plus',
                        ),
                        subtitle: Text(
                          purchaseService.isPlusUnlocked
                              ? 'Custom prompts, review queue, and goals are unlocked'
                              : purchaseService.plusPrice.isEmpty
                                  ? 'One-time upgrade for custom practice'
                                  : 'One-time upgrade • ${purchaseService.plusPrice}',
                        ),
                        leading: Icon(
                          Icons.workspace_premium,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        trailing: purchaseService.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                purchaseService.isPlusUnlocked
                                    ? Icons.check_circle
                                    : Icons.chevron_right,
                              ),
                        onTap: _showPlusSheet,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Daily Goal'),
                        subtitle: Text(
                          purchaseService.isPlusUnlocked
                              ? '${_progressService.getDailyGoal()} sessions per day'
                              : 'Unlock Plus to customize your goal',
                        ),
                        leading: const Icon(Icons.flag),
                        trailing: purchaseService.isPlusUnlocked
                            ? const Icon(Icons.chevron_right)
                            : const Icon(Icons.lock),
                        onTap: purchaseService.isPlusUnlocked
                            ? _showDailyGoalPicker
                            : _showPlusSheet,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Saved Prompts'),
                        subtitle: Text(
                          purchaseService.isPlusUnlocked
                              ? savedPromptService.savedPromptCount == 0
                                  ? 'Add custom prompts or save favorites'
                                  : '${savedPromptService.savedPromptCount} prompts saved for review'
                              : 'Unlock Plus for custom prompts and review queue',
                        ),
                        leading: const Icon(Icons.bookmark),
                        trailing: purchaseService.isPlusUnlocked
                            ? const Icon(Icons.chevron_right)
                            : const Icon(Icons.lock),
                        onTap: purchaseService.isPlusUnlocked
                            ? () => GoRouter.of(context).go('/challenges/saved')
                            : _showPlusSheet,
                      ),
                    ],
                  ),
                );
              },
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
                      'Library, generated prompts, saved prompts, and progress stay on this device.',
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
                            'An offline-first practice app for text precision, dictation, and saved-prompt practice.',
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
        for (final color in ThemeService.accentColors) ...[
          _colorOption(color),
          if (color != ThemeService.accentColors.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _colorOption(Color color) {
    final isSelected = widget.themeService.accentColor == color;
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.outlineVariant;

    return GestureDetector(
      onTap: () {
        setState(() {
          widget.themeService.setAccentColor(color);
        });
      },
      child: Container(
        width: 28,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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

  void _showPlusSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const PlusPurchaseSheet(),
    );
  }

  void _showDailyGoalPicker() {
    final currentGoal = _progressService.getDailyGoal();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final goal in [3, 5, 10, 15])
              ListTile(
                title: Text('$goal sessions per day'),
                trailing: currentGoal == goal
                    ? const Icon(Icons.check_circle)
                    : const SizedBox.shrink(),
                onTap: () async {
                  await _progressService.setDailyGoal(goal);

                  if (!mounted || !context.mounted) return;

                  Navigator.of(context).pop();
                  setState(() {});
                },
              ),
          ],
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

  Future<void> _replayOnboarding() async {
    await AppPreferences.resetOnboarding();

    if (!mounted) return;

    GoRouter.of(context).go('/onboarding');
  }
}
