import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../reading.dart';

/// A row in the readings list. Shows the date + cumulative meter reading, a chip
/// row (units used · per-day · days gap), and an inline manual-override control
/// with a "reset to auto" option. Edit / delete live in the overflow menu.
class ReadingTile extends StatefulWidget {
  const ReadingTile({
    super.key,
    required this.item,
    required this.onSetManual,
    required this.onEdit,
    required this.onDelete,
  });

  final ComputedReading item;
  final ValueChanged<int?> onSetManual; // null = reset to auto
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<ReadingTile> createState() => _ReadingTileState();
}

class _ReadingTileState extends State<ReadingTile> {
  bool _editing = false;
  late final TextEditingController _controller =
      TextEditingController(text: widget.item.unitsUsed?.toString() ?? '');

  @override
  void didUpdateWidget(covariant ReadingTile old) {
    super.didUpdateWidget(old);
    // Keep the field in sync when not actively editing.
    if (!_editing) {
      _controller.text = widget.item.unitsUsed?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(_controller.text.trim());
    if (value != null) widget.onSetManual(value);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final item = widget.item;
    final r = item.reading;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateChip(date: r.date),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(Fmt.meter(r.meterReading),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.mono(p.primaryText, size: 19)),
                        ),
                        const SizedBox(width: 5),
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text('on meter',
                              style: AppType.body(p.secondaryText, size: 11.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(Fmt.date(r.date),
                        style: AppType.caption(p.secondaryText, size: 11.5)),
                    if (r.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(r.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.body(p.secondaryText, size: 12)),
                    ],
                  ],
                ),
              ),
              _Menu(onEdit: widget.onEdit, onDelete: widget.onDelete),
            ],
          ),
          const SizedBox(height: 12),
          _chips(context),
          if (!item.isBaseline) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.stacked_line_chart_rounded,
                    size: 13, color: p.secondaryText),
                const SizedBox(width: 5),
                Text('Total used up to this day: ${Fmt.thousands(item.cumulativeUsed)} units',
                    style: AppType.caption(p.secondaryText, size: 11.5)),
              ],
            ),
          ],
          if (item.invalid) ...[
            const SizedBox(height: 10),
            _InvalidNote(alert: p.alert),
          ],
          const SizedBox(height: 10),
          _override(context),
        ],
      ),
    );
  }

  // Units used · per-day · days gap.
  Widget _chips(BuildContext context) {
    final p = context.palette;
    final item = widget.item;

    if (item.isBaseline) {
      return Pill(
        color: AppColors.petrol.withAlpha(context.isDark ? 0x33 : 0x10),
        child: Text('Baseline — first reading',
            style: AppType.label(p.primaryText, size: 12)),
      );
    }

    final units = item.unitsUsed!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Stat(
          label: item.isManual ? 'units (manual)' : 'units used',
          value: Fmt.thousands(units),
          accent: AppColors.copper,
          strong: true,
        ),
        _Stat(label: 'per day', value: Fmt.perDay(item.perDay!)),
        _Stat(
          label: item.daysGap == 1 ? 'day' : 'days',
          value: '${item.daysGap}',
        ),
      ],
    );
  }

  Widget _override(BuildContext context) {
    final p = context.palette;
    final item = widget.item;
    if (item.isBaseline) return const SizedBox.shrink();

    if (!_editing) {
      return Row(
        children: [
          InkWell(
            onTap: () {
              _controller.text = item.unitsUsed?.toString() ?? '';
              setState(() => _editing = true);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 15, color: p.secondaryText),
                  const SizedBox(width: 5),
                  Text(item.isManual ? 'Manual units set' : 'Set units manually',
                      style: AppType.label(p.secondaryText, size: 12)),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (item.isManual)
            InkWell(
              onTap: () => widget.onSetManual(null),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text('Reset to auto',
                    style: AppType.label(AppColors.copper, size: 12)),
              ),
            ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppType.mono(p.primaryText, size: 15),
              cursorColor: AppColors.copper,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'units',
                hintStyle: AppType.body(p.secondaryText, size: 13),
                filled: true,
                fillColor: p.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.copper, width: 1.4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _MiniButton(label: 'Set', copper: true, onTap: _save),
        const SizedBox(width: 6),
        _MiniButton(
          label: 'Cancel',
          onTap: () => setState(() => _editing = false),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});
  final DateTime date;

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.petrol.withAlpha(context.isDark ? 0x33 : 0x0F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('${date.day}',
              style: AppType.title(p.primaryText, size: 18)),
          Text(_months[date.month - 1],
              style: AppType.caption(p.secondaryText, size: 9.5)
                  .copyWith(letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.accent,
    this.strong = false,
  });

  final String label;
  final String value;
  final Color? accent;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final valueColor = accent ?? p.primaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: strong
            ? AppColors.copper.withAlpha(context.isDark ? 0x33 : 0x1F)
            : (context.isDark ? Colors.white.withAlpha(0x0F) : AppColors.paper),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(value,
              style: AppType.mono(valueColor, size: 13.5,
                  weight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text(label, style: AppType.caption(p.secondaryText, size: 11)),
        ],
      ),
    );
  }
}

class _InvalidNote extends StatelessWidget {
  const _InvalidNote({required this.alert});
  final Color alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: alert.withAlpha(0x1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alert.withAlpha(0x55)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: alert, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Meter reading went down. Set the units used manually to fix it.',
              style: AppType.label(alert, size: 11.5).copyWith(height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, required this.onTap, this.copper = false});
  final String label;
  final VoidCallback onTap;
  final bool copper;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = copper ? AppColors.copper : p.background;
    final fg = copper ? AppColors.ink : p.primaryText;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(label, style: AppType.label(fg, size: 12.5)),
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 20, color: p.secondaryText),
      color: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Text('Edit', style: AppType.label(p.primaryText, size: 14)),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: AppType.label(p.alert, size: 14)),
        ),
      ],
    );
  }
}
