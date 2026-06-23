import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';

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

  Widget _buildFrostedCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.2),
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18),
        color: isDark ? Colors.white : AppColors.lightTextPrimary,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
      body: Stack(
        children: [
          const IgnorePointer(child: OrbBackgroundWidget()),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                snap: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leadingWidth: 70,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Center(
                    child: _buildFrostedCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () => Navigator.pop(context),
                      isDark: isDark,
                    ),
                  ),
                ),
                title: Text(
                  'Help Center',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                centerTitle: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Support Agent Card ──
                    GlassCardWidget(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.support_agent_outlined,
                              size: 32,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'How can we help?',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Browse our frequently asked questions below.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── FAQ Header ──
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: Text(
                        'Frequently Asked Questions',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),

                    // ── Accordion List of FAQs ──
                    ..._faqs.map((faq) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCardWidget(
                            padding: EdgeInsets.zero,
                            child: Theme(
                              data: theme.copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.question_answer_outlined,
                                    size: 16,
                                    color: Color(0xFFA855F7),
                                  ),
                                ),
                                title: Text(
                                  faq.question,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                iconColor: const Color(0xFFA855F7),
                                collapsedIconColor: const Color(0xFFA855F7),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        faq.answer,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: subtitleColor,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                  ]),
                ),
              ),
            ],
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
