import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/navigation/app_navigator.dart';
import '../models/plan.dart';
import '../models/shop_item.dart';
import '../providers/plan_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';
import '../widgets/plan_glyph.dart';

void openPlan(BuildContext context, String id) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlanScreen(planId: id)));
}

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, required this.planId});

  final String planId;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  var _awake = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (context.read<ShopProvider>().featureOn(ShopCatalog.featAwake)) {
        _awake = true;
        await WakelockPlus.enable();
      }
    });
  }

  @override
  void dispose() {
    if (_awake) WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = context.watch<PlanProvider>();
    final plan = board.find(widget.planId);
    if (plan == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('This plan is gone.')));
    }
    final left = daysUntil(plan.nextRenewal);
    final tone = PlanTone.of(plan.mark).toned(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan details'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlanFormScreen(planId: plan.id))),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                Center(child: PlanGlyph(mark: plan.mark, size: 72)),
                const SizedBox(height: 8),
                Text(plan.name, textAlign: TextAlign.center, style: AppTypography.title(size: 26, context: context)),
                const SizedBox(height: 6),
                Center(child: _StatusPill(status: plan.status)),
                const SizedBox(height: 14),
                Text('${money(plan.price, plan.currency)} / ${perLabel(plan.cycle)}', textAlign: TextAlign.center, style: AppTypography.display(size: 34, context: context)),
                Text(
                  plan.cycle == BillCycle.yearly ? 'Equals ${money(plan.monthlyCost, plan.currency)} / month' : '${money(plan.yearlyCost, plan.currency)} / year',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(size: 14, context: context),
                ),
                const SizedBox(height: 16),
                _Ticket(day: plan.nextRenewal, left: left),
                const SizedBox(height: 18),
                Text('Remind before', style: AppTypography.labelBold(context: context)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final day in {...plan.remindDays, 1, 3, 7}.toList()..sort())
                      ChoiceChip(
                        label: Text(day == 1 ? '1 day' : '$day days'),
                        selected: plan.remindDays.contains(day),
                        onSelected: (_) => _toggleRemind(plan, day),
                      ),
                    ActionChip(label: const Text('Add'), onPressed: () => _addRemind(plan)),
                  ],
                ),
                const SizedBox(height: 14),
                _InfoRow(label: 'Cycle', value: cycleLabel(plan.cycle)),
                if (plan.trialEnds != null) _InfoRow(label: 'Trial ends', value: monthDay(plan.trialEnds!)),
                const SizedBox(height: 8),
                Material(
                  color: AppColors.noteWash(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description_outlined, color: tone.ink),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('How to cancel', style: AppTypography.labelBold(context: context)),
                              Text(
                                plan.cancelNote.trim().isEmpty ? 'Add a note in edit, such as where the cancel button lives.' : plan.cancelNote,
                                style: AppTypography.body(size: 13, context: context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: FilledButton.icon(
              onPressed: () => _openManage(plan),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open manage page', style: TextStyle(fontWeight: FontWeight.w800)),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: OutlinedButton.icon(
              onPressed: () => _flipStatus(plan),
              icon: Icon(plan.status == PlanStatus.cancelled ? Icons.replay_rounded : Icons.delete_outline),
              label: Text(plan.status == PlanStatus.cancelled ? 'Mark as active' : 'Mark as cancelled', style: const TextStyle(fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('This only updates SubTrack. It does not cancel the service.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          ),
          const AdBannerSlot(),
        ],
      ),
    );
  }

  Future<void> _toggleRemind(SubPlan plan, int day) async {
    final next = [...plan.remindDays];
    if (next.contains(day)) {
      if (next.length == 1) return;
      next.remove(day);
    } else {
      next.add(day);
    }
    await context.read<PlanProvider>().setRemindDays(plan.id, next);
  }

  Future<void> _addRemind(SubPlan plan) async {
    final day = await showDialog<int>(context: context, builder: (context) => const _RemindDialog());
    if (day == null || !mounted) return;
    await context.read<PlanProvider>().setRemindDays(plan.id, [...plan.remindDays, day]);
  }

  Future<void> _openManage(SubPlan plan) async {
    final raw = plan.manageUrl.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http')) || !uri.hasAuthority) {
      AppToast.show(context, title: raw.isEmpty ? 'Add a manage link first' : 'Use a full https link');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) AppToast.show(context, title: 'Could not open that page');
  }

  Future<void> _flipStatus(SubPlan plan) async {
    final board = context.read<PlanProvider>();
    final next = plan.status == PlanStatus.cancelled ? PlanStatus.active : PlanStatus.cancelled;
    if (next == PlanStatus.active && !board.canAdd && plan.status == PlanStatus.cancelled) {
      final shop = context.read<ShopProvider>();
      AppToast.show(context, title: AppStrings.t(context, 'needProFlows', {'n': '${shop.maxArchive}'}), actionLabel: 'Shop', onAction: AppTabs.goShop);
      return;
    }
    if (context.read<ShopProvider>().featureOn(ShopCatalog.featSound)) {
      await HapticFeedback.selectionClick();
    }
    await board.setStatus(plan.id, next);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final PlanStatus status;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusWash(context, active: status == PlanStatus.active, paused: status == PlanStatus.paused);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(statusLabel(status), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.statusInk(context))),
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket({required this.day, required this.left});

  final DateTime day;
  final int left;

  @override
  Widget build(BuildContext context) {
    final canvas = AppColors.canvasOf(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Column(
            children: [
              Text('NEXT RENEWAL', style: AppTypography.body(size: 12, context: context)),
              const SizedBox(height: 4),
              Text(ticketDay(day), textAlign: TextAlign.center, style: AppTypography.display(size: 32, context: context)),
              Text('${day.year} · ${daysLeftLabel(left)}', style: AppTypography.labelBold(context: context)),
            ],
          ),
        ),
        Positioned(left: -10, child: _Notch(color: canvas)),
        Positioned(right: -10, child: _Notch(color: canvas)),
      ],
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: AppColors.borderOf(context))),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: AppTypography.body(size: 14, context: context)),
          const Spacer(),
          Text(value, style: AppTypography.labelBold(context: context)),
        ],
      ),
    );
  }
}

