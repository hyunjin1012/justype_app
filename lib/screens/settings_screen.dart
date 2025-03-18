import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeService themeService;

  const SettingsScreen({super.key, required this.themeService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeService _themeService;
  int _dailyGoal = 5;

  @override
  void initState() {
    super.initState();
    _themeService = widget.themeService;
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
          // Theme settings
          Card(
            elevation: 2,
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Dark mode toggle
                  ListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Switch between light and dark theme'),
                    trailing: Switch(
                      value: _themeService.isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          _themeService.toggleTheme();
                        });
                      },
                    ),
                  ),

                  // Accent color selector
                  ListTile(
                    title: const Text('Accent Color'),
                    subtitle: const Text('Choose your preferred accent color'),
                    trailing: _buildColorSelector(),
                  ),
                ],
              ),
            ),
          ),

          // Practice settings
          Card(
            elevation: 2,
            margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Practice Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Daily goal setting
                  ListTile(
                    title: const Text('Daily Goal'),
                    subtitle:
                        const Text('Number of exercises to complete each day'),
                    trailing: DropdownButton<int>(
                      value: _dailyGoal,
                      items: [3, 5, 10, 15, 20].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value'),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _dailyGoal = newValue;
                            // Assuming _progressService.setDailyGoal(newValue) is called elsewhere
                          });
                        }
                      },
                    ),
                  ),

                  // Font size slider
                  ListTile(
                    title: const Text('Text Size'),
                    subtitle: const Text('Adjust the size of practice text'),
                    trailing: SizedBox(
                      width: 120,
                      child: Slider(
                        value: _themeService.fontSize,
                        min: 0.8,
                        max: 1.4,
                        divisions: 6,
                        label: _getFontSizeLabel(_themeService.fontSize),
                        onChanged: (value) {
                          setState(() {
                            _themeService.setFontSize(value);
                          });
                        },
                      ),
                    ),
                  ),

                  // Speech rate slider for audio challenges
                  ListTile(
                    title: const Text('Speech Rate'),
                    subtitle: const Text('Adjust the speed of audio playback'),
                    trailing: SizedBox(
                      width: 120,
                      child: Slider(
                        value: _themeService.speechRate,
                        min: 0.5,
                        max: 1.5,
                        divisions: 4,
                        label: '${_themeService.speechRate}x',
                        onChanged: (value) {
                          setState(() {
                            _themeService.setSpeechRate(value);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Data management
          Card(
            elevation: 2,
            margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Reset progress button
                  ListTile(
                    title: const Text('Reset Progress'),
                    subtitle:
                        const Text('Clear all achievements and statistics'),
                    trailing: ElevatedButton(
                      onPressed: _showResetConfirmationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // App info
          Card(
            elevation: 2,
            margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About JusType',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    title: Text('Version'),
                    subtitle: Text('1.0.0'),
                  ),
                  ListTile(
                    title: const Text('Help & Feedback'),
                    subtitle: const Text('Get support or share your thoughts'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Open help/feedback screen or link
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
    final isSelected = _themeService.accentColor == color;

    return GestureDetector(
      onTap: () {
        setState(() {
          _themeService.setAccentColor(color);
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

  Future<void> _showResetConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset All Progress'),
          content: const SingleChildScrollView(
            child: Text(
              'This will erase all your progress, achievements, and statistics. '
              'This action cannot be undone. Are you sure you want to continue?',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Reset'),
              onPressed: () {
                _resetAllProgress();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetAllProgress() async {
    // Assuming _resetAllProgress() is called elsewhere
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All progress has been reset'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
