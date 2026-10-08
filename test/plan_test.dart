import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack/core/constants/iap_constants.dart';
import 'package:subtrack/core/services/hive_service.dart';
import 'package:subtrack/core/services/storage_service.dart';
import 'package:subtrack/models/plan.dart';
import 'package:subtrack/providers/plan_provider.dart';
import 'package:subtrack/providers/shop_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('st_plans');
    await HiveService.init(path: dir.path, suffix: '_plans');
    await StorageService.instance.init();
  });

  setUp(() async {
    await HiveService.kv.clear();
  });

  test('monthly and yearly equivalents follow the cycle', () {
    final monthly = SubPlan(id: '1', name: 'Cloud', price: 49000, cycle: BillCycle.monthly, nextRenewal: DateTime(2026, 10, 12), created: DateTime(2026, 1, 1));
    expect(monthly.monthlyCost, 49000);
    expect(monthly.yearlyCost, 588000);
    expect(money(49000), '49,000 VND');
    expect(money(999, 'USD'), '\$9.99');
    expect(money(123456, 'EUR'), '€1,234.56');
    expect(money(1200, 'JPY'), '¥1,200');
    final yearly = SubPlan(id: '2', name: 'Box', price: 588000, cycle: BillCycle.yearly, nextRenewal: DateTime(2026, 10, 12), created: DateTime(2026, 1, 1));
    expect(yearly.monthlyCost, 49000);
    final weekly = SubPlan(id: '3', name: 'Pass', price: 12000, cycle: BillCycle.weekly, nextRenewal: DateTime(2026, 10, 12), created: DateTime(2026, 1, 1));
    expect(weekly.monthlyCost, 52000);
    expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
  });

  test('a past renewal rolls forward and the reminder window opens', () {
    final plan = SubPlan(
      id: '1',
      name: 'Cloud',
      price: 49000,
      cycle: BillCycle.monthly,
      nextRenewal: DateTime(2026, 1, 12),
      remindDays: [3],
      created: DateTime(2026, 1, 1),
    );
    expect(plan.rollForward(DateTime(2026, 3, 1)), isTrue);
    expect(plan.nextRenewal, DateTime(2026, 3, 12));
    expect(remindsNow(plan, DateTime(2026, 3, 10)), isTrue);
    expect(remindsNow(plan, DateTime(2026, 3, 1)), isFalse);
    expect(daysUntil(plan.nextRenewal, DateTime(2026, 3, 8)), 4);
  });

  test('free plans stop at 8, and a cancelled plan does not take a slot', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    final board = PlanProvider(shop);
    await board.init();
    for (var i = 0; i < IapConstants.freeArchiveLimit; i++) {
      expect(
        await board.create(name: 'Plan $i', price: 1000, cycle: BillCycle.monthly, nextRenewal: DateTime(2026, 12, 1), remindDays: [1], status: PlanStatus.active, manageUrl: '', cancelNote: '', mark: PlanMark.cloud),
        isNotNull,
      );
    }
    expect(
      await board.create(name: 'One more', price: 1000, cycle: BillCycle.monthly, nextRenewal: DateTime(2026, 12, 1), remindDays: [1], status: PlanStatus.active, manageUrl: '', cancelNote: '', mark: PlanMark.note),
      isNull,
    );
    final cancelled = await board.create(name: 'Old', price: 1000, cycle: BillCycle.monthly, nextRenewal: DateTime(2026, 12, 1), remindDays: [1], status: PlanStatus.cancelled, manageUrl: '', cancelNote: 'Settings', mark: PlanMark.book);
    expect(cancelled, isNotNull);
    expect(board.monthlyTotal, 8000);
    expect(shop.coins, IapConstants.testCompleteReward * IapConstants.maxDayRewards);
  });
}
