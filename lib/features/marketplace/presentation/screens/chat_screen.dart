import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/marketplace/presentation/controllers/communication_controller.dart';
import 'package:ecom/features/marketplace/presentation/widgets/chat_bubble.dart';
import 'package:ecom/features/marketplace/presentation/widgets/chat_typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  Timer? _typingTimer;
  bool _isTyping = false;

  // Room metadata fetched from Firestore
  String _otherName = 'Chat';
  String? _otherPhotoUrl;
  bool _metaLoaded = false;

  String get _currentUserId =>
      ref.read(currentUserIdProvider) ?? 'unknown';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRoomMeta();
    // Mark as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(communicationControllerProvider.notifier)
          .markRead(widget.chatId, _currentUserId);
    });
  }

  Future<void> _loadRoomMeta() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();
      if (!mounted) return;
      final data = doc.data() ?? {};
      final buyerId = data['buyerId'] as String? ?? '';
      final isCurrentUserBuyer = _currentUserId == buyerId;
      setState(() {
        _otherName = isCurrentUserBuyer
            ? (data['sellerName'] as String? ?? 'Seller')
            : (data['buyerName'] as String? ?? 'Buyer');
        _otherPhotoUrl = isCurrentUserBuyer
            ? (data['sellerPhotoUrl'] as String?)
            : (data['buyerPhotoUrl'] as String?);
        _metaLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _metaLoaded = true);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _cancelTyping();

    await ref
        .read(communicationControllerProvider.notifier)
        .transmitText(widget.chatId, _currentUserId, text);

    _scrollToBottom();
  }

  void _onTextChanged(String value) {
    if (value.isNotEmpty && !_isTyping) {
      _isTyping = true;
      ref
          .read(communicationControllerProvider.notifier)
          .setTyping(widget.chatId, _currentUserId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), _cancelTyping);
  }

  void _cancelTyping() {
    if (_isTyping) {
      _isTyping = false;
      ref
          .read(communicationControllerProvider.notifier)
          .setTyping(widget.chatId, _currentUserId, false);
    }
    _typingTimer?.cancel();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController
              .jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  void dispose() {
    _cancelTyping();
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final textColor =
        isDark ? Colors.white : AppColors.lightTextPrimary;

    final messagesAsync =
        ref.watch(liveMessageStreamProvider(widget.chatId));
    final otherTyping = ref
        .watch(otherTypingStreamProvider(widget.chatId, _currentUserId))
        .value ?? false;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Background orbs ──────────────────────────────────────────────
          Positioned(
            top: -40,
            right: -30,
            child: _GlowOrb(
              color: const Color(0xFF7C3AED),
              size: 160,
              opacity: isDark ? 0.10 : 0.06,
            ),
          ),

          Column(
            children: [
              // ── Custom AppBar ────────────────────────────────────────────
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.75),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white
                              .withValues(alpha: isDark ? 0.08 : 0.5),
                        ),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            // Back button
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black
                                          .withValues(alpha: 0.04),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                        alpha: isDark ? 0.12 : 0.2),
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Avatar
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFFA855F7)
                                  ],
                                ),
                              ),
                              child: _otherPhotoUrl != null &&
                                      _otherPhotoUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        _otherPhotoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            _AvatarInitials(
                                                name: _otherName),
                                      ),
                                    )
                                  : _AvatarInitials(name: _otherName),
                            ),
                            const SizedBox(width: 12),

                            // Name + status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _metaLoaded ? _otherName : '...',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    child: otherTyping
                                        ? Text(
                                            'typing...',
                                            key: const ValueKey('typing'),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: const Color(0xFF7C3AED),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          )
                                        : Text(
                                            'tap to view profile',
                                            key: const ValueKey('status'),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors.darkTextSecond
                                                  : AppColors.lightTextSecond,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Messages area ────────────────────────────────────────────
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF7C3AED)),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      'Error: $err',
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  data: (messages) {
                    if (messages.isEmpty && !otherTyping) {
                      return _buildEmptyChat(isDark);
                    }

                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _scrollToBottom(animate: false));

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: messages.length + (otherTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (otherTyping && index == messages.length) {
                          return const ChatTypingIndicator();
                        }
                        final message = messages[index];
                        final isMe = message.senderId == _currentUserId;

                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          builder: (ctx, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(
                                  0, (1 - value) * 12),
                              child: child,
                            ),
                          ),
                          child: ChatBubble(
                            message: message,
                            isMe: isMe,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Input Bar ────────────────────────────────────────────────
              _buildInputBar(isDark, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
              ),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start the conversation',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.lightTextSecond,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Send a message to get started',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white38 : AppColors.lightTextSecond,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark, BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color:
                    Colors.white.withValues(alpha: isDark ? 0.08 : 0.5),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  // ── Text field ───────────────────────────────────────────
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: isDark ? 0.1 : 0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        onChanged: _onTextChanged,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: GoogleFonts.inter(
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.inter(
                            color: isDark
                                ? Colors.white38
                                : AppColors.lightTextSecond,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ── Send button ──────────────────────────────────────────
                  GestureDetector(
                    onTap: _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF7C3AED),
                            Color(0xFFA855F7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x447C3AED),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          fontSize: 15,
        ),
      ),
    );
  }
}
