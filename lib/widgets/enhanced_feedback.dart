import 'package:flutter/material.dart';

import 'app_surface.dart';

class EnhancedFeedback extends StatelessWidget {
  final String userInput;
  final String correctSentence;
  final bool isCorrect;

  const EnhancedFeedback({
    super.key,
    required this.userInput,
    required this.correctSentence,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = isCorrect ? colorScheme.primary : colorScheme.error;

    return AppSurface(
      color: isCorrect
          ? colorScheme.primaryContainer.withValues(alpha: 0.36)
          : colorScheme.errorContainer.withValues(alpha: 0.48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.error_outline,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Matched exactly' : 'Review the differences',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isCorrect)
            Text(
              'Your answer matches the prompt. Move on while the rhythm is fresh.',
              style: theme.textTheme.bodyMedium,
            )
          else ...[
            _buildDifferenceBlock(
              context,
              title: 'Your answer',
              words: _highlightDifferences(
                _splitWords(userInput),
                _splitWords(correctSentence),
                isUserInput: true,
                theme: theme,
              ),
            ),
            const SizedBox(height: 12),
            _buildDifferenceBlock(
              context,
              title: 'Expected answer',
              words: _highlightDifferences(
                _splitWords(correctSentence),
                _splitWords(userInput),
                isUserInput: false,
                theme: theme,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDifferenceBlock(
    BuildContext context, {
    required String title,
    required List<TextSpan> words,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              children: words,
            ),
          ),
        ),
      ],
    );
  }

  List<String> _splitWords(String value) {
    return value.trim().split(RegExp(r'\s+')).where((word) {
      return word.trim().isNotEmpty;
    }).toList();
  }

  List<TextSpan> _highlightDifferences(
    List<String> primaryWords,
    List<String> comparisonWords, {
    required bool isUserInput,
    required ThemeData theme,
  }) {
    final spans = <TextSpan>[];
    final colorScheme = theme.colorScheme;
    final differenceColor =
        isUserInput ? colorScheme.error : colorScheme.primary;
    final baseColor = colorScheme.onSurface;

    for (var index = 0; index < primaryWords.length; index++) {
      final word = primaryWords[index];
      final comparisonWord =
          index < comparisonWords.length ? comparisonWords[index] : '';
      final isDifferent =
          _normalizeWord(word) != _normalizeWord(comparisonWord);

      spans.add(
        TextSpan(
          text: '$word ',
          style: TextStyle(
            color: isDifferent ? differenceColor : baseColor,
            fontWeight: isDifferent ? FontWeight.w700 : FontWeight.normal,
            decoration: isDifferent ? TextDecoration.underline : null,
          ),
        ),
      );
    }

    if (!isUserInput && comparisonWords.length < primaryWords.length) {
      spans.add(
        TextSpan(
          text: '(missing words)',
          style: TextStyle(
            color: colorScheme.tertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return spans;
  }

  String _normalizeWord(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }
}
