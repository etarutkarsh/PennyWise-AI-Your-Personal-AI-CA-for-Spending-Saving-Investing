import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Feature 10 - AI Financial Assistant. Chat UI over the (future) LLM-backed
/// /ai/chat endpoint; ChatHistory rows are persisted server-side for context.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMessage {
  const _ChatMessage(this.text, this.fromUser);
  final String text;
  final bool fromUser;
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage('Hi! Ask me things like "Can I buy a PS5?" or "Should I invest in gold?"', false),
  ];

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text, true));
      // TODO: POST to /ai/chat with the message + retrieve a streamed reply.
      _messages.add(const _ChatMessage(
        "This is a placeholder reply - wire this up to the LLM-backed /ai/chat endpoint.",
        false,
      ));
    });
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask PennyWise')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: msg.fromUser ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(color: msg.fromUser ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Ask a question...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
