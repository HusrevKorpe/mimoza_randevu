import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cash_entry.dart';
import '../services/cash_repository.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import 'app_card.dart';
import 'dismissible_cash_tile.dart';
import 'list_card.dart';
import 'section_header.dart';
import 'section_placeholder.dart';

/// GİDERLER — the selected month's expenses: a "this month" total hero card on
/// top, then the entries grouped in one panel (newest first), each showing its
/// day. Owns a per-month stream so the total and the list update together from a
/// single Firestore subscription.
class MonthCashSection extends StatefulWidget {
  const MonthCashSection({super.key, required this.month});

  final DateTime month;

  @override
  State<MonthCashSection> createState() => _MonthCashSectionState();
}

class _MonthCashSectionState extends State<MonthCashSection> {
  Stream<List<CashEntry>>? _stream;
  DateTime? _streamMonth;

  @override
  Widget build(BuildContext context) {
    if (_streamMonth != widget.month) {
      _streamMonth = widget.month;
      _stream = context.read<CashRepository>().watchMonth(widget.month);
    }

    return StreamBuilder<List<CashEntry>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _layout(
            total: null,
            count: null,
            body: const _StateCard(
              icon: Icons.error_outline_rounded,
              text: 'Giderler yüklenemedi.',
            ),
          );
        }
        if (!snapshot.hasData) {
          return _layout(
            total: null,
            count: null,
            body: const _StateCard.loading(),
          );
        }
        final items = snapshot.data!;
        final total = items.fold<double>(0, (sum, e) => sum + e.amount);
        return _layout(
          total: total,
          count: items.length,
          body: items.isEmpty
              ? const _StateCard(
                  icon: Icons.account_balance_wallet_outlined,
                  text: 'Bu ay gider yok.',
                )
              : ListCard(
                  children: [
                    for (final e in items)
                      DismissibleCashTile(entry: e, showDate: true),
                  ],
                ),
        );
      },
    );
  }

  /// Hero total + GİDERLER header (with a count) + the list/placeholder body.
  Widget _layout({
    required double? total,
    required int? count,
    required Widget body,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TotalHero(total: total),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: 'GİDERLER',
          trailing: count == null || count == 0
              ? null
              : Text('$count kayıt', style: context.text.helper),
        ),
        body,
      ],
    );
  }
}

/// "BU AYKİ GİDER" with the month's total shown large, plus a soft-blue wallet
/// badge. A null [total] (loading / error) shows a muted dash.
class _TotalHero extends StatelessWidget {
  const _TotalHero({required this.total});

  final double? total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('BU AYKİ GİDER', style: text.topLabel),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  total == null ? '—' : formatTRY(total!),
                  style: text.screenTitle,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.softBlue,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: colors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single-card state for the expense list: a left-aligned muted icon + message,
/// or a centered spinner while loading. Keeps empty/error/loading looking like
/// the list panel they replace.
class _StateCard extends StatelessWidget {
  const _StateCard({required this.icon, required this.text}) : loading = false;

  const _StateCard.loading()
      : icon = null,
        text = null,
        loading = true;

  final IconData? icon;
  final String? text;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: loading
          ? const SectionPlaceholder.loading()
          : SectionPlaceholder(icon: icon, text: text),
    );
  }
}
