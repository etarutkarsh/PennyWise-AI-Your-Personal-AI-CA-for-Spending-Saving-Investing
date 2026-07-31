import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

// ─── Constants ─────────────────────────────────────────────────────────────
const _kEmailSupport   = 'support@pennywise.ai';
const _kEmailBusiness  = 'business@pennywise.ai';
const _kEmailInvestors = 'investors@pennywise.ai';
const _kEmailCareers   = 'careers@pennywise.ai';
const _kEmailPress     = 'press@pennywise.ai';
const _kEmailPrivacy   = 'privacy@pennywise.ai';
const _kLinkedIn       = 'https://linkedin.com/company/pennywise-ai';
const _kTwitter        = 'https://twitter.com/pennywiseai';
const _kGitHub         = 'https://github.com/etarutkarsh';
const _kInstagram      = 'https://instagram.com/pennywiseai';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heroController;
  late final Animation<double> _heroFade;

  // Form state
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String? _category;
  bool _isLoading = false;
  bool _isSuccess = false;

  static const _categories = [
    'General Question',
    'Technical Issue',
    'Bug Report',
    'Feature Request',
    'Billing',
    'Partnership',
    'Investor Inquiry',
    'Media',
    'Career',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      _formKey.currentState!.reset();
      _nameCtrl.clear();
      _emailCtrl.clear();
      _subjectCtrl.clear();
      _messageCtrl.clear();
      setState(() => _category = null);
    }
  }

  void _copyEmail(String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $email'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showUrl(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(url, style: const TextStyle(fontSize: 12)),
        backgroundColor: AppColors.indigo,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(),
            _buildContactOptions(),
            _buildContactForm(),
            _buildLocation(),
            _buildSocialLinks(),
            _buildFAQ(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ─── SECTION 1: HERO ────────────────────────────────────────────────────

  Widget _buildHero() {
    return FadeTransition(
      opacity: _heroFade,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1B4B),
              AppColors.indigo,
              AppColors.blue,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blue.withValues(alpha: 0.2),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 24),
                    Text(
                      "We'd Love To\nHear From You",
                      style: GoogleFonts.dmSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Questions, feedback, partnerships, or just saying hello — we read every message.',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Pill badges horizontal scroll
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          'Questions',
                          'Feedback',
                          'Bug Reports',
                          'Partnerships',
                          'Media',
                          'Investors',
                          'Careers',
                        ]
                            .map((t) => _heroPill(t))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroPill(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          )),
    );
  }

  // ─── SECTION 2: CONTACT OPTIONS ─────────────────────────────────────────

  Widget _buildContactOptions() {
    final options = <(List<Color>, IconData, String, String)>[
      (
        [AppColors.orange, const Color(0xFFFF8C42)],
        Icons.support_agent_rounded,
        'General Support',
        _kEmailSupport
      ),
      (
        [AppColors.blue, const Color(0xFF06B6D4)],
        Icons.business_rounded,
        'Business',
        _kEmailBusiness
      ),
      (
        [AppColors.indigo, AppColors.violet],
        Icons.trending_up_rounded,
        'Investors',
        _kEmailInvestors
      ),
      (
        [const Color(0xFF059669), AppColors.success],
        Icons.work_rounded,
        'Careers',
        _kEmailCareers
      ),
      (
        [AppColors.amber, AppColors.orange],
        Icons.campaign_rounded,
        'Press',
        _kEmailPress
      ),
      (
        [AppColors.violet, AppColors.indigo],
        Icons.privacy_tip_rounded,
        'Privacy',
        _kEmailPrivacy
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Contact Options'),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: options
                .map((o) => _contactCard(
                      o.$1,
                      o.$2,
                      o.$3,
                      o.$4,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(
      List<Color> gradient, IconData icon, String label, String email) {
    return GestureDetector(
      onTap: () => _copyEmail(email),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const Spacer(),
            Text(label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 2),
            Text(email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                )),
            const SizedBox(height: 2),
            Text('Tap to copy',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: AppColors.orange,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  // ─── SECTION 3: CONTACT FORM ─────────────────────────────────────────────

  Widget _buildContactForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Send a Message'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(20),
            child: _isSuccess ? _buildSuccessState() : _buildFormFields(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: Column(
        children: [
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 64,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('Message Sent!',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          Text(
            "We've received your message and will get back to you within 24 hours on business days.",
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => setState(() => _isSuccess = false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.orange),
            ),
            child: Text('Send Another Message',
                style: GoogleFonts.dmSans(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w600,
                )),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _formField(
            controller: _nameCtrl,
            label: 'Full Name',
            hint: 'John Doe',
            icon: Icons.person_outline_rounded,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),
          _formField(
            controller: _emailCtrl,
            label: 'Email Address',
            hint: 'john@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
              if (!regex.hasMatch(v.trim())) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Category dropdown
          DropdownButtonFormField<String>(
            initialValue: _category,
            dropdownColor: AppColors.surfaceElevated,
            decoration: _inputDecoration('Category', Icons.category_rounded),
            hint: Text('Select a category',
                style: GoogleFonts.dmSans(
                    color: AppColors.textMuted, fontSize: 14)),
            items: _categories
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: GoogleFonts.dmSans(
                              color: AppColors.textPrimary, fontSize: 14)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _category = v),
            validator: (v) =>
                v == null ? 'Please select a category' : null,
          ),
          const SizedBox(height: 14),
          _formField(
            controller: _subjectCtrl,
            label: 'Subject',
            hint: 'Brief summary of your message',
            icon: Icons.subject_rounded,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Subject is required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _messageCtrl,
            maxLines: 6,
            style: GoogleFonts.dmSans(
                color: AppColors.textPrimary, fontSize: 14),
            decoration: _inputDecoration(
                'Message', Icons.chat_bubble_outline_rounded,
                hint: 'Tell us how we can help you...'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Message is required';
              if (v.trim().length < 10) {
                return 'Message must be at least 10 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Attachment row
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attachments coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.attach_file_rounded, size: 18),
            label: Text('Attach File (optional)',
                style: GoogleFonts.dmSans(fontSize: 13)),
          ),
          const SizedBox(height: 20),
          // Send button
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('Send Message',
                    style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14),
      decoration: _inputDecoration(label, icon, hint: hint),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
      labelStyle:
          GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13),
      hintStyle:
          GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13),
      filled: true,
      fillColor: AppColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  // ─── SECTION 4: LOCATION ─────────────────────────────────────────────────

  Widget _buildLocation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Our Office'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Abstract map CustomPainter
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: CustomPaint(
                    size: const Size(double.infinity, 175),
                    painter: _AbstractMapPainter(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.orange, AppColors.amber],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Headquarters',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                )),
                            const SizedBox(height: 3),
                            Text('Remote First Company 🇮🇳',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                )),
                            Text('India',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                )),
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

  // ─── SECTION 5: SOCIAL LINKS ─────────────────────────────────────────────

  Widget _buildSocialLinks() {
    final socials = <(List<Color>, IconData, String, String)>[
      (
        [AppColors.blue, const Color(0xFF0077B5)],
        Icons.linked_camera_rounded,
        'LinkedIn',
        _kLinkedIn
      ),
      (
        [const Color(0xFF1DA1F2), AppColors.blue],
        Icons.flutter_dash_rounded,
        'Twitter/X',
        _kTwitter
      ),
      (
        [const Color(0xFF333333), const Color(0xFF555555)],
        Icons.code_rounded,
        'GitHub',
        _kGitHub
      ),
      (
        [const Color(0xFFE1306C), const Color(0xFFF77737)],
        Icons.camera_alt_rounded,
        'Instagram',
        _kInstagram
      ),
      (
        [const Color(0xFFFF0000), const Color(0xFFCC0000)],
        Icons.play_circle_rounded,
        'YouTube',
        'https://youtube.com/@pennywiseai'
      ),
      (
        [AppColors.orange, AppColors.amber],
        Icons.language_rounded,
        'Website',
        'https://pennywise.ai'
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Follow Us'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: socials
                .map((s) => _socialButton(
                      s.$1,
                      s.$2,
                      s.$3,
                      s.$4,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _socialButton(
      List<Color> gradient, IconData icon, String label, String url) {
    return GestureDetector(
      onTap: () => _showUrl(url),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  // ─── SECTION 6: FAQ ──────────────────────────────────────────────────────

  Widget _buildFAQ() {
    final faqs = [
      (
        'How secure is my data?',
        'All data is encrypted using AES-256-GCM. Your financial information never leaves your control and is never sold to third parties.'
      ),
      (
        'Can I delete my account?',
        'Yes. You can delete your account and all associated data at any time from Settings → Privacy. We process deletion requests within 30 days.'
      ),
      (
        'How do AI recommendations work?',
        'PennyWise AI analyzes your spending patterns, goals, and financial health score to generate personalized insights. AI runs on our secure backend — your raw data is never sent to third-party AI services without your consent.'
      ),
      (
        'Is PennyWise free?',
        'The core features are free. Premium features including AI Tax Filing, Account Aggregator sync, and advanced AI insights will be available as a subscription.'
      ),
      (
        'How do I contact support?',
        'Email us at support@pennywise.ai or use the contact form above. We typically respond within 24 hours on business days.'
      ),
      (
        'When will tax filing be available?',
        "ITD ERI Type-2 integration is on our roadmap for 2027. We'll notify you in-app as soon as it's available."
      ),
      (
        'How do bank integrations work?',
        'We use RBI-regulated Account Aggregator technology. You authorize data sharing via OTP — we never ask for banking credentials.'
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Frequently Asked Questions'),
          const SizedBox(height: 16),
          ...faqs.map((faq) => _faqTile(faq.$1, faq.$2)),
        ],
      ),
    );
  }

  Widget _faqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: AppColors.orange,
          collapsedIconColor: AppColors.textMuted,
          title: Text(question,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          children: [
            Text(answer,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.6,
                )),
          ],
        ),
      ),
    );
  }

  // ─── SECTION 7: FOOTER ───────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 28, 20, 32),
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
                  fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Privacy Policy coming soon'),
                        behavior: SnackBarBehavior.floating),
                  );
                },
                child: Text('Privacy Policy',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.blue)),
              ),
              Text('  ·  ',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textMuted)),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Terms of Service coming soon'),
                        behavior: SnackBarBehavior.floating),
                  );
                },
                child: Text('Terms of Service',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Made with ❤️ in India',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('© 2026 PennyWise AI. All rights reserved.',
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // ─── SHARED HELPERS ──────────────────────────────────────────────────────

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

// ─── CUSTOM PAINTER: Abstract Map ───────────────────────────────────────────

class _AbstractMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F1729),
          Color(0xFF1A1F2E),
          Color(0xFF111827),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Abstract map shapes (stylized India-like regions)
    final regionPaint = Paint()
      ..color = AppColors.indigo.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final regionBorder = Paint()
      ..color = AppColors.indigo.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path1 = Path()
      ..moveTo(size.width * 0.3, size.height * 0.2)
      ..lineTo(size.width * 0.55, size.height * 0.15)
      ..lineTo(size.width * 0.6, size.height * 0.4)
      ..lineTo(size.width * 0.5, size.height * 0.7)
      ..lineTo(size.width * 0.35, size.height * 0.85)
      ..lineTo(size.width * 0.25, size.height * 0.6)
      ..lineTo(size.width * 0.28, size.height * 0.35)
      ..close();
    canvas.drawPath(path1, regionPaint);
    canvas.drawPath(path1, regionBorder);

    final path2 = Path()
      ..moveTo(size.width * 0.6, size.height * 0.1)
      ..lineTo(size.width * 0.8, size.height * 0.2)
      ..lineTo(size.width * 0.75, size.height * 0.5)
      ..lineTo(size.width * 0.6, size.height * 0.4)
      ..close();
    final regionPaint2 = Paint()
      ..color = AppColors.blue.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path2, regionPaint2);
    canvas.drawPath(path2, regionBorder);

    // Location pin
    final pinX = size.width * 0.42;
    final pinY = size.height * 0.45;
    final pinPaint = Paint()
      ..shader = const LinearGradient(
              colors: [AppColors.orange, AppColors.amber])
          .createShader(
              Rect.fromCircle(center: Offset(pinX, pinY), radius: 12));
    canvas.drawCircle(Offset(pinX, pinY), 8, pinPaint);
    canvas.drawCircle(Offset(pinX, pinY), 14,
        Paint()..color = AppColors.orange.withValues(alpha: 0.2));
    canvas.drawCircle(Offset(pinX, pinY), 22,
        Paint()..color = AppColors.orange.withValues(alpha: 0.08));

    // Dot markers
    final dotPaint = Paint()..color = AppColors.blue.withValues(alpha: 0.6);
    for (final p in [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.35),
      Offset(size.width * 0.5, size.height * 0.65),
      Offset(size.width * 0.15, size.height * 0.7),
      Offset(size.width * 0.8, size.height * 0.6),
    ]) {
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
