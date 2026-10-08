import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/services/storage_service.dart';
import '../models/plan.dart';
import 'shop_provider.dart';

class PlanProvider extends ChangeNotifier {
  PlanProvider(this.shop);

  static const _key = 'st_plans';

  final ShopProvider shop;
  final _uuid = const Uuid();
  final List<SubPlan> _plans = [];

  List<SubPlan> get plans => List.unmodifiable(_plans);

  List<SubPlan> get active => _plans.where((plan) => plan.status == PlanStatus.active).toList();
  List<SubPlan> get paused => _plans.where((plan) => plan.status == PlanStatus.paused).toList();
  List<SubPlan> get cancelled => _plans.where((plan) => plan.status == PlanStatus.cancelled).toList();

  List<SubPlan> get paying => active.where((plan) => !inTrial(plan)).toList();

  List<SubPlan> get comingUp {
    final rows = paying.followedBy(paused).toList()..sort((a, b) => a.nextRenewal.compareTo(b.nextRenewal));
    return rows;
  }

  int get monthlyTotal => paying.fold(0, (sum, plan) => sum + plan.monthlyCost);
  int get yearlyTotal => paying.fold(0, (sum, plan) => sum + plan.yearlyCost);

  Map<String, int> get monthlyByCurrency => _byCurrency((plan) => plan.monthlyCost);
  Map<String, int> get yearlyByCurrency => _byCurrency((plan) => plan.yearlyCost);

  Map<String, int> _byCurrency(int Function(SubPlan plan) pick) {
    final map = <String, int>{};
    for (final plan in paying) {
      map[plan.currency] = (map[plan.currency] ?? 0) + pick(plan);
    }
    return map;
  }

  bool get canAdd => active.length + paused.length < shop.maxArchive;

  SubPlan? find(String id) {
    for (final plan in _plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  List<SubPlan> inMonth(int year, int month) {
    final rows = _plans.where((plan) {
      if (plan.status == PlanStatus.cancelled) return false;
      final day = shownDate(plan);
      return day.year == year && day.month == month;
    }).toList()
      ..sort((a, b) => shownDate(a).compareTo(shownDate(b)));
    return rows;
  }

  SubPlan? get soonestAlert {
    final rows = active.where((plan) => remindsNow(plan) || trialEnding(plan)).toList()
      ..sort((a, b) {
        final aDay = trialEnding(a) && a.trialEnds != null ? a.trialEnds! : a.nextRenewal;
        final bDay = trialEnding(b) && b.trialEnds != null ? b.trialEnds! : b.nextRenewal;
        return aDay.compareTo(bDay);
      });
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> init() async {
    final raw = await StorageService.instance.getDataList(_key);
    _plans
      ..clear()
      ..addAll((raw ?? []).map(SubPlan.fromJson).where((plan) => plan.name.trim().isNotEmpty));
    final rolled = _plans.any((plan) => plan.rollForward());
    if (rolled) await _save();
    notifyListeners();
  }

  Future<SubPlan?> create({
    required String name,
    required int price,
    required BillCycle cycle,
    required DateTime nextRenewal,
    DateTime? trialEnds,
    required List<int> remindDays,
    required PlanStatus status,
    required String manageUrl,
    required String cancelNote,
    required PlanMark mark,
    String currency = 'VND',
  }) async {
    final title = name.trim();
    if (title.isEmpty) return null;
    if (status != PlanStatus.cancelled && !canAdd) return null;
    final plan = SubPlan(
      id: _uuid.v4(),
      name: title,
      price: price < 0 ? 0 : price,
      cycle: cycle,
      nextRenewal: dateOnly(nextRenewal),
      trialEnds: trialEnds == null ? null : dateOnly(trialEnds),
      remindDays: _cleanDays(remindDays),
      status: status,
      manageUrl: manageUrl.trim(),
      cancelNote: cancelNote.trim(),
      mark: mark,
      currency: moneyCode(currency).code,
      created: DateTime.now(),
    );
    plan.rollForward();
    if (!plan.rewarded) {
      plan.rewarded = true;
      await shop.rewardForPlan();
    }
    _plans.add(plan);
    await _save();
    notifyListeners();
    return plan;
  }

  Future<void> update(
    SubPlan plan, {
    required String name,
    required int price,
    required BillCycle cycle,
    required DateTime nextRenewal,
    DateTime? trialEnds,
    required List<int> remindDays,
    required PlanStatus status,
    required String manageUrl,
    required String cancelNote,
    required PlanMark mark,
    String currency = 'VND',
  }) async {
    final title = name.trim();
    if (title.isEmpty) return;
    final wasOpen = plan.status != PlanStatus.cancelled;
    final willOpen = status != PlanStatus.cancelled;
    if (!wasOpen && willOpen && !canAdd) return;
    plan.name = title;
    plan.price = price < 0 ? 0 : price;
    plan.cycle = cycle;
    plan.nextRenewal = dateOnly(nextRenewal);
    plan.trialEnds = trialEnds == null ? null : dateOnly(trialEnds);
    plan.remindDays = _cleanDays(remindDays);
    plan.status = status;
    plan.manageUrl = manageUrl.trim();
    plan.cancelNote = cancelNote.trim();
    plan.mark = mark;
    plan.currency = moneyCode(currency).code;
    plan.rollForward();
    await _save();
    notifyListeners();
  }

  Future<void> setStatus(String id, PlanStatus status) async {
    final plan = find(id);
    if (plan == null || plan.status == status) return;
    if (plan.status == PlanStatus.cancelled && status != PlanStatus.cancelled && !canAdd) return;
    plan.status = status;
    plan.rollForward();
    await _save();
    notifyListeners();
  }

  Future<void> setRemindDays(String id, List<int> days) async {
    final plan = find(id);
    if (plan == null) return;
    plan.remindDays = _cleanDays(days);
    await _save();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _plans.removeWhere((plan) => plan.id == id);
    await _save();
    notifyListeners();
  }

  List<int> _cleanDays(List<int> days) {
    final next = days.where((day) => day > 0 && day <= 60).toSet().toList()..sort();
    return next.isEmpty ? [1] : next;
  }

  Future<void> _save() async {
    await StorageService.instance.saveDataList(_key, _plans.map((plan) => plan.toJson()).toList());
  }
}
