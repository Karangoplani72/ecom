import 'package:ecom/core/constants/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecom/core/widgets/scaffolds/premium_25d_scaffold.dart';
import 'package:ecom/core/widgets/cards/glass_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'How do I track my order?',
      answer:
          'Go to My Account → My Orders and tap on the order you want to track. '
          'You will see real-time status updates from the seller.',
    ),
    _FaqItem(
      question: 'Can I cancel or modify an order?',
      answer:
          'Orders can be cancelled before the seller confirms shipment. '
          'Open the order detail and tap "Cancel Order". Modifications are '
          'not supported after placement — please cancel and re-order.',
    ),
    _FaqItem(
      question: 'How do refunds work?',
      answer:
          'Once your cancellation or return is approved, the refund is '
          'credited to your original payment method within 5–7 business days.',
    ),
    _FaqItem(
      question: 'How do I add or change a delivery address?',
      answer:
          'Go to My Account → Account Settings → Manage Saved Addresses. '
          'You can add multiple addresses and set a default.',
    ),
    _FaqItem(
      question: 'My payment failed — what should I do?',
      answer:
          'Double-check your card details and try again. If the issue persists, '
          'contact your bank or reach out to our support team.',
    ),
    _FaqItem(
      question: 'How do I report a product or seller?',
      answer:
          'Open the product detail page and tap the flag icon in the top-right '
          'corner. Our moderation team reviews all reports within 24 hours.',
    ),
    _FaqItem(
      question: 'Is my personal information secure?',
      answer:
          'Yes. We use industry-standard encryption for all data in transit and '
          'at rest. We never sell your personal information to third parties. '
          'See our Privacy Policy for full details.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Premium25DScaffold(
      isDark: theme.brightness == Brightness.dark,
      appBar: AppBar(title: const Text('Help Center'), centerTitle: true, backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // ── Hero banner ──
          GlassCard(
            isDark: theme.brightness == Brightness.dark,
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.support_agent_outlined,
                    size: 40, color: colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How can we help?',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer)),
                      const SizedBox(height: 4),
                      Text('Browse FAQs or contact our team.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── FAQ section ──
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              'Frequently Asked Questions',
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
          ),
          ..._faqs.map((faq) => _FaqTile(item: faq)),

          const SizedBox(height: 32),

          // ── Contact support ──
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              'Contact Support',
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
          ),
          GlassCard(
            isDark: theme.brightness == Brightness.dark,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.email_outlined,
                          size: 20, color: colorScheme.onSurface),
                    ),
                    title: const Text('Email Support'),
                    subtitle: const Text(AppInfo.supportEmail),
                    trailing: const Icon(Icons.copy, size: 16),
                    onTap: () {
                      Clipboard.setData(
                          const ClipboardData(text: AppInfo.supportEmail));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Email address copied'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: colorScheme.outlineVariant),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.phone_outlined,
                          size: 20, color: colorScheme.onSurface),
                    ),
                    title: const Text('Phone Support'),
                    subtitle: const Text(AppInfo.supportPhone),
                    trailing: const Icon(Icons.copy, size: 16),
                    onTap: () {
                      Clipboard.setData(
                          const ClipboardData(text: AppInfo.supportPhone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Phone number copied'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(
                  widget.item.answer,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant, height: 1.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
