import 'package:flutter/material.dart';

class PracticeModeSelector extends StatelessWidget {
  final bool isListeningMode;
  final Function(Set<bool>) onSelectionChanged;

  const PracticeModeSelector({
    super.key,
    required this.isListeningMode,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment<bool>(
            value: false,
            label: Text('Text Mode'),
            icon: Icon(Icons.menu_book),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text('Audio Mode'),
            icon: Icon(Icons.hearing),
          ),
        ],
        selected: {isListeningMode},
        onSelectionChanged: onSelectionChanged,
      ),
    );
  }
}