class _RemindDialog extends StatefulWidget {
  const _RemindDialog();

  @override
  State<_RemindDialog> createState() => _RemindDialogState();
}

class _RemindDialogState extends State<_RemindDialog> {
  final _days = TextEditingController();

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Remind before'),
      content: TextField(
        controller: _days,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(hintText: 'Days, 1 to 60'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final day = int.tryParse(_days.text) ?? 0;
            if (day < 1 || day > 60) return;
            Navigator.pop(context, day);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class PlanFormScreen extends StatefulWidget {
  const PlanFormScreen({super.key, this.planId});

  final String? planId;

  @override
  State<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _url;
  late final TextEditingController _note;
  late BillCycle _cycle;
  late PlanStatus _status;
  late PlanMark _mark;
  late String _currency;
  late DateTime _renewal;
  DateTime? _trial;
  late List<int> _remind;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    final plan = widget.planId == null ? null : context.read<PlanProvider>().find(widget.planId!);
    _name = TextEditingController(text: plan?.name ?? '');
    _price = TextEditingController(text: plan == null ? '' : priceField(plan.price, plan.currency));
    _url = TextEditingController(text: plan?.manageUrl ?? '');
    _note = TextEditingController(text: plan?.cancelNote ?? '');
    _cycle = plan?.cycle ?? BillCycle.monthly;
    _status = plan?.status ?? PlanStatus.active;
    _mark = plan?.mark ?? PlanMark.cloud;
    _currency = plan?.currency ?? 'VND';
    _renewal = plan?.nextRenewal ?? DateTime.now().add(const Duration(days: 30));
    _trial = plan?.trialEnds;
    _remind = [...?plan?.remindDays];
    if (_remind.isEmpty) _remind = [1];
    _ready = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _url.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final editing = widget.planId != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit plan' : 'New plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          Text('Currency', style: AppTypography.labelBold(context: context)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final spec in moneyCodes)
                ChoiceChip(
                  label: Text(spec.code),
                  selected: _currency == spec.code,
                  onSelected: (_) => setState(() => _currency = spec.code),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _price,
            keyboardType: TextInputType.numberWithOptions(decimal: moneyCode(_currency).decimals > 0),
            inputFormatters: [
              moneyCode(_currency).decimals == 0 ? FilteringTextInputFormatter.digitsOnly : FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(labelText: 'Price', hintText: moneyCode(_currency).decimals == 0 ? '49000' : '9.99'),
          ),
          const SizedBox(height: 12),
          Text('Cycle', style: AppTypography.labelBold(context: context)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final cycle in BillCycle.values)
                ChoiceChip(label: Text(cycleLabel(cycle)), selected: _cycle == cycle, onSelected: (_) => setState(() => _cycle = cycle)),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Next payment'),
            subtitle: Text(monthDay(_renewal)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _renewal, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (picked != null) setState(() => _renewal = picked);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Trial ends'),
            subtitle: Text(_trial == null ? 'None' : monthDay(_trial!)),
            trailing: _trial == null
                ? const Icon(Icons.chevron_right)
                : IconButton(onPressed: () => setState(() => _trial = null), icon: const Icon(Icons.close)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _trial ?? _renewal,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _trial = picked);
            },
          ),
          Text('Status', style: AppTypography.labelBold(context: context)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final status in PlanStatus.values)
                ChoiceChip(label: Text(statusLabel(status)), selected: _status == status, onSelected: (_) => setState(() => _status = status)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Icon', style: AppTypography.labelBold(context: context)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final mark in PlanMark.values)
                GestureDetector(
                  onTap: () => setState(() => _mark = mark),
                  child: Opacity(opacity: _mark == mark ? 1 : 0.4, child: PlanGlyph(mark: mark, size: 44)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _url, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Manage link', hintText: 'https://')),
          const SizedBox(height: 10),
          TextField(controller: _note, textCapitalization: TextCapitalization.sentences, maxLines: 3, decoration: const InputDecoration(labelText: 'How to cancel')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          if (editing)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete plan'),
                    content: const Text('This removes the plan from this phone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) return;
                await context.read<PlanProvider>().delete(widget.planId!);
                if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Delete plan'),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final board = context.read<PlanProvider>();
    final title = _name.text.trim();
    if (title.isEmpty) {
      AppToast.show(context, title: 'Name the plan');
      return;
    }
    final existing = widget.planId == null ? null : board.find(widget.planId!);
    if (existing == null && _status != PlanStatus.cancelled && !board.canAdd) {
      final shop = context.read<ShopProvider>();
      AppToast.show(context, title: AppStrings.t(context, 'needProFlows', {'n': '${shop.maxArchive}'}), actionLabel: 'Shop', onAction: AppTabs.goShop);
      return;
    }
    if (existing == null) {
      final created = await board.create(
        name: title,
        price: parsePrice(_price.text, _currency),
        cycle: _cycle,
        nextRenewal: _renewal,
        trialEnds: _trial,
        remindDays: _remind,
        status: _status,
        manageUrl: _url.text,
        cancelNote: _note.text,
        mark: _mark,
        currency: _currency,
      );
      if (created != null && mounted) Navigator.pop(context);
      return;
    }
    await board.update(
      existing,
      name: title,
      price: parsePrice(_price.text, _currency),
      cycle: _cycle,
      nextRenewal: _renewal,
      trialEnds: _trial,
      remindDays: _remind,
      status: _status,
      manageUrl: _url.text,
      cancelNote: _note.text,
      mark: _mark,
      currency: _currency,
    );
    if (mounted) Navigator.pop(context);
  }
}
