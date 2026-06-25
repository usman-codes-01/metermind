import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/settings_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../reading.dart';
import '../readings_cubit.dart';
import '../widgets/reading_form_sheet.dart';
import '../widgets/reading_tile.dart';

/// Screen A — the tool. Add readings, see the list with per-row consumption
/// chips + manual override, and a live summary (Calculate) at the top.
class ReadingsPage extends StatelessWidget {
  const ReadingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      floatingActionButton: const _AddFab(),
      body: BlocConsumer<ReadingsCubit, ReadingsState>(
        listenWhen: (a, b) => a.actionError != b.actionError,
        listener: (context, state) {
          if (state.actionError != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.actionError!)));
            context.read<ReadingsCubit>().clearActionError();
          }
        },
        builder: (context, state) {
          final Widget content;
          if (state.isLoading && state.isEmpty) {
            content = const Center(
              child: CircularProgressIndicator(color: AppColors.petrol),
            );
          } else if (state.status == ReadingsStatus.error && state.isEmpty) {
            content = _ErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: () => context.read<ReadingsCubit>().load(),
            );
          } else {
            content = _Body(state: state);
          }
          return content;
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});
  final ReadingsState state;

  @override
  Widget build(BuildContext context) {
    final readings = state.oldestFirst; // old at top, latest at the bottom

    // Fixed widgets above the reading rows. Built lazily by ListView.builder so
    // only what's on screen is laid out — stays smooth no matter how many
    // readings there are.
    final leading = <Widget>[
      const _Header(),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: _SummaryCard(state: state),
      ),
      if (state.isEmpty)
        const _Empty()
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
          child: SectionLabel('Readings', trailing: _Count(n: readings.length)),
        ),
    ];
    final rowCount = state.isEmpty ? 0 : readings.length;
    final itemCount = leading.length + rowCount + 1; // +1 trailing spacer

    return RefreshIndicator(
      color: AppColors.petrol,
      onRefresh: () => context.read<ReadingsCubit>().load(),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < leading.length) return leading[index];
          final rowIndex = index - leading.length;
          if (rowIndex >= rowCount) return const SizedBox(height: 96);
          final item = readings[rowIndex];
          return Padding(
            // Stable key keeps each tile's inline editor bound to its own
            // reading across add / delete / reorder (no state jumping).
            key: ValueKey(item.reading.id),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: ReadingTile(
              item: item,
              onSetManual: (v) =>
                  context.read<ReadingsCubit>().setManualUnits(item.reading.id, v),
              onEdit: () => _edit(context, item),
              onDelete: () => _confirmDelete(context, item),
            ),
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, ComputedReading item) async {
    final cubit = context.read<ReadingsCubit>();
    final result = await showReadingForm(context, existing: item.reading);
    if (result != null) {
      await cubit.updateReading(item.reading.copyWith(
        meterReading: result.meterReading,
        date: result.date,
        note: result.note,
      ));
    }
  }

  Future<void> _confirmDelete(BuildContext context, ComputedReading item) async {
    final cubit = context.read<ReadingsCubit>();
    final p = context.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        title: Text('Delete reading?', style: AppType.title(p.primaryText, size: 18)),
        content: Text(
          'The ${Fmt.date(item.reading.date)} reading will be removed.',
          style: AppType.body(p.secondaryText, size: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppType.label(p.primaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: AppType.label(p.alert)),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.deleteReading(item.reading.id);
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return TealHeader(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MeterMind',
                    style: AppType.body(AppColors.paper.withAlpha(0xB0), size: 12.5)),
                const SizedBox(height: 2),
                Text('Your readings',
                    style: AppType.title(AppColors.paper, size: 22)),
              ],
            ),
          ),
          _HeaderButton(
            icon: theme.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            onTap: theme.toggle,
          ),
          const SizedBox(width: 10),
          _HeaderButton(
            icon: Icons.settings_rounded,
            onTap: () => showSettings(context),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(0x1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.copper, size: 19),
      ),
    );
  }
}

/// The live "Calculate" result: total units used + avg/day + the monthly target.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});
  final ReadingsState state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = state.summary;
    final target = state.monthlyTarget;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_rounded, size: 18, color: AppColors.copper),
              const SizedBox(width: 8),
              Text('Calculation',
                  style: AppType.title(p.primaryText, size: 16)),
              const Spacer(),
              Text('${state.readings.length} readings',
                  style: AppType.caption(p.secondaryText, size: 11.5)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  value: Fmt.thousands(s.totalUnitsUsed),
                  unit: 'units',
                  label: 'Total used',
                ),
              ),
              Container(width: 1, height: 38, color: p.secondaryText.withAlpha(0x22)),
              Expanded(
                child: _Metric(
                  value: Fmt.perDay(s.avgPerDay),
                  unit: '/ day',
                  label: 'Average',
                ),
              ),
              Container(width: 1, height: 38, color: p.secondaryText.withAlpha(0x22)),
              Expanded(
                child: _Metric(
                  value: '${s.totalDays}',
                  unit: s.totalDays == 1 ? 'day' : 'days',
                  label: 'Span',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: p.secondaryText.withAlpha(0x18)),
          const SizedBox(height: 14),
          _TargetRow(state: state),
          if (target != null) ...[
            const SizedBox(height: 12),
            _TargetProgress(target: target, projected: state.projectedMonthly),
            if (state.exceedsTarget) ...[
              const SizedBox(height: 12),
              _TargetWarning(over: state.projectedMonthly - target),
            ],
          ],
        ],
      ),
    );
  }
}

