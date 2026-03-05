// lib/widgets/bottom_bar.dart
import 'package:flutter/material.dart';

class ChatBottomBar extends StatefulWidget {
  final void Function(String text) onSend;
  final VoidCallback onAttach;
  final bool isSending;

  const ChatBottomBar({
    super.key,
    required this.onSend,
    required this.onAttach,
    this.isSending = false,
  });

  @override
  State<ChatBottomBar> createState() => _ChatBottomBarState();
}

class _ChatBottomBarState extends State<ChatBottomBar> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111B21),
        border: Border(top: BorderSide(color: Color(0xFF1F2C34), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Attachment button ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: widget.isSending
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF25D366),
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: widget.onAttach,
                      icon: const Icon(Icons.attach_file_rounded),
                      color: Colors.white38,
                      padding: EdgeInsets.zero,
                    ),
            ),

            // ── Text field ────────────────────────────────────────────
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: const TextStyle(color: Color(0xFF8696A0)),
                    filled: true,
                    fillColor: const Color(0xFF1F2C34),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (v) {}, // multi-line: Enter = newline
                ),
              ),
            ),

            const SizedBox(width: 6),

            // ── Send button ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: _hasText
                    ? GestureDetector(
                        key: const ValueKey('send'),
                        onTap: _send,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                        ),
                      )
                    : GestureDetector(
                        key: const ValueKey('mic'),
                        onTap: () {}, // placeholder
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1F2C34),
                          ),
                          child: const Icon(Icons.mic_rounded,
                              color: Colors.white38, size: 22),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
