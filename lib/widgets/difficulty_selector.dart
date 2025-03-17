import 'package:flutter/material.dart';

class DifficultySelector extends StatelessWidget {
  final String selectedDifficulty;
  final Function(String) onDifficultyChanged;

  const DifficultySelector({
    super.key,
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Difficulty Level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDifficultyButton(
                  context,
                  'Easy',
                  Icons.sentiment_satisfied,
                  Colors.green,
                ),
                _buildDifficultyButton(
                  context,
                  'Medium',
                  Icons.sentiment_neutral,
                  Colors.orange,
                ),
                _buildDifficultyButton(
                  context,
                  'Hard',
                  Icons.sentiment_very_dissatisfied,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(
    BuildContext context,
    String difficulty,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedDifficulty == difficulty;

    return InkWell(
      onTap: () => onDifficultyChanged(difficulty),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              difficulty,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
