import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
                  'Privacy Policy',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                centerTitle: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Last updated: June 2026',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _PolicySection(
                      title: '1. Information We Collect',
                      body:
                          'We collect information you provide directly, such as your name, '
                          'email address, phone number, and delivery addresses when you create '
                          'an account or place an order. We also collect transactional data '
                          'including order history, payment method details (processed securely '
                          'by our payment partner), and product reviews you submit.',
                    ),
                    const _PolicySection(
                      title: '2. How We Use Your Information',
                      body:
                          'We use the information we collect to: process and fulfil your '
                          'orders; send order confirmations, shipping updates, and receipts; '
                          'respond to your questions and support requests; personalise product '
                          'recommendations; detect and prevent fraud; and comply with legal '
                          'obligations. We do not use your data for purposes unrelated to the '
                          'services we provide.',
                    ),
                    const _PolicySection(
                      title: '3. Sharing of Information',
                      body:
                          'We do not sell your personal information. We share data only with: '
                          'sellers on our platform (limited to what is necessary to fulfil your '
                          'order, e.g. your delivery address); our payment processor for '
                          'transaction handling; logistics partners for delivery; and service '
                          'providers who help operate our platform under strict confidentiality '
                          'agreements. We may disclose information when required by law.',
                    ),
                    const _PolicySection(
                      title: '4. Data Retention',
                      body:
                          'We retain your personal data for as long as your account is active '
                          'or as needed to provide services and comply with legal obligations. '
                          'You may request deletion of your account and associated data at any '
                          'time by contacting our support team.',
                    ),
                    const _PolicySection(
                      title: '5. Security',
                      body:
                          'We use industry-standard encryption (TLS) for all data in transit '
                          'and encrypt sensitive data at rest. Access to personal data is '
                          'restricted to authorised personnel on a need-to-know basis. However, '
                          'no method of transmission over the internet is 100% secure, and we '
                          'cannot guarantee absolute security.',
                    ),
                    const _PolicySection(
                      title: '6. Cookies and Analytics',
                      body:
                          'Our mobile application does not use browser cookies. We may collect '
                          'anonymised usage analytics to improve app performance and user '
                          'experience. This data cannot be used to identify you individually.',
                    ),
                    const _PolicySection(
                      title: '7. Your Rights',
                      body:
                          'Depending on your jurisdiction, you may have the right to: access '
                          'the personal data we hold about you; request correction of inaccurate '
                          'data; request deletion of your data; object to or restrict certain '
                          'processing; and data portability. To exercise any of these rights, '
                          'contact us at the address below.',
                    ),
                    const _PolicySection(
                      title: '8. Children\'s Privacy',
                      body:
                          'Our services are not directed to individuals under the age of 18. '
                          'We do not knowingly collect personal information from minors. If we '
                          'become aware that we have collected such information, we will delete '
                          'it promptly.',
                    ),
                    const _PolicySection(
                      title: '9. Changes to This Policy',
                      body:
                          'We may update this Privacy Policy from time to time. We will notify '
                          'you of significant changes via the app or by email. Continued use of '
                          'the app after changes constitutes acceptance of the revised policy.',
                    ),
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

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          GlassCardWidget(
            padding: const EdgeInsets.all(16),
            child: Text(
              body,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: subtitleColor,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
