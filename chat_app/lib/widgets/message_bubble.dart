// lib/widgets/message_bubble.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onDelete,
  });

  static final _timeFmt = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showOptions(context),
        child: Container(
          margin: EdgeInsets.only(
            left: isMine ? 64 : 8,
            right: isMine ? 8 : 64,
            bottom: 4,
          ),
          child: message.isImage
              ? _ImageBubble(message: message, isMine: isMine)
              : _TextBubble(message: message, isMine: isMine),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            if (!message.isImage)
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.white60),
                title: const Text('Copy', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied!'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title: const Text('Delete',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Text bubble ───────────────────────────────────────────────────────────────
class _TextBubble extends StatelessWidget {
  final Message message;
  final bool isMine;

  const _TextBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMine ? const Color(0xFF005C4B) : const Color(0xFF1F2C34),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isMine ? const Radius.circular(16) : const Radius.circular(4),
          bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            MessageBubble._timeFmt.format(message.timestamp),
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image bubble ──────────────────────────────────────────────────────────────
class _ImageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;

  const _ImageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final url = AppConstants.imageUrl(message.content);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft:
              isMine ? const Radius.circular(16) : const Radius.circular(4),
          bottomRight:
              isMine ? const Radius.circular(4) : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _openFullScreen(context, url),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 220,
                height: 220,
                color: const Color(0xFF1F2C34),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF25D366),
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 220,
                height: 80,
                color: const Color(0xFF1F2C34),
                child: const Icon(Icons.broken_image_outlined,
                    color: Colors.white30),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 8,
            child: Text(
              MessageBubble._timeFmt.format(message.timestamp),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreen(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url),
            ),
          ),
        ),
      ),
    );
  }
}
