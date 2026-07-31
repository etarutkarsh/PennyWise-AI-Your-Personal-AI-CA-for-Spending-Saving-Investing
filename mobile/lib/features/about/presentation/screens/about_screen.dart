import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _fadeController;

  final List<bool> _timelineVisible = List.filled(10, false);

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _animateTimeline();
  }

  void _animateTimeline() {
    for (int i = 0; i < _timelineVisible.length; i++) {
      Future.delayed(Duration(milliseconds: 300 + i * 150), () {
        if (mounted) setState(() => _timelineVisible[i] = true);
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(child: _buildOurStory()),
            SliverToBoxAdapter(child: _buildMissionCards()),
            SliverToBoxAdapter(child: _buildTimeline()),
            SliverToBoxAdapter(child: _buildWhyCards()),
            SliverToBoxAdapter(child: _buildValues()),
            SliverToBoxAdapter(child: _buildSecurity()),
            SliverToBoxAdapter(child: _buildRoadmap()),
            SliverToBoxAdapter(child: _buildTeam()),
            SliverToBoxAdapter(child: _buildFooter()),
          ],
        ),
      ),
    );
  }

  // ─── SECTION 1: HERO ──────────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      height: 360,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1B4B),
            AppColors.indigo,
            AppColors.blue,
            AppColors.violet,
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violet.withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue.withValues(alpha: 0.2),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.glassWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                  const Spacer(),
                  // Shimmer title
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: const [
                              Colors.white,
                              Color(0xFFFFB830),
                              Colors.white,
                              Color(0xFF93C5FD),
                              Colors.white,
                            ],
                            stops: [
                              0.0,
                              (_shimmerController.value - 0.1)
                                  .clamp(0.0, 1.0),
                              _shimmerController.value.clamp(0.0, 1.0),
                              (_shimmerController.value + 0.1)
                                  .clamp(0.0, 1.0),
                              1.0,
                            ],
                          ).createShader(bounds);
                        },
                        child: Text(
                          'PennyWise AI',
                          style: GoogleFonts.dmSans(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Personal AI Financial Operating System',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Glassmorphism trust card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.glassWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _trustChip(Icons.auto_awesome_rounded, 'Trusted AI'),
                            _dividerDot(),
                            _trustChip(Icons.lock_rounded, 'Private'),
                            _dividerDot(),
                            _trustChip(Icons.verified_rounded, 'Secure'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _dividerDot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Text('·', style: TextStyle(color: Colors.white54, fontSize: 16)),
    );
  }

  // ─── SECTION 2: OUR STORY ─────────────────────────────────────────────────

  Widget _buildOurStory() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Our Story'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: const Border(
                left: BorderSide(color: AppColors.orange, width: 4),
                top: BorderSide(color: AppColors.border, width: 1),
                right: BorderSide(color: AppColors.border, width: 1),
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Text(
              'PennyWise AI was created to solve one simple problem: Managing money is harder than it should be. Millions of people struggle with budgeting, savings, investing, taxes, and understanding their own financial health. Our mission is to make financial management simple, intelligent, and accessible through artificial intelligence.\n\nInstead of forcing users to use multiple apps for banking, investing, budgeting, tax filing, document management, and financial education, PennyWise AI brings everything together into one secure platform. We believe every person deserves access to intelligent financial guidance, regardless of their financial background.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION 3: MISSION CARDS ─────────────────────────────────────────────

  Widget _buildMissionCards() {
    final cards = [
      ('📚', 'Financial Literacy', 'Making complex finance simple for everyone'),
      ('🤖', 'AI Powered Guidance',
          'Smart recommendations based on your unique financial picture'),
      ('💰', 'Smart Saving',
          'Automated savings rules and goal tracking'),
      ('📈', 'Investment Education',
          'Learn before you invest with curated content'),
      ('🏛️', 'Future Tax Automation',
          'AI-powered ITR filing coming soon'),
      ('🔒', 'Privacy First',
          'Your data never leaves your control'),
      ('⚡', 'Automation',
          'Set rules, let PennyWise handle the rest'),
      ('🎯', 'User Control',
          'You decide what data is shared and when'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Our Mission'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((c) => _missionCard(c.$1, c.$2, c.$3)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _missionCard(String emoji, String title, String subtitle) {
    final width = (MediaQuery.of(context).size.width - 52) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.indigo, AppColors.violet],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(title,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.4,
                )),
          ],
        ),
      ),
    );
  }

  // ─── SECTION 4: TIMELINE ──────────────────────────────────────────────────

  Widget _buildTimeline() {
    final items = [
      ('Today', 'Budgeting & Expense Tracking'),
      ('Now', 'AI Spending Insights'),
      ('Soon', 'Goals & Investment Education'),
      ('Q3 2025', 'Investment Portfolio Tracking'),
      ('Q4 2025', 'Document Vault'),
      ('Q2 2026', 'Account Aggregator Integration'),
      ('Q3 2026', 'AI Tax Assistant'),
      ('2027', 'Income Tax Filing (ITR)'),
      ('2028', 'Financial Digital Twin'),
      ('Vision', "India's Financial Operating System"),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Our Vision'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: List.generate(items.length, (i) {
                return AnimatedSlide(
                  offset: _timelineVisible[i]
                      ? Offset.zero
                      : const Offset(-0.3, 0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: _timelineVisible[i] ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: _timelineNode(
                      items[i].$1,
                      items[i].$2,
                      isLast: i == items.length - 1,
                      isFirst: i == 0,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineNode(String label, String title,
      {bool isLast = false, bool isFirst = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  gradient: isFirst
                      ? const LinearGradient(
                          colors: [AppColors.orange, AppColors.amber])
                      : const LinearGradient(
                          colors: [AppColors.indigo, AppColors.blue]),
                  shape: BoxShape.circle,
                  boxShadow: isFirst
                      ? [
                          BoxShadow(
                              color: AppColors.orange.withValues(alpha: 0.4),
                              blurRadius: 8)
                        ]
                      : null,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.indigo.withValues(alpha: 0.6),
                        AppColors.border,
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(label,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      )),
                ),
                const SizedBox(height: 4),
                Text(title,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── SECTION 5: WHY PENNYWISE ─────────────────────────────────────────────

  Widget _buildWhyCards() {
    final cards = [
      ('🤖', 'AI Powered', 'Intelligent categorization and spending insights'),
      ('🔐', 'Secure', 'Bank-grade AES-256 encryption'),
      ('🕵️', 'Private', 'Zero data selling, ever'),
      ('✨', 'Easy to Use', 'Designed for everyone, not just finance experts'),
      ('🇮🇳', 'Built for India', 'Indian banks, UPI, ITR, GST — all covered'),
      ('🚀', 'Future Ready',
          'Account Aggregator and ERI integration roadmap'),
      ('🎓', 'Financial Education', 'Learn while you earn and save'),
      ('💎', 'Modern UI', "Premium design that respects your time"),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Why PennyWise'),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: cards
                .map((c) => _whyCard(c.$1, c.$2, c.$3))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _whyCard(String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(title,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 3),
          Text(subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppColors.textSecondary,
                height: 1.4,
              )),
        ],
      ),
    );
  }

  // ─── SECTION 6: VALUES ────────────────────────────────────────────────────

  Widget _buildValues() {
    final values = <(List<Color>, IconData, String, String)>[
      ([AppColors.orange, const Color(0xFFFF8C42)], Icons.visibility_rounded,
          'Transparency', 'Open about what we do with your data'),
      ([AppColors.violet, AppColors.indigo], Icons.lock_rounded,
          'Privacy', 'Your data belongs to you'),
      (
        [AppColors.blue, const Color(0xFF06B6D4)],
        Icons.security_rounded,
        'Security',
        'Bank-grade protection at every layer'
      ),
      ([AppColors.amber, AppColors.orange], Icons.lightbulb_rounded,
          'Innovation', 'Building the future of personal finance'),
      ([const Color(0xFF059669), AppColors.success], Icons.school_rounded,
          'Education', 'Empowering informed financial decisions'),
      ([AppColors.indigo, AppColors.violet], Icons.handshake_rounded,
          'Trust', 'Earned through consistency and honesty'),
      ([AppColors.orange, AppColors.amber], Icons.person_rounded,
          'User First', 'Every feature starts with your needs'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _sectionHeader('Our Values'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: values.length,
              itemBuilder: (context, i) {
                final v = values[i];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient:
                              LinearGradient(colors: v.$1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(v.$2, color: Colors.white, size: 18),
                      ),
                      const SizedBox(height: 12),
                      Text(v.$3,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          )),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(v.$4,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            )),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION 7: SECURITY ──────────────────────────────────────────────────

  Widget _buildSecurity() {
    final items = [
      ('🔐', 'End-to-End Encryption',
          'AES-256-GCM encryption for all data in transit and at rest'),
      ('🛡️', 'Secure Authentication',
          'JWT tokens with secure storage, biometric support coming'),
      ('📁', 'Private Document Vault',
          'Documents never leave your encrypted vault'),
      ('👤', 'User Data Ownership', 'You own your data. Period.'),
      ('✅', 'Consent-Based Sharing',
          'Every data flow requires explicit user approval'),
      ('🚫', 'Zero Credential Sharing',
          'We never ask for or store banking passwords'),
      ('🔗', 'Future AA Integration',
          'RBI-regulated Account Aggregator pipeline coming'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Security & Privacy'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Gradient top border
                Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.blue, AppColors.indigo, AppColors.violet],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ...items.map((item) => _securityItem(
                            item.$1,
                            item.$2,
                            item.$3,
                          )),
                      const Divider(color: AppColors.border, height: 24),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_rounded,
                                color: AppColors.danger, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'We never sell your data. Not today, not ever.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityItem(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION 8: ROADMAP ───────────────────────────────────────────────────

  Widget _buildRoadmap() {
    final items = [
      ('🏦', 'Account Aggregator',
          'Link all your bank accounts seamlessly', 'Q4 2026', 0.65),
      ('🤖', 'AI Tax Assistant',
          'AI-powered tax optimization and advice', 'Q1 2027', 0.40),
      ('📋', 'Income Tax Filing',
          'File ITR directly from the app', 'Q2 2027', 0.25),
      ('📊', 'Health Reports',
          'Deep financial health analytics', 'Q3 2026', 0.80),
      ('👨‍👩‍👧', 'Family Accounts',
          'Manage finances for your whole family', 'Q4 2027', 0.15),
      ('🧠', 'Advanced AI',
          'GPT-4 powered financial copilot', 'Q3 2026', 0.70),
      ('💹', 'Investment Marketplace',
          'Curated mutual funds and ETFs', '2027', 0.20),
      ('🛡️', 'Insurance Marketplace',
          'Compare and buy insurance', '2027', 0.10),
      ('🏖️', 'Retirement Planning',
          'Long-term wealth building', '2027', 0.05),
      ('👤', 'Financial Digital Twin',
          'AI clone of your financial life', '2028', 0.02),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _sectionHeader('Coming Soon'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return _roadmapCard(
                  item.$1,
                  item.$2,
                  item.$3,
                  item.$4,
                  item.$5,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _roadmapCard(String emoji, String title, String subtitle,
      String badge, double progress) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.indigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.indigo.withValues(alpha: 0.3)),
                ),
                child: Text(badge,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 4),
          Expanded(
            child: Text(subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.4,
                )),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progress * 100).toInt()}%',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Stack(
                  children: [
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.orange, AppColors.amber]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION 9: TEAM ──────────────────────────────────────────────────────

  Widget _buildTeam() {
    final roles = [
      ('👨‍💼', 'Founder & CEO'),
      ('⚙️', 'Engineering'),
      ('🤖', 'AI & ML'),
      ('📦', 'Product'),
      ('🎨', 'Design'),
      ('🤝', 'Support'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Our Team'),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: roles.map((r) => _teamCard(r.$1, r.$2)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _teamCard(String emoji, String role) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(role,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text('Growing Team',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    )),
                GestureDetector(
                  onTap: () {},
                  child: Text('Join Us →',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION 10: FOOTER ───────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.orange, AppColors.amber],
            ).createShader(bounds),
            child: Text(
              'PennyWise AI',
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('v0.1.0 (Build 1)',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textMuted,
              )),
          const SizedBox(height: 8),
          Text('Made with ❤️ in India',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 4),
          Text('© 2026 PennyWise AI. All rights reserved.',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.textMuted,
              )),
        ],
      ),
    );
  }

  // ─── SHARED HELPERS ───────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.orange, AppColors.amber],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
      ],
    );
  }
}
