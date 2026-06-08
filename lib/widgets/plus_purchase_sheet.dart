import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/purchase_service.dart';

class PlusPurchaseSheet extends StatelessWidget {
  const PlusPurchaseSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseService>(
      builder: (context, purchaseService, child) {
        final theme = Theme.of(context);
        final isUnlocked = purchaseService.isPlusUnlocked;
        final price = purchaseService.plusPrice;

        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.workspace_premium,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isUnlocked ? 'JusType Plus' : 'Unlock JusType Plus',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isUnlocked
                        ? 'Plus is active on this device.'
                        : 'A one-time upgrade for custom prompts, review queues, and daily goals.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _BenefitRow(
                    icon: Icons.add,
                    title: 'Custom prompts',
                    description:
                        'Write your own prompts and keep them on device.',
                  ),
                  const SizedBox(height: 12),
                  const _BenefitRow(
                    icon: Icons.view_list,
                    title: 'Review queue',
                    description:
                        'Practice saved and custom prompts in one run.',
                  ),
                  const SizedBox(height: 12),
                  const _BenefitRow(
                    icon: Icons.flag,
                    title: 'Custom daily goals',
                    description: 'Choose 3, 5, 10, or 15 sessions per day.',
                  ),
                  const SizedBox(height: 12),
                  const _BenefitRow(
                    icon: Icons.offline_pin,
                    title: 'Keep the app offline-first',
                    description:
                        'No account required. Your practice stays local.',
                  ),
                  if (purchaseService.statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      purchaseService.statusMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (isUnlocked)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: purchaseService.canBuyPlus
                            ? purchaseService.buyPlus
                            : null,
                        icon: purchaseService.purchasePending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_open),
                        label: Text(
                          price.isEmpty
                              ? 'Unlock Plus'
                              : 'Unlock Plus - $price',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: purchaseService.purchasePending
                            ? null
                            : purchaseService.restorePurchases,
                        child: const Text('Restore Purchase'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
