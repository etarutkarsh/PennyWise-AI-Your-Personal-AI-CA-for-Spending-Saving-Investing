import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/services/app_services.dart';
import '../../../../../core/theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Message> _messages = [];
  bool _loading = false;
  bool _typing = false;
  String? _openAiKey;

  static const _suggestions = [
    'How can I save more this month?',
    'Should I invest in mutual funds?',
    'What\'s the 50-30-20 rule?',
    'How do I build an emergency fund?',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final token = await AppServices.instance.tokenStorage.accessToken;
      if (token == null) return;
      final resp = await Dio().get(
        '${ApiConstants.baseUrl}/ai/chat/history',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final history = (resp.data as List?) ?? [];
      if (mounted) {
        setState(() {
          _messages.addAll(history.map((m) => _Message(
                text: m['message'] as String? ?? '',
                isUser: m['role'] == 'user',
              )));
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _msgCtrl.text).trim();
    if (text.isEmpty || _loading) return;
    _msgCtrl.clear();
    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _typing = true;
      _loading = true;
    });
    _scrollToBottom();

    try {
      final token = await AppServices.instance.tokenStorage.accessToken;
      final resp = await Dio().post(
        '${ApiConstants.baseUrl}/ai/chat',
        data: {'message': text, if (_openAiKey != null) 'openAiKey': _openAiKey},
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      final reply = resp.data['response'] as String? ?? '…';
      if (mounted) {
        setState(() {
          _messages.add(_Message(text: reply, isUser: false));
          _typing = false;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_Message(
              text: 'Could not reach AI. Check your connection and try again.',
              isUser: false,
              isError: true));
          _typing = false;
          _loading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showKeyDialog() {
    final ctrl = TextEditingController(text: _openAiKey ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('OpenAI Key',
            style: GoogleFonts.dmSans(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          style: GoogleFonts.dmSans(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'sk-...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () {
                setState(() => _openAiKey = ctrl.text.trim());
                Navigator.pop(ctx);
              },
              child: Text('Save',
                  style: GoogleFonts.dmSans(
                      color: AppColors.orange, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ask AI',
                          style: GoogleFonts.dmSans(
                              color: AppColors.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w800)),
                      Text('Your financial CA',
                          style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showKeyDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.key_outlined,
                              color: _openAiKey != null
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              size: 16),
                          const SizedBox(width: 6),
                          Text('API Key',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Messages
            Expanded(
              child: _messages.isEmpty
                  ? _EmptyState(onSuggestionTap: _send, suggestions: _suggestions)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _messages.length + (_typing ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _messages.length) {
                          return const _TypingBubble();
                        }
                        return _MessageBubble(msg: _messages[i]);
                      },
                    ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(
                    top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary, fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Ask anything about your money…',
                        hintStyle: GoogleFonts.dmSans(
                            color: AppColors.textMuted, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _send(),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _loading ? AppColors.border : AppColors.orange,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _loading
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textSecondary),
                              ),
                            )
                          : const Icon(Icons.arrow_upward_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message {
  const _Message(
      {required this.text, required this.isUser, this.isError = false});
  final String text;
  final bool isUser;
  final bool isError;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final _Message msg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppColors.orange
              : msg.isError
                  ? AppColors.danger.withValues(alpha: 0.12)
                  : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 18),
          ),
          border: msg.isUser
              ? null
              : Border.all(color: AppColors.border),
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.dmSans(
            color: msg.isUser
                ? Colors.white
                : msg.isError
                    ? AppColors.danger
                    : AppColors.textPrimary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 3; i++) ...[
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: AppColors.textSecondary,
                      shape: BoxShape.circle)),
              if (i < 2) const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.onSuggestionTap, required this.suggestions});
  final void Function(String) onSuggestionTap;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.psychology_outlined,
                color: AppColors.orange, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            'Your AI Financial CA',
            style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask anything about saving, investing, or budgeting.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Text('Try asking:',
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...suggestions.map((s) => GestureDetector(
                onTap: () => onSuggestionTap(s),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(s,
                            style: GoogleFonts.dmSans(
                                color: AppColors.textPrimary,
                                fontSize: 14)),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.textMuted, size: 14),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
