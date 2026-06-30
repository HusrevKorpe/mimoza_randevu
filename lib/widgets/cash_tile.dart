import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cash_entry.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';

/// One expense row inside a [ListCard] panel: title on the left, amount on the
/// right — shown plainly, as written (no sign). A flat row (no card of its own);
/// the surrounding panel draws the surface, border and dividers. Tappable for the
/// edit form. Set [showDate] in the monthly list, where the day isn't implied.
class CashTile extends StatelessWidget {
  const CashTile({
    super.key,
    required this.entry,
    this.onTap,
    this.showDate = false,
  });

  final CashEntry entry;
  final VoidCallback? onTap;
  final bool showDate;

  static final DateFormat _dateLabel = DateFormat('d MMMM', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title.isEmpty ? '—' : entry.title,
                    style: text.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showDate) ...[
                    const SizedBox(height: 2),
                    Text(
                      _dateLabel.format(entry.date),
                      style: text.helper,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(formatTRY(entry.amount), style: text.dayTitle),
          ],
        ),
      ),
    );
  }
}
