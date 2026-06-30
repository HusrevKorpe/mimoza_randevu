import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../services/note_repository.dart';
import '../theme/app_theme.dart';
import 'app_snackbar.dart';
import 'list_card.dart';
import 'section_header.dart';
import 'section_placeholder.dart';
import 'swipe_delete_background.dart';

/// NOTLAR — general to-dos grouped in one panel: checkable rows plus an
/// always-present inline add field as the panel's last row. Owns the notes stream
/// and the add field's controller/focus so they survive list rebuilds.
class GeneralNotesSection extends StatefulWidget {
  const GeneralNotesSection({super.key});

  @override
  State<GeneralNotesSection> createState() => _GeneralNotesSectionState();
}

class _GeneralNotesSectionState extends State<GeneralNotesSection> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  late final Stream<List<Note>> _stream =
      context.read<NoteRepository>().watchAll();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final repository = context.read<NoteRepository>();
    _controller.clear();
    try {
      await repository.add(text);
      if (mounted) _focus.requestFocus();
    } catch (_) {
      AppSnack.fromMessenger(
        messenger,
        'Not eklenemedi. Tekrar dene.',
        type: AppSnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final addRow = _AddNoteRow(
      controller: _controller,
      focusNode: _focus,
      onSubmit: _add,
    );

    return StreamBuilder<List<Note>>(
      stream: _stream,
      builder: (context, snapshot) {
        final rows = <Widget>[];
        if (snapshot.hasError) {
          rows.add(
            const _MessageRow(
              icon: Icons.error_outline_rounded,
              text: 'Notlar yüklenemedi.',
            ),
          );
        } else {
          for (final note in snapshot.data ?? const <Note>[]) {
            rows.add(_NoteRow(note: note));
          }
        }
        // The add field is always the last row, so the panel is never empty.
        rows.add(addRow);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'NOTLAR'),
            ListCard(children: rows),
          ],
        );
      },
    );
  }
}

/// One to-do: a checkbox that toggles done, text that strikes through when done,
/// and swipe-to-delete. Flat row; the panel draws the surface and dividers.
class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      // Square background: the ListCard clips it to the panel's rounded corners.
      background: const SwipeDeleteBackground(radius: 0),
      confirmDismiss: (_) => _delete(context, note),
      child: InkWell(
        onTap: () => _toggle(context, note),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(
                note.done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: note.done ? colors.green : colors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  note.text,
                  style: note.done
                      ? text.body.copyWith(
                          color: colors.textMuted,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: colors.textMuted,
                        )
                      : text.name,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The inline add field — the notes panel's last row.
class _AddNoteRow extends StatelessWidget {
  const _AddNoteRow({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(Icons.add_rounded, size: 22, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              style: context.text.name,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'Not ekle…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintStyle: context.text.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A muted icon + message row used for the error state inside the panel.
class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: SectionPlaceholder(icon: icon, text: text),
    );
  }
}

Future<void> _toggle(BuildContext context, Note note) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await context.read<NoteRepository>().setDone(note.id, !note.done);
  } catch (_) {
    AppSnack.fromMessenger(
      messenger,
      'Not güncellenemedi.',
      type: AppSnackType.error,
    );
  }
}

/// Deletes via the repository, then resolves `false` so the live stream drives
/// the row's removal (matches the appointment/cash swipe pattern).
Future<bool> _delete(BuildContext context, Note note) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await context.read<NoteRepository>().delete(note.id);
  } catch (_) {
    AppSnack.fromMessenger(
      messenger,
      'Not silinemedi. Tekrar dene.',
      type: AppSnackType.error,
    );
  }
  return false;
}
