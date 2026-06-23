import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ecom/core/constants/app_info.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  'About',
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
                    // ── App Identity ──
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 56,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppInfo.appName,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Version ${AppInfo.version}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your trusted local marketplace — connecting buyers\nwith verified sellers across India.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: subtitleColor,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Contact Section ──
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Contact Support',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    GlassCardWidget(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.email_outlined, color: Color(0xFFA855F7), size: 18),
                              ),
                              title: Text('Email', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                              subtitle: Text(AppInfo.supportEmail, style: GoogleFonts.inter(fontSize: 12, color: subtitleColor)),
                              trailing: Icon(Icons.copy, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                              onTap: () => _copyToClipboard(context, AppInfo.supportEmail, 'Email copied to clipboard'),
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.phone_outlined, color: Color(0xFFA855F7), size: 18),
                              ),
                              title: Text('Phone', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                              subtitle: Text(AppInfo.supportPhone, style: GoogleFonts.inter(fontSize: 12, color: subtitleColor)),
                              trailing: Icon(Icons.copy, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                              onTap: () => _copyToClipboard(context, AppInfo.supportPhone, 'Phone number copied to clipboard'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Legal Section ──
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Legal Links',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    GlassCardWidget(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.policy_outlined, color: Color(0xFFA855F7), size: 18),
                              ),
                              title: Text('Privacy Policy', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                              trailing: Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? Colors.white38 : Colors.black38),
                              onTap: () => _copyToClipboard(context, AppInfo.privacyPolicyUrl, 'Link copied'),
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.description_outlined, color: Color(0xFFA855F7), size: 18),
                              ),
                              title: Text('Terms & Conditions', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                              trailing: Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? Colors.white38 : Colors.black38),
                              onTap: () => _copyToClipboard(context, AppInfo.termsUrl, 'Link copied'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    Center(
                      child: Text(
                        '© 2026 ${AppInfo.appName}. All rights reserved.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
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
