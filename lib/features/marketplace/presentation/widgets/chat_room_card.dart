import 'package:ecom/features/marketplace/domain/entities/chat_room.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatRoomCard extends StatelessWidget {
  final ChatRoom room;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatRoomCard({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final otherName = room.otherName(currentUserId);
    final otherPhoto = room.otherPhotoUrl(currentUserId);
    final unread = room.unreadFor(currentUserId);
    final hasUnread = unread > 0;

    final timeStr = room.lastMessageAt != null
        ? _formatTime(room.lastMessageAt!)
        : '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: hasUnread ? 0.07 : 0.04)
              : Colors.white.withValues(alpha: hasUnread ? 1.0 : 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasUnread
                ? const Color(0xFF7C3AED).withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: isDark ? 0.1 : 0.6),
            width: hasUnread ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: hasUnread
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              // ── Avatar ────────────────────────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: otherPhoto != null && otherPhoto.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              otherPhoto,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _AvatarInitials(name: otherName),
                            ),
                          )
                        : _AvatarInitials(name: otherName),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEC4899),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // ── Content ───────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherName,
                            style: GoogleFonts.inter(
                              fontWeight:
                                  hasUnread ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: hasUnread
                                ? const Color(0xFF7C3AED)
                                : colorScheme.onSurfaceVariant,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      room.lastMessage.isEmpty
                          ? 'Start the conversation'
                          : room.lastMessage,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: hasUnread
                            ? (isDark ? Colors.white70 : const Color(0xFF374151))
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('hh:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('dd/MM/yy').format(dt);
  }
}

class _AvatarInitials extends StatelessWidget {
  final String name;
  const _AvatarInitials({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '?';
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
