import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../state/chatbot_controller.dart';

class ChatbotSheet extends StatefulWidget {
  const ChatbotSheet({super.key});

  @override
  State<ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends State<ChatbotSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ChatbotController>().loadWelcomeMessage();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text;
    _controller.clear();

    await context.read<ChatbotController>().sendMessage(text);

    if (!_scrollController.hasClients) return;
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatbotController>(
      builder: (context, controller, _) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'UniRide Assistant',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3E3E3E),
                    ),
                  ),
                  const Spacer(),
                  if (controller.isSyncing)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),

              // ── Offline banner ────────────────────────────────────────────
              if (controller.isOffline)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        size: 14,
                        color: Color(0xFF92400E),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Sin conexión — los mensajes se enviarán al reconectar',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Message list ──────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    return _MessageBubble(message: message);
                  },
                ),
              ),

              // ── Error label ───────────────────────────────────────────────
              if (controller.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    controller.errorMessage!,
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),

              // ── Input row ─────────────────────────────────────────────────
              SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: controller.isOffline
                              ? 'Mensaje (se enviará al reconectar)...'
                              : 'Type your message...',
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFF8B8B8B),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F7FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: controller.isSending ? null : _submit,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: controller.isOffline
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF1F5DFF),
                          shape: BoxShape.circle,
                        ),
                        child: controller.isSending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                controller.isOffline
                                    ? Icons.schedule
                                    : Icons.send,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Message bubble with status indicator ──────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF1F5DFF)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isUser ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(height: 3),
              _StatusIndicator(status: message.status),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status});

  final ChatMessageStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ChatMessageStatus.sending => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            const SizedBox(width: 4),
            Text(
              'Enviando…',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ChatMessageStatus.sent => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.done_all, size: 12, color: Color(0xFF1F5DFF)),
            const SizedBox(width: 3),
            Text(
              'Enviado',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ChatMessageStatus.failed => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 12, color: Color(0xFFEF4444)),
            const SizedBox(width: 3),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ChatMessageStatus.pendingSync => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 12, color: Color(0xFFC2410C)),
            const SizedBox(width: 3),
            Text(
              'Pendiente',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFFC2410C),
              ),
            ),
          ],
        ),
    };
  }
}
