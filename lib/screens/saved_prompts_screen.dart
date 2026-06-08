import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/purchase_service.dart';
import '../services/saved_prompt_service.dart';
import '../widgets/app_surface.dart';
import '../widgets/plus_purchase_sheet.dart';

class SavedPromptsScreen extends StatefulWidget {
  const SavedPromptsScreen({super.key});

  @override
  State<SavedPromptsScreen> createState() => _SavedPromptsScreenState();
}

class _SavedPromptsScreenState extends State<SavedPromptsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPrompts();
  }

  Future<void> _loadSavedPrompts() async {
    final savedPromptService =
        Provider.of<SavedPromptService>(context, listen: false);
    await savedPromptService.loadSavedPrompts();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Prompts'),
        actions: [
          Consumer<PurchaseService>(
            builder: (context, purchaseService, child) {
              return IconButton(
                tooltip: 'Add custom prompt',
                icon: const Icon(Icons.add),
                onPressed: purchaseService.isPlusUnlocked
                    ? _showCustomPromptDialog
                    : _showPlusSheet,
              );
            },
          ),
        ],
      ),
      body: Consumer2<PurchaseService, SavedPromptService>(
        builder: (context, purchaseService, savedPromptService, child) {
          if (_isLoading || !savedPromptService.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!purchaseService.isPlusUnlocked) {
            return _buildLockedState(context);
          }

          final prompts = savedPromptService.savedPrompts;
          if (prompts.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildReviewHeader(context, prompts.length),
              const SizedBox(height: 12),
              for (final prompt in prompts) ...[
                _SavedPromptTile(savedPrompt: prompt),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildLockedState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmarks_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Build your own prompt queue',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock Plus to save favorites, add custom prompts, and review them as a queue.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showPlusSheet,
                  icon: const Icon(Icons.workspace_premium),
                  label: const Text('Unlock Plus'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_add_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No prompts saved yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save prompts during practice or add your own custom prompt.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _showCustomPromptDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Custom Prompt'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => GoRouter.of(context).go('/challenges/text'),
                icon: const Icon(Icons.keyboard),
                label: const Text('Start Typing'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewHeader(BuildContext context, int promptCount) {
    final theme = Theme.of(context);

    return AppSurface(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.view_list, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Review Queue',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$promptCount prompts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Practice saved and custom prompts in one focused run.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      GoRouter.of(context).go('/challenges/saved/review'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Review'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _showCustomPromptDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Prompt'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCustomPromptDialog() {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Custom Prompt'),
          content: TextField(
            controller: controller,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Prompt',
              hintText: 'Write a line you want to practice.',
              alignLabelWithHint: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final prompt = controller.text.trim();
                if (prompt.isEmpty) return;

                final savedPromptService =
                    Provider.of<SavedPromptService>(context, listen: false);
                final wasAlreadySaved = savedPromptService.isSaved(prompt);
                await savedPromptService.savePrompt(
                  prompt: prompt,
                  sourceLabel: 'Custom Prompt',
                );

                if (!mounted || !dialogContext.mounted) return;

                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      wasAlreadySaved
                          ? 'Prompt was already saved'
                          : 'Custom prompt added',
                    ),
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _showPlusSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const PlusPurchaseSheet(),
    );
  }
}

class _SavedPromptTile extends StatelessWidget {
  final SavedPrompt savedPrompt;

  const _SavedPromptTile({
    required this.savedPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurface(
      onTap: () => GoRouter.of(context).push(
        '/challenges/saved/practice/${Uri.encodeComponent(savedPrompt.id)}',
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bookmark,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  savedPrompt.prompt,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${savedPrompt.sourceLabel} - Saved ${_formatDate(savedPrompt.savedAtDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove saved prompt',
            icon: const Icon(Icons.close),
            onPressed: () => _removeSavedPrompt(context),
          ),
        ],
      ),
    );
  }

  Future<void> _removeSavedPrompt(BuildContext context) async {
    final savedPromptService =
        Provider.of<SavedPromptService>(context, listen: false);
    await savedPromptService.removePromptById(savedPrompt.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed saved prompt'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
