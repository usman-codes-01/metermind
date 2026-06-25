import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/common_widgets.dart';
import '../reading.dart';

/// Result of the add/edit form.
class ReadingFormResult {
  const ReadingFormResult({
    required this.meterReading,
    required this.date,
    required this.note,
  });
  final int meterReading;
  final DateTime date;
  final String note;
}

/// Shows the add/edit reading sheet. Returns the entered values, or null if
/// dismissed. Pass [existing] to pre-fill for editing.
Future<ReadingFormResult?> showReadingForm(
  BuildContext context, {
  Reading? existing,
}) {
  return showModalBottomSheet<ReadingFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReadingFormSheet(existing: existing),
  );
}

class _ReadingFormSheet extends StatefulWidget {
  const _ReadingFormSheet({this.existing});
  final Reading? existing;

  @override
  State<_ReadingFormSheet> createState() => _ReadingFormSheetState();
}

class _ReadingFormSheetState extends State<_ReadingFormSheet> {
  late final TextEditingController _meter = TextEditingController(
      text: widget.existing?.meterReading.toString() ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.existing?.note ?? '');
  late DateTime _date = widget.existing?.date ?? DateTime.now();

  bool get _isEdit => widget.existing != null;
  int? get _value => int.tryParse(_meter.text.trim());
  bool get _canSave => _value != null && _value! >= 0;

  @override
  void dispose() {
    _meter.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now, // today or any past date — never the future
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.petrol,
                onPrimary: AppColors.paper,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(ReadingFormResult(
      meterReading: _value!,
      date: DateTime(_date.year, _date.month, _date.day),
      note: _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.secondaryText.withAlpha(0x55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(_isEdit ? 'Edit reading' : 'Add reading',
                  style: AppType.title(p.primaryText, size: 20)),
              const SizedBox(height: 4),
              Text('The total number shown on your meter on a given day.',
                  style: AppType.body(p.secondaryText, size: 12.5)),
              const SizedBox(height: 20),
              _DateField(date: _date, onTap: _pickDate),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Meter reading',
                hint: '00000',
                controller: _meter,
                mono: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Note (optional)',
                hint: 'e.g. after the AC service',
                controller: _note,
              ),
              const SizedBox(height: 24),
              BigButton(
                label: _isEdit ? 'Save changes' : 'Save reading',
                copper: true,
                enabled: _canSave,
                onPressed: _canSave ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DATE',
            style: AppType.caption(p.secondaryText, size: 10.5)
                .copyWith(letterSpacing: 0.8)),
        const SizedBox(height: 7),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: p.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ink.withAlpha(0x12)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 17, color: p.secondaryText),
                const SizedBox(width: 10),
                Text(Fmt.date(date),
                    style: AppType.body(p.primaryText, size: 15)),
                const Spacer(),
                Icon(Icons.expand_more_rounded, size: 20, color: p.secondaryText),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
