import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cash_entry.dart';
import '../services/auth_service.dart';
import '../services/cash_repository.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_label.dart';

/// Yeni Gider — the create *and* edit form for an expense entry: title, amount
/// and date. Saves through [CashRepository]; the Günlük tab picks the change up
/// via its live stream.
///
/// Route argument decides the mode: a [CashEntry] → edit it; a [DateTime] →
/// create one for that day; nothing → create one for today.
class NewCashScreen extends StatefulWidget {
  const NewCashScreen({super.key});

  @override
  State<NewCashScreen> createState() => _NewCashScreenState();
}

class _NewCashScreenState extends State<NewCashScreen> {
  static final DateFormat _dateLabel = DateFormat('EEEE, d MMMM yyyy', 'tr_TR');

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  /// Non-null when editing; null when creating.
  CashEntry? _editing;

  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _initialized = false;

  bool get _isEditing => _editing != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is CashEntry) {
      _editing = arg;
      _titleController.text = arg.title;
      _amountController.text = _amountInput(arg.amount);
      _date = DateTime(arg.date.year, arg.date.month, arg.date.day);
    } else if (arg is DateTime) {
      _date = DateTime(arg.year, arg.month, arg.day);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Seed the amount field when editing: whole numbers without decimals, else
  /// Turkish "," decimals — matching what [parseAmount] reads back.
  static String _amountInput(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final title = _titleController.text.trim();
    final amount = parseAmount(_amountController.text);

    if (title.isEmpty) {
      AppSnack.fromMessenger(messenger, 'Başlık girin.', type: AppSnackType.info);
      return;
    }
    if (amount == null || amount <= 0) {
      AppSnack.fromMessenger(
        messenger,
        'Geçerli bir tutar girin.',
        type: AppSnackType.info,
      );
      return;
    }

    final entry = CashEntry(
      id: _editing?.id ?? '',
      title: title,
      amount: amount,
      date: _date,
      createdAt: _editing?.createdAt,
    );

    setState(() => _saving = true);
    try {
      final uid = context.read<AuthService>().user!.uid;
      final repository = CashRepository(uid);
      if (_isEditing) {
        await repository.update(entry);
        navigator.pop(entry);
      } else {
        await repository.add(entry);
        navigator.pop();
      }
    } on FirebaseException catch (e, stack) {
      if (mounted) setState(() => _saving = false);
      debugPrint('Cash save failed: ${e.code} — ${e.message}\n$stack');
      final reason = e.code == 'permission-denied'
          ? ' (yetki reddedildi — Firestore kuralları)'
          : ' (${e.code})';
      AppSnack.fromMessenger(
        messenger,
        '${_isEditing ? 'Değişiklikler kaydedilemedi' : 'Kayıt kaydedilemedi'}'
            '$reason',
        type: AppSnackType.error,
      );
    } catch (e, stack) {
      if (mounted) setState(() => _saving = false);
      debugPrint('Cash save failed: $e\n$stack');
      AppSnack.fromMessenger(
        messenger,
        _isEditing
            ? 'Değişiklikler kaydedilemedi. Tekrar dene.'
            : 'Kayıt kaydedilemedi. Tekrar dene.',
        type: AppSnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Gideri Düzenle' : 'Yeni Gider';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            AppSpacing.screen,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleField(
                        controller: _titleController,
                        hint: 'Örn. Kira, Malzeme, Fatura',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _AmountField(controller: _amountController),
                      const SizedBox(height: AppSpacing.xl),
                      _DateField(
                        label: _dateLabel.format(_date),
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Kaydet',
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A field group: uppercase label above its input/control.
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: 'BAŞLIK',
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: 'TUTAR',
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(
          hintText: '0',
          prefixText: '₺ ',
          prefixStyle: context.text.body,
          helperText: 'Kuruş için virgül kullan (örn. 1.500,50)',
        ),
      ),
    );
  }
}

/// Read-only, tappable field styled like the text inputs; opens a date picker.
class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(AppRadius.field);
    return _LabeledField(
      label: 'TARİH',
      child: Material(
        color: colors.card,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: context.text.body)),
                  Icon(Icons.event_rounded, color: colors.primary, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
