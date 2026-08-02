import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/services/app_services.dart';
import '../../../../../core/services/chat_context_builder.dart';
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

  ChatContext? _ctx;
  bool _ctxLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContext();
    _loadHistory();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    final ctx = await ChatContextBuilder.build();
    if (mounted) setState(() { _ctx = ctx; _ctxLoading = false; });
  }

  Future<void> _loadHistory() async {
    try {
      final history = await AppServices.instance.ai.getChatHistory();
      if (mounted) {
        setState(() {
          _messages.addAll(history
              .where((m) {
                final text = m['message'] as String? ?? '';
                return !text.startsWith('[Context:') && m['role'] != 'system';
              })
              .map((m) => _Message(
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
      final String reply;
      final ctx = _ctx;
      if (ctx != null && ctx.systemPrompt.isNotEmpty) {
        reply = await AppServices.instance.ai
            .sendWithContext(text, ctx.systemPrompt);
      } else {
        reply = await AppServices.instance.ai.sendMessage(text);
      }
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
          _messages.add(const _Message(
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

  List<String> get _suggestions =>
      _ctx?.suggestions ?? ChatContext.fallback.suggestions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(ctxLoading: _ctxLoading, ctx: _ctx),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: _messages.isEmpty
                  ? _EmptyState(
                      onSuggestionTap: _send,
                      suggestions: _suggestions,
                      ctxLoading: _ctxLoading,
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      itemCount: _messages.length + (_typing ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _messages.length) {
                          return const _TypingBubble();
                        }
                        return _MessageBubble(msg: _messages[i]);
                      },
                    ),
            ),
            _InputBar(
              controller: _msgCtrl,
              loading: _loading,
              onSend: () => _send(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.ctxLoading, required this.ctx});
  final bool ctxLoading;
  final ChatContext? ctx;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask AI',
                  style: GoogleFonts.manrope(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                // Context status pill
                if (ctxLoading)
                  Row(
                    children: [
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Loading your finances…',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  )
                else if (ctx != null &&
                    ctx!.statusLabel != 'Generic mode')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          ctx!.statusLabel,
                          style: GoogleFonts.dmSans(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Your personal financial CA',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          // AI badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.psychology_outlined,
                    size: 13, color: AppColors.orange),
                const SizedBox(width: 4),
                Text(
                  'GPT-4o',
                  style: GoogleFonts.dmSans(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.loading,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary, fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Ask about your money…',
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
            onTap: loading ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: loading ? AppColors.border : AppColors.orange,
                borderRadius: BorderRadius.circular(14),
              ),
              child: loading
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
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

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
      alignment:
          msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            height: 1.55,
          ),
        ),
      ),
    );
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (_ctrl.value + i / 3) % 1.0;
                final scale = 0.6 + 0.4 * (1 - (2 * t - 1).abs());
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted
                            .withValues(alpha: 0.4 + 0.6 * scale),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ── Empty / Welcome State ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onSuggestionTap,
    required this.suggestions,
    required this.ctxLoading,
  });
  final void Function(String) onSuggestionTap;
  final List<String> suggestions;
  final bool ctxLoading;

  static const _capabilities = [
    (Icons.savings_outlined, AppColors.success, 'Savings & Emergency Fund',
        'How much to save, when to pause, where to park it'),
    (Icons.trending_up_rounded, AppColors.orange, 'Investments & SIP',
        'Mutual funds, index funds, SIP calculations, risk profiling'),
    (Icons.account_balance_wallet_outlined, AppColors.primary, 'Budgeting',
        '50-30-20, zero-based budgeting, cutting unnecessary spend'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Hero banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.orange.withValues(alpha: 0.14),
                  const Color(0xFF6A1B9A).withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.psychology_outlined,
                      color: AppColors.orange, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ctxLoading
                            ? 'Loading your context…'
                            : 'Ready for your questions',
                        style: GoogleFonts.manrope(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ctxLoading
                            ? 'Fetching your transactions, goals and health score'
                            : 'Personalised to your actual finances',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Capabilities
          Text(
            'What I can help with',
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          ..._capabilities.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.$2.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(c.$1, color: c.$2, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.$3,
                              style: GoogleFonts.dmSans(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(height: 2),
                          Text(c.$4,
                              style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 22),

          Row(
            children: [
              Text(
                ctxLoading ? 'Loading suggestions…' : 'Try asking',
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              if (!ctxLoading) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Personalised',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          if (ctxLoading)
            // Skeleton placeholders
            ...List.generate(
              4,
              (i) => Container(
                height: 46,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
              ),
            )
          else
            ...suggestions.map((s) => _SuggestionChip(
                  text: s,
                  onTap: () => onSuggestionTap(s),
                )),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  const _SuggestionChip({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? AppColors.orange.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.orange.withValues(alpha: 0.7), size: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.text,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: _hovered ? AppColors.orange : AppColors.textMuted,
                  size: 13),
            ],
          ),
        ),
      ),
    );
  }
}
