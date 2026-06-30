import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/cash_entry.dart';
import '../services/cash_repository.dart';
import '../theme/app_theme.dart';
import 'app_snackbar.dart';
import 'cash_tile.dart';
import 'swipe_delete_background.dart';

/// A [CashTile] wrapped with tap-to-edit and swipe-to-delete, used by the Günlük
/// tab's GİDERLER list. Reads the [CashRepository] from context (the tab
/// provides one) so the delete confirmation lives in one place.
class DismissibleCashTile extends StatelessWidget {
  const DismissibleCashTile({
    super.key,
    required this.entry,
    this.showDate = false,
  });

  final CashEntry entry;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      // Square background: the enclosing ListCard clips it to the panel's
      // rounded corners.
      background: const SwipeDeleteBackground(radius: 0),
      confirmDismiss: (_) => _confirmDelete(context, entry),
      child: CashTile(
        entry: entry,
        showDate: showDate,
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.newCash,
          arguments: entry,
        ),
      ),
    );
  }
}

/// Confirms, then removes via the repository. Always resolves `false` so the
/// live stream — not the [Dismissible] — drives the row's removal.
Future<bool> _confirmDelete(BuildContext context, CashEntry entry) async {
  final messenger = ScaffoldMessenger.of(context);
  final repository = context.read<CashRepository>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Kaydı sil'),
      content: Text(
        '${entry.title.isEmpty ? 'Bu kayıt' : entry.title} silinsin mi?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: ctx.colors.red),
          child: const Text('Sil'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  try {
    await repository.delete(entry.id);
  } catch (_) {
    AppSnack.fromMessenger(
      messenger,
      'Kayıt silinemedi. Tekrar dene.',
      type: AppSnackType.error,
    );
  }
  return false;
}
