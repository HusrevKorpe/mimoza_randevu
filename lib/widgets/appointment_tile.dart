import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'icon_action_button.dart';

/// One appointment row: time · name + phone · green call button. Optionally
/// tappable for the detail screen. [past] fades the whole row for an
/// appointment whose time has already elapsed.
class AppointmentTile extends StatelessWidget {
  const AppointmentTile({
    super.key,
    required this.appointment,
    required this.onCall,
    this.onTap,
    this.past = false,
  });

  final Appointment appointment;
  final VoidCallback onCall;
  final VoidCallback? onTap;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final card = AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(appointment.time, style: text.time),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.name,
                  style: text.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.phone.isEmpty ? '—' : appointment.phone,
                  style: text.helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconActionButton(
            icon: Icons.phone_rounded,
            background: colors.green,
            foreground: colors.onPrimary,
            onTap: onCall,
          ),
        ],
      ),
    );
    return past ? Opacity(opacity: AppOpacity.past, child: card) : card;
  }
}
