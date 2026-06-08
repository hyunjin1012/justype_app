import 'package:flutter/material.dart';

class PracticeSessionScaffold extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget content;
  final Widget inputArea;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry bottomPadding;
  final String feedback;
  final bool? isFeedbackCorrect;
  final VoidCallback? onShowDetails;
  final VoidCallback? onNext;
  final String nextLabel;
  final String promptHint;

  const PracticeSessionScaffold({
    super.key,
    required this.title,
    required this.content,
    required this.inputArea,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.scrollController,
    this.contentPadding = const EdgeInsets.all(16),
    this.bottomPadding = const EdgeInsets.all(16),
    this.feedback = '',
    this.isFeedbackCorrect,
    this.onShowDetails,
    this.onNext,
    this.nextLabel = 'New prompt',
    this.promptHint = 'Match the prompt exactly.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: leading,
        actions: actions,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: contentPadding,
                child: content,
              ),
            ),
            Padding(
              padding: bottomPadding,
              child: Column(
                children: [
                  if (promptHint.trim().isNotEmpty) ...[
                    _buildPromptHint(context),
                    const SizedBox(height: 8),
                  ],
                  inputArea,
                  if (onNext != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onNext,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(nextLabel),
                      ),
                    ),
                  ],
                  if (feedback.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      feedback,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _feedbackColor(context),
                      ),
                    ),
                    if (onShowDetails != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: onShowDetails,
                        icon: const Icon(Icons.feedback),
                        label: const Text('Details'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _feedbackColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isFeedbackCorrect == null) {
      return colorScheme.onSurfaceVariant;
    }

    return isFeedbackCorrect! ? colorScheme.primary : colorScheme.error;
  }

  Widget _buildPromptHint(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            promptHint,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