/// "Monthly target" label + the set/edit control.
class _TargetRow extends StatelessWidget {
  const _TargetRow({required this.state});
  final ReadingsState state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final target = state.monthlyTarget;

    if (target == null) {
      return InkWell(
        onTap: () => _editMonthlyTarget(context, null),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.copper.withAlpha(context.isDark ? 0x33 : 0x1F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flag_rounded, size: 16, color: AppColors.copper),
              const SizedBox(width: 8),
              Text('Set your monthly units',
                  style: AppType.label(p.primaryText, size: 13)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Icon(Icons.flag_rounded, size: 16, color: p.secondaryText),
        const SizedBox(width: 8),
        Text('Monthly target', style: AppType.label(p.secondaryText, size: 13)),
        const Spacer(),
        InkWell(
          onTap: () => _editMonthlyTarget(context, target),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.isDark ? Colors.white.withAlpha(0x0F) : AppColors.paper,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${Fmt.thousands(target)} units',
                    style: AppType.mono(p.primaryText, size: 13)),
                const SizedBox(width: 6),
                Icon(Icons.edit_rounded, size: 13, color: p.secondaryText),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Progress bar of projected monthly usage against the target.
class _TargetProgress extends StatelessWidget {
  const _TargetProgress({required this.target, required this.projected});
  final int target;
  final int projected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final over = projected > target;
    final frac = target <= 0 ? 0.0 : (projected / target).clamp(0.0, 1.0);
    final color = over ? p.alert : AppColors.petrol;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: frac.toDouble(),
            minHeight: 8,
            backgroundColor: p.secondaryText.withAlpha(0x22),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Projected ~${Fmt.thousands(projected)} units/month at this pace '
          '(target ${Fmt.thousands(target)})',
          style: AppType.caption(p.secondaryText, size: 11),
        ),
      ],
    );
  }
}

class _TargetWarning extends StatelessWidget {
  const _TargetWarning({required this.over});
  final int over;

  @override
  Widget build(BuildContext context) {
    final alert = context.palette.alert;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: alert.withAlpha(0x1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alert.withAlpha(0x55)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: alert, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'On track to exceed your monthly units by '
              '~${Fmt.thousands(over)} units.',
              style: AppType.label(alert, size: 12).copyWith(height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to set / change / clear the monthly-units target.
Future<void> _editMonthlyTarget(BuildContext context, int? current) async {
  final cubit = context.read<ReadingsCubit>();
  final p = context.palette;
  final controller = TextEditingController(text: current?.toString() ?? '');
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: p.card,
      title: Text('Set your monthly units',
          style: AppType.title(p.primaryText, size: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your monthly units allowance. We’ll warn you when your projected '
            'usage is on track to go over it.',
            style: AppType.body(p.secondaryText, size: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: AppType.mono(p.primaryText, size: 18),
            cursorColor: AppColors.copper,
            decoration: InputDecoration(
              hintText: 'e.g. 300',
              hintStyle: AppType.body(p.secondaryText, size: 14),
              filled: true,
              fillColor: p.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.copper, width: 1.4),
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (current != null)
          TextButton(
            onPressed: () {
              cubit.setMonthlyTarget(null);
              Navigator.pop(ctx);
            },
            child: Text('Clear', style: AppType.label(p.alert)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: AppType.label(p.primaryText)),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(controller.text.trim());
            if (value != null && value > 0) cubit.setMonthlyTarget(value);
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.unit, required this.label});
  final String value, unit, label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppType.title(AppColors.copper, size: 24)),
              const SizedBox(width: 3),
              Text(unit, style: AppType.caption(p.secondaryText, size: 10.5)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.caption(p.secondaryText, size: 9.5)
                .copyWith(letterSpacing: 0.6)),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.n});
  final int n;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text('$n total', style: AppType.caption(p.secondaryText, size: 12));
  }
}

class _AddFab extends StatelessWidget {
  const _AddFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.copper,
      foregroundColor: AppColors.ink,
      elevation: 3,
      onPressed: () async {
        final cubit = context.read<ReadingsCubit>();
        final result = await showReadingForm(context);
        if (result != null) {
          await cubit.addReading(
            meterReading: result.meterReading,
            date: result.date,
            note: result.note,
          );
        }
      },
      icon: const Icon(Icons.add, size: 22),
      label: Text('Add reading', style: AppType.button(AppColors.ink)),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 56, 40, 40),
      child: Column(
        children: [
          Icon(Icons.speed_rounded, size: 52, color: p.secondaryText),
          const SizedBox(height: 18),
          Text('No readings yet', style: AppType.title(p.primaryText, size: 20)),
          const SizedBox(height: 10),
          Text(
            'Add your first meter reading. From the second reading on, we’ll show '
            'units used, per-day usage and the days between readings.',
            textAlign: TextAlign.center,
            style: AppType.body(p.secondaryText, size: 13.5).copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: p.secondaryText),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: AppType.body(p.secondaryText, size: 14)),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
