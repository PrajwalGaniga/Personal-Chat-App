import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/date_label.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollCtrl = ScrollController();
  bool _showScrollBtn = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset < _scrollCtrl.position.maxScrollExtent - 200;
      if (show != _showScrollBtn) setState(() => _showScrollBtn = show);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollCtrl.hasClients) return;
    if (animated) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
  }

  Future<void> _pickImage(ChatProvider provider) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Send Photo',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sourceOption(Icons.photo_camera_rounded, 'Camera',
                    ImageSource.camera),
                _sourceOption(Icons.photo_library_rounded, 'Gallery',
                    ImageSource.gallery),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (picked == null) return;
    await provider.sendImage(File(picked.path));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Widget _sourceOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF025144),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF25D366), size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<ChatProvider>();
    final msgs      = provider.messages;
    final myPhone   = provider.currentUser?.phone ?? '';

    // Auto scroll on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients &&
          _scrollCtrl.position.maxScrollExtent -
                  _scrollCtrl.offset <
              300) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: _buildAppBar(context, provider),
      body: Stack(
        children: [
          // ── Chat background pattern ──────────────────────────────────
          _ChatBackground(),

          // ── Message list ─────────────────────────────────────────────
          Column(
            children: [
              Expanded(
                child: msgs.isEmpty
                    ? _EmptyState()
                    : _buildMessageList(msgs, myPhone, provider),
              ),

              // ── Bottom bar ─────────────────────────────────────────
              ChatBottomBar(
                onSend: (text) {
                  provider.sendTextMessage(text);
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _scrollToBottom());
                },
                onAttach: () => _pickImage(provider),
                isSending: provider.isSending,
              ),
            ],
          ),

          // ── Scroll-to-bottom FAB ──────────────────────────────────────
          if (_showScrollBtn)
            Positioned(
              bottom: 84,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: () => _scrollToBottom(),
                backgroundColor: const Color(0xFF1F2C34),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF25D366),
                ),
              ).animate().scale(duration: 200.ms),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, ChatProvider provider) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: const Color(0xFF25D366).withOpacity(0.2),
          child: Text(
            provider.otherUserName.isNotEmpty
                ? provider.otherUserName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Color(0xFF25D366),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.otherUserName,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          Text(
            provider.otherOnline
                ? '🟢 online'
                : provider.wsConnected
                    ? 'last seen recently'
                    : '⚡ connecting...',
            style: TextStyle(
              fontSize: 12,
              color: provider.otherOnline
                  ? const Color(0xFF25D366)
                  : Colors.white38,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          color: const Color(0xFF1F2C34),
          onSelected: (val) async {
            if (val == 'logout') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1F2C34),
                  title: const Text('Logout',
                      style: TextStyle(color: Colors.white)),
                  content: const Text('Are you sure you want to logout?',
                      style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white54))),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout',
                            style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                context.read<ChatProvider>().logout();
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(children: [
                Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                SizedBox(width: 10),
                Text('Logout', style: TextStyle(color: Colors.white70)),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageList(
      List<Message> msgs, String myPhone, ChatProvider provider) {
    // Build items list with date label separators
    final items = <dynamic>[];
    String? lastLabel;
    for (final msg in msgs) {
      if (msg.dateLabel != lastLabel) {
        items.add(msg.dateLabel);
        lastLabel = msg.dateLabel;
      }
      items.add(msg);
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        if (item is String) {
          return DateLabelWidget(label: item)
              .animate()
              .fadeIn(duration: 300.ms);
        }
        final msg = item as Message;
        final isMine = msg.senderPhone == myPhone;
        return MessageBubble(
          message: msg,
          isMine: isMine,
          onDelete: isMine
              ? () => provider.deleteMessage(msg.id)
              : null,
        ).animate().fadeIn(duration: 250.ms).slideX(
              begin: isMine ? 0.1 : -0.1,
              end: 0,
              duration: 250.ms,
              curve: Curves.easeOut,
            );
      },
    );
  }
}

// ── Chat wallpaper-style background ──────────────────────────────────────────
class _ChatBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B141A), Color(0xFF0D1F2D)],
        ),
      ),
      child: CustomPaint(
        painter: _DotPatternPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF25D366).withOpacity(0.03)
      ..strokeWidth = 1;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Empty state ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          const Text(
            'No messages yet\nSay hello! 👋',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 15, height: 1.5),
          ),
        ],
      ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
    );
  }
}
