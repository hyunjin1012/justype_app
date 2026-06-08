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

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: prompts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _SavedPromptTile(savedPrompt: prompts[index]);
            },
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
                'Save favorite prompts',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock Plus to bookmark interesting prompts and replay them whenever you want.',
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
              'No saved prompts yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the bookmark icon during practice to save prompts for later.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => GoRouter.of(context).go('/challenges/text'),
              icon: const Icon(Icons.keyboard),
              label: const Text('Start Practice'),
            ),
          ],
        ),
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
