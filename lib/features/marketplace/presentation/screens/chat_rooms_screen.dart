import 'dart:ui';

import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/marketplace/presentation/controllers/communication_controller.dart';
import 'package:ecom/features/marketplace/presentation/widgets/chat_room_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatRoomsScreen extends ConsumerWidget {
  const ChatRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    if (user == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(context, isDark, textColor),
        body: _buildEmptyState(
          context,
          icon: Icons.lock_outline_rounded,
          title: 'Sign in to view messages',
          subtitle: 'Create an account or sign in to chat with sellers.',
        ),
      );
    }

    final isStaff = user.roles.contains(UserRole.storeManager) && !user.roles.contains(UserRole.seller);
    final effectiveUserId = isStaff ? (user.storeId ?? user.uid) : user.uid;

    final roomsAsync = ref.watch(chatRoomsStreamProvider(effectiveUserId, isStaff: isStaff));

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Subtle orb background ──────────────────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: _GlowOrb(
              color: const Color(0xFF7C3AED),
              size: 200,
              opacity: isDark ? 0.12 : 0.07,
            ),
          ),
          Positioned(
            bottom: 100,
            left: -40,
            child: _GlowOrb(
              color: const Color(0xFFEC4899),
              size: 160,
              opacity: isDark ? 0.1 : 0.05,
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                pinned: true,
                snap: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.7),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.08 : 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Center(
                    child: _FrostedIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      isDark: isDark,
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                leadingWidth: 70,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Messages',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
              ),

              // ── Body ──────────────────────────────────────────────────────
              roomsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  ),
                ),
                error: (err, _) => SliverFillRemaining(
                  child: _buildEmptyState(
                    context,
                    icon: Icons.error_outline_rounded,
                    title: 'Something went wrong',
                    subtitle: err.toString(),
                  ),
                ),
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(
                        context,
                        icon: Icons.forum_outlined,
                        title: 'No conversations yet',
                        subtitle:
                            'Visit a product page and tap "Chat with Seller" to start a conversation.',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final room = rooms[index];
                        return ChatRoomCard(
                          room: room,
                          currentUserId: effectiveUserId,
                          onTap: () => context.push('/chat/${room.chatId}'),
                        );
                      }, childCount: rooms.length),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isDark, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: _FrostedIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            isDark: isDark,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      title: Text(
        'Messages',
        style: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                ),
              ),
              child: Icon(icon, size: 48, color: const Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecond
                    : AppColors.lightTextSecond,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _FrostedIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onPressed;

  const _FrostedIconButton({
    required this.icon,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
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
        child: Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white : AppColors.lightTextPrimary,
        ),
      ),
    );
  }
}
