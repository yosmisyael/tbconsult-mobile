import 'package:flutter/material.dart';

import 'package:TBConsult/core/theme/app_colors.dart';
import 'package:TBConsult/features/treatment/domain/entities/dashboard_entity.dart';

/// Swipeable carousel of progress rings — one card per active journey.
/// If there is only one journey the page indicator is hidden.
class TreatmentProgressCard extends StatefulWidget {
  final List<JourneyDashboardItem> items;

  const TreatmentProgressCard({super.key, required this.items});

  @override
  State<TreatmentProgressCard> createState() => _TreatmentProgressCardState();
}

class _TreatmentProgressCardState extends State<TreatmentProgressCard> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const _EmptyProgressCard();

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) =>
                _ProgressRingCard(item: widget.items[i]),
          ),
        ),
        if (widget.items.length > 1) ...[
          const SizedBox(height: 12),
          _PageDots(count: widget.items.length, current: _page),
        ],
      ],
    );
  }
}

// ── Single ring card ─────────────────────────────────────────────────────────

class _ProgressRingCard extends StatefulWidget {
  final JourneyDashboardItem item;
  const _ProgressRingCard({required this.item});

  @override
  State<_ProgressRingCard> createState() => _ProgressRingCardState();
}

class _ProgressRingCardState extends State<_ProgressRingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(begin: 0, end: widget.item.progressFraction)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_ProgressRingCard old) {
    super.didUpdateWidget(old);
    if (old.item.progressFraction != widget.item.progressFraction) {
      _anim = Tween<double>(
          begin: _anim.value, end: widget.item.progressFraction)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Ring ──────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              width: 130,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _anim.value,
                    strokeWidth: 11,
                    backgroundColor: const Color(0xFFD4F0ED),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(_anim.value * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text(
                        'Complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // ── Info ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.journey.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  item.phaseLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                _StatRow(
                  icon: Icons.local_fire_department,
                  color: Colors.deepOrange,
                  label: '${item.stats.currentStreak} hari streak',
                ),
                const SizedBox(height: 6),
                _StatRow(
                  icon: item.stats.onTrack
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color:
                  item.stats.onTrack ? AppColors.primary : Colors.orange,
                  label: item.stats.onTrack ? 'On track' : 'Perlu perhatian',
                ),
                const SizedBox(height: 6),
                _StatRow(
                  icon: Icons.calendar_today_outlined,
                  color: AppColors.textSecondary,
                  label: '${item.stats.daysElapsed} hari berlalu'
                      '${item.stats.daysRemaining != null ? ' · ${item.stats.daysRemaining} tersisa' : ''}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Page dots ────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color:
            active ? AppColors.primary : AppColors.primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Empty state card ─────────────────────────────────────────────────────────

class _EmptyProgressCard extends StatelessWidget {
  const _EmptyProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.medication_outlined,
              size: 48, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text(
            'Belum ada rencana pengobatan aktif',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
