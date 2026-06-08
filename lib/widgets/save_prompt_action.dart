import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/purchase_service.dart';
import '../services/saved_prompt_service.dart';
import 'plus_purchase_sheet.dart';

class SavePromptAction extends StatelessWidget {
  final String prompt;
  final String sourceLabel;

  const SavePromptAction({
    super.key,
    required this.prompt,
    required this.sourceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedPrompt = prompt.trim();

    return Consumer2<PurchaseService, SavedPromptService>(
      builder: (context, purchaseService, savedPromptService, child) {
        final isSaved = savedPromptService.isSaved(trimmedPrompt);

        return IconButton(
          tooltip: isSaved ? 'Remove saved prompt' : 'Save prompt',
          icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
          onPressed: trimmedPrompt.isEmpty
              ? null
              : () => _handleTap(
                    context,
                    purchaseService,
                    savedPromptService,
                  ),
        );
      },
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    PurchaseService purchaseService,
    SavedPromptService savedPromptService,
  ) async {
    if (!purchaseService.isPlusUnlocked) {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => const PlusPurchaseSheet(),
      );
      return;
    }

    final isNowSaved = await savedPromptService.togglePrompt(
      prompt: prompt,
      sourceLabel: sourceLabel,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isNowSaved ? 'Saved prompt' : 'Removed saved prompt'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
