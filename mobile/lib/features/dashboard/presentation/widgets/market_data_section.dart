import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/market_data_service.dart';

// Pre-computed formatters — never re-created per frame.
final _fmtIN = NumberFormat('#,##,###.##', 'en_IN');
final _fmtUS = NumberFormat('#,###.##', 'en_IN');

class MarketDataSection extends StatelessWidget {
  const MarketDataSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketItem>>(
      stream: MarketDataService().stream,
      initialData: MarketDataService().currentItems,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Markets',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _LiveBadge(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _MarketCard(item: items[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Live Badge ───────────────────────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.5 + _pulse.value * 0.5),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: GoogleFonts.dmSans(
              color: AppColors.success,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Market Card ──────────────────────────────────────────────────────────────

class _MarketCard extends StatefulWidget {
  final MarketItem item;
  const _MarketCard({required this.item});

  @override
  State<_MarketCard> createState() => _MarketCardState();
}

class _MarketCardState extends State<_MarketCard> {
  double _scale = 1.0;

  @override
  void didUpdateWidget(_MarketCard old) {
    super.didUpdateWidget(old);
    if (old.item.price != widget.item.price) {
      _triggerPriceAnimation();
    }
  }

  Future<void> _triggerPriceAnimation() async {
    if (!mounted) return;
    setState(() => _scale = 1.04);
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _scale = 1.0);
  }

  String _formatPrice(double price) {
    if (price >= 10000) return _fmtIN.format(price);
    if (price >= 100) return _fmtUS.format(price);
    return price.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final changeColor = item.isUp ? AppColors.success : AppColors.danger;
    final changePrefix = item.isUp ? '▲' : '▼';

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        width: 140,
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.symbol,
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$changePrefix ${item.changePercent.abs().toStringAsFixed(2)}%',
                  style: GoogleFonts.dmSans(
                    color: changeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              item.name,
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _formatPrice(item.price),
              style: GoogleFonts.manrope(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
