import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/services/app_services.dart';
import '../../../../../core/theme/app_colors.dart';

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
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _loadingHistory = true;
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _checkKey();
  }

  Future<void> _checkKey() async {
    final has = await AppServices.instance.ai.hasKey();
    if (mounted) setState(() => _hasKey = has);
  }

  Future<void> _loadHistory() async {
    try {
      final res = await AppServices.instance.apiClient.dio.get(ApiConstants.chatHistory);
      final list = res.data as List;
      if (mounted) {
        setState(() {
          _messages.clear();
          if (list.isEmpty) {
            _messages.add(const _ChatMessage(
              'Hi! I\'m PennyWise, your AI personal finance CA. '
              'Ask me anything — "Should I invest in gold?", '
              '"How do I build an emergency fund?", '
              '"Can I afford a MacBook Pro?"',
              false,
            ));
          } else {
            for (final m in list) {
              _messages.add(_ChatMessage(m['message'] as String, m['role'] == 'user'));
            }
          }
          _loadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingHistory = false;
          _messages.add(const _ChatMessage(
            'Hi! I\'m PennyWise, your AI personal finance CA. Ask me anything!',
            false,
          ));
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text, true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final key = await AppServices.instance.ai.hasKey()
          ? await AppServices.instance.ai.getStoredKey()
          : null;

      final res = await AppServices.instance.apiClient.dio.post(
        ApiConstants.chat,
        data: {'message': text},
        options: key != null ? Options(headers: {'X-OpenAI-Key': key}) : null,
      );
      final reply = res.data['message'] as String;
      if (mounted) setState(() => _messages.add(_ChatMessage(reply, false)));
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add(const _ChatMessage(
            'Sorry, I couldn\'t get a response. Check your connection and try again.',
            false)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask PennyWise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('About AI Chat'),
                content: const Text(
                    'PennyWise answers financial questions using your spending, '
                    'goals, and salary as context.\n\n'
                    'Add your OpenAI key in Settings → AI Assistant to enable it.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it')),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loadingHistory) const LinearProgressIndicator(minHeight: 2),
          if (!_loadingHistory && !_hasKey)
            _NoKeyBanner(onSetKey: () async {
              await context.push('/settings');
              _checkKey();
            }),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return const _TypingIndicator();
                return _MessageBubble(msg: _messages[index]);
              },
            ),
          ),
          _InputBar(controller: _controller, onSend: _send, isLoading: _isLoading),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final _ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: msg.fromUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(msg.fromUser ? 14 : 4),
            bottomRight: Radius.circular(msg.fromUser ? 4 : 14),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.fromUser ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 40, child: LinearProgressIndicator(minHeight: 2, color: AppColors.primary)),
            SizedBox(width: 8),
            Text('PennyWise is thinking…',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend, required this.isLoading});
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.15))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask a financial question…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isLoading ? null : onSend,
              icon: isLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoKeyBanner extends StatelessWidget {
  const _NoKeyBanner({required this.onSetKey});
  final VoidCallback onSetKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.accent.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.key_rounded, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Add your OpenAI key to enable AI responses',
              style: TextStyle(fontSize: 12, color: AppColors.accent),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onSetKey,
            child: const Text('Add key',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}
