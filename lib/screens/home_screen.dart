import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/navigation/app_navigator.dart';
import '../models/plan.dart';
import '../providers/plan_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';
import '../widgets/coin_balance_chip.dart';
import '../widgets/plan_glyph.dart';
import 'plan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: switch (_tab) {
                1 => const _CalendarTab(),
                2 => const _StatsTab(),
                _ => _OverviewTab(onSeeCalendar: () => setState(() => _tab = 1)),
              },
            ),
            const AdBannerSlot(),
            _Nav(index: _tab, onSelect: (index) => setState(() => _tab = index)),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.onSeeCalendar});

  final VoidCallback onSeeCalendar;

  @override
  Widget build(BuildContext context) {
    final board = context.watch<PlanProvider>();
    final coming = board.comingUp;
    final alert = board.soonestAlert;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        const _Header(),
        const SizedBox(height: 12),
        Text('Your plans', style: AppTypography.title(size: 26, context: context)),
        const SizedBox(height: 12),
        _TotalCard(monthly: board.monthlyByCurrency, yearly: board.yearlyByCurrency, active: board.paying.length),
        if (alert != null) ...[
          const SizedBox(height: 12),
          _AlertCard(plan: alert),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Coming up', style: AppTypography.labelBold(size: 16, context: context)),
            const Spacer(),
            TextButton(onPressed: onSeeCalendar, child: const Text('See calendar')),
          ],
        ),
        if (coming.isEmpty)
          Text('No plans yet. Add the next renewal so you can decide before it charges.', style: AppTypography.body(size: 15, context: context))
        else
          for (final plan in coming) ...[
            _PlanRow(plan: plan),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 4),
        FilledButton.icon(
          onPressed: () => _addPlan(context),
          icon: const Icon(Icons.add),
          label: const Text('Add a plan', style: TextStyle(fontWeight: FontWeight.w800)),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.primaryOf(context), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.sync_rounded, color: AppColors.onPrimaryOf(context), size: 16),
        ),
        const SizedBox(width: 8),
        Text('SubTrack', style: AppTypography.title(size: 22, context: context)),
        const Spacer(),
        const CoinBalanceChip(variant: CoinChipVariant.header),
        const SizedBox(width: 2),
        const IconButton(visualDensity: VisualDensity.compact, onPressed: AppTabs.goSettings, icon: Icon(Icons.settings_outlined)),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.monthly, required this.yearly, required this.active});

  final Map<String, int> monthly;
  final Map<String, int> yearly;
  final int active;

  @override
  Widget build(BuildContext context) {
    final onPrimary = AppColors.onPrimaryOf(context);
    final codes = monthly.keys.toList();
    final single = codes.length <= 1;
    final code = codes.isEmpty ? 'VND' : codes.first;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(color: AppColors.primaryOf(context), borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly equivalent', style: TextStyle(color: onPrimary.withValues(alpha: 0.75), fontWeight: FontWeight.w600)),
                if (single)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(money(monthly[code] ?? 0, code), style: TextStyle(color: onPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                  )
                else
                  for (final item in codes)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(money(monthly[item] ?? 0, item), style: TextStyle(color: onPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.mintWash(context), borderRadius: BorderRadius.circular(20)),
                  child: Text('$active active', style: const TextStyle(color: Color(0xFF10303C), fontWeight: FontWeight.w800, fontSize: 12)),
                ),
                const SizedBox(height: 8),
                if (single)
                  Text('Equals ${money(yearly[code] ?? 0, code)} / year', style: TextStyle(color: onPrimary.withValues(alpha: 0.8), fontSize: 13))
                else
                  for (final item in codes)
                    Text('${money(yearly[item] ?? 0, item)} / year', style: TextStyle(color: onPrimary.withValues(alpha: 0.8), fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.sync_rounded, color: onPrimary.withValues(alpha: 0.35), size: 64),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.plan});

  final SubPlan plan;

  @override
  Widget build(BuildContext context) {
    final trial = trialEnding(plan);
    final when = trial && plan.trialEnds != null ? plan.trialEnds! : plan.nextRenewal;
    final title = trial ? '${plan.name} trial ends soon' : '${plan.name} renews soon';
    final detail = trial ? '${shortDay(when)} · Then ${money(plan.price, plan.currency)}/${perLabel(plan.cycle)}' : '${shortDay(when)} · ${daysLeftLabel(daysUntil(when))}';
    return Material(
      color: AppColors.alertWash(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openPlan(context, plan.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              const Icon(Icons.hourglass_bottom_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.labelBold(context: context)),
                    Text(detail, style: AppTypography.body(size: 13, context: context)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.plan});

  final SubPlan plan;

  @override
  Widget build(BuildContext context) {
    final left = daysUntil(plan.nextRenewal);
    final paused = plan.status == PlanStatus.paused;
    return Material(
      color: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.borderOf(context))),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openPlan(context, plan.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              PlanGlyph(mark: plan.mark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name, style: AppTypography.labelBold(context: context)),
                    Text(
                      paused ? 'Paused · ${shortDay(plan.nextRenewal)}' : '${shortDay(plan.nextRenewal)} · ${daysLeftLabel(left)}',
                      style: AppTypography.body(size: 13, context: context),
                    ),
                  ],
                ),
              ),
              Text(money(plan.price, plan.currency), style: AppTypography.labelBold(context: context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarTab extends StatefulWidget {
  const _CalendarTab();

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final rows = context.watch<PlanProvider>().inMonth(_month.year, _month.month);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Text("Don't miss\na renewal.", style: AppTypography.display(size: 32, context: context)),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), icon: const Icon(Icons.chevron_left)),
            Expanded(child: Text('${_months[_month.month - 1]} ${_month.year}', textAlign: TextAlign.center, style: AppTypography.labelBold(size: 16, context: context))),
            IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)), icon: const Icon(Icons.chevron_right)),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.noteWash(context), borderRadius: BorderRadius.circular(14)),
          child: Text('Dates come from what you type in. SubTrack does not read a bank.', style: AppTypography.body(size: 13, context: context)),
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          Text('Nothing renews this month.', style: AppTypography.body(size: 15, context: context))
        else
          for (var i = 0; i < rows.length; i++) _TimelineRow(plan: rows[i], last: i == rows.length - 1),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.noteWash(context), borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              const Icon(Icons.notifications_none_rounded),
              const SizedBox(width: 10),
              Expanded(child: Text('Reminders stay in SubTrack. You decide before the charge.', style: AppTypography.body(size: 13, context: context))),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.plan, required this.last});

  final SubPlan plan;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final tone = PlanTone.of(plan.mark).toned(context);
    final when = shownDate(plan);
    final trial = inTrial(plan);
    final remindOn = dateOnly(plan.nextRenewal).subtract(Duration(days: plan.remindLead));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Column(
              children: [
                Text('${when.day}', style: AppTypography.title(size: 20, context: context)),
                Text(_months[when.month - 1].substring(0, 3).toUpperCase(), style: AppTypography.body(size: 11, context: context)),
              ],
            ),
          ),
          SizedBox(
            width: 18,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(width: 10, height: 10, decoration: BoxDecoration(color: tone.ink, shape: BoxShape.circle)),
                if (!last) Container(width: 2, height: 58, color: AppColors.borderOf(context)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: tone.wash,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => openPlan(context, plan.id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Row(
                      children: [
                        Icon(planIcon(plan.mark), color: tone.ink),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plan.name, style: AppTypography.labelBold(context: context)),
                              if (trial)
                                Text('Trial ending', style: TextStyle(color: tone.ink, fontWeight: FontWeight.w800, fontSize: 11)),
                              Text(
                                trial ? '${money(plan.price, plan.currency)}/${perLabel(plan.cycle)} if you continue' : '${money(plan.price, plan.currency)} · Remind ${shortDay(remindOn)}',
                                style: AppTypography.body(size: 12, context: context),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    final board = context.watch<PlanProvider>();
    final ranked = [...board.active]..sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));
    final peakOf = <String, int>{};
    for (final plan in ranked) {
      if (plan.monthlyCost > (peakOf[plan.currency] ?? 0)) peakOf[plan.currency] = plan.monthlyCost;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Text('Compare', style: AppTypography.title(size: 26, context: context)),
        const SizedBox(height: 8),
        Text('Monthly and yearly totals use active plans only.', style: AppTypography.body(size: 14, context: context)),
        const SizedBox(height: 14),
        Row(
          children: [
            _Count(label: 'Active', value: board.active.length),
            const SizedBox(width: 8),
            _Count(label: 'Paused', value: board.paused.length),
            const SizedBox(width: 8),
            _Count(label: 'Cancelled', value: board.cancelled.length),
          ],
        ),
        const SizedBox(height: 12),
        _TotalCard(monthly: board.monthlyByCurrency, yearly: board.yearlyByCurrency, active: board.paying.length),
        const SizedBox(height: 16),
        if (ranked.isEmpty)
          Text('Add a plan to compare what each one costs per month.', style: AppTypography.body(size: 15, context: context))
        else
          for (final plan in ranked) ...[
            Row(
              children: [
                Expanded(child: Text(plan.name, style: AppTypography.labelBold(context: context))),
                Text('${money(plan.monthlyCost, plan.currency)} / mo', style: AppTypography.body(size: 13, context: context)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (peakOf[plan.currency] ?? 0) == 0 ? 0 : plan.monthlyCost / peakOf[plan.currency]!,
                minHeight: 8,
                color: PlanTone.of(plan.mark).toned(context).ink,
                backgroundColor: AppColors.primarySoftOf(context),
              ),
            ),
            const SizedBox(height: 12),
          ],
        if (board.cancelled.isNotEmpty) ...[
          Text('Cancelled', style: AppTypography.labelBold(size: 16, context: context)),
          const SizedBox(height: 6),
          for (final plan in board.cancelled)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: PlanGlyph(mark: plan.mark, size: 36),
              title: Text(plan.name),
              subtitle: const Text('Cancelled in SubTrack'),
              onTap: () => openPlan(context, plan.id),
            ),
        ],
        const SizedBox(height: 8),
        Text('SubTrack does not read your bank or cancel a service for you.', style: AppTypography.body(size: 13, context: context)),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderOf(context))),
        child: Column(
          children: [
            Text('$value', style: AppTypography.title(size: 22, context: context)),
            Text(label, style: AppTypography.body(size: 12, context: context)),
          ],
        ),
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const labels = ['Overview', 'Calendar', 'Stats'];
    const icons = [Icons.home_outlined, Icons.calendar_month_outlined, Icons.bar_chart_rounded];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icons[i], color: index == i ? (AppColors.isDark(context) ? AppColors.primaryLight : AppColors.primaryOf(context)) : AppColors.mutedInk(context)),
                      const SizedBox(height: 2),
                      Text(labels[i], style: TextStyle(fontWeight: index == i ? FontWeight.w800 : FontWeight.w600, fontSize: 12, color: index == i ? AppColors.inkOf(context) : AppColors.mutedInk(context))),
                      const SizedBox(height: 4),
                      Container(height: 3, width: 28, decoration: BoxDecoration(color: index == i ? (AppColors.isDark(context) ? AppColors.primaryLight : AppColors.primaryOf(context)) : Colors.transparent, borderRadius: BorderRadius.circular(2))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

Future<void> _addPlan(BuildContext context) async {
  final board = context.read<PlanProvider>();
  if (!board.canAdd) {
    final shop = context.read<ShopProvider>();
    AppToast.show(context, title: AppStrings.t(context, 'needProFlows', {'n': '${shop.maxArchive}'}), actionLabel: 'Shop', onAction: AppTabs.goShop);
    return;
  }
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlanFormScreen()));
}
