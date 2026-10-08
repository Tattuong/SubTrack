enum BillCycle { weekly, monthly, quarterly, yearly }

enum PlanStatus { active, paused, cancelled }

enum PlanMark { cloud, play, book, note, music, film, card, spark }

class SubPlan {
  SubPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.cycle,
    required this.nextRenewal,
    required this.created,
    List<int>? remindDays,
    this.trialEnds,
    this.status = PlanStatus.active,
    this.manageUrl = '',
    this.cancelNote = '',
    this.mark = PlanMark.cloud,
    this.currency = 'VND',
    this.rewarded = false,
  }) : remindDays = remindDays ?? [1];

  final String id;
  String name;
  int price;
  BillCycle cycle;
  DateTime nextRenewal;
  DateTime? trialEnds;
  List<int> remindDays;
  PlanStatus status;
  String manageUrl;
  String cancelNote;
  PlanMark mark;
  String currency;
  final DateTime created;
  bool rewarded;

  int get monthlyCost {
    return switch (cycle) {
      BillCycle.weekly => (price * 52 / 12).round(),
      BillCycle.monthly => price,
      BillCycle.quarterly => (price / 3).round(),
      BillCycle.yearly => (price / 12).round(),
    };
  }

  int get yearlyCost => monthlyCost * 12;

  int get remindLead => remindDays.isEmpty ? 0 : remindDays.reduce((a, b) => a > b ? a : b);

  bool rollForward([DateTime? today]) {
    if (status != PlanStatus.active) return false;
    final day = dateOnly(today ?? DateTime.now());
    var next = dateOnly(nextRenewal);
    var changed = false;
    var guard = 0;
    while (next.isBefore(day) && guard < 600) {
      next = addCycle(next, cycle);
      changed = true;
      guard++;
    }
    nextRenewal = next;
    return changed;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'cycle': cycle.name,
        'nextRenewal': dateOnly(nextRenewal).toIso8601String(),
        'trialEnds': trialEnds == null ? null : dateOnly(trialEnds!).toIso8601String(),
        'remindDays': remindDays,
        'status': status.name,
        'manageUrl': manageUrl,
        'cancelNote': cancelNote,
        'mark': mark.name,
        'currency': currency,
        'created': created.toIso8601String(),
        'rewarded': rewarded,
      };

  factory SubPlan.fromJson(Map<String, dynamic> json) {
    final days = ((json['remindDays'] as List?) ?? const [1]).map((value) => (value as num).toInt()).where((value) => value > 0).toList();
    return SubPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      cycle: BillCycle.values.byName(json['cycle'] as String? ?? 'monthly'),
      nextRenewal: DateTime.tryParse(json['nextRenewal'] as String? ?? '') ?? DateTime.now(),
      trialEnds: DateTime.tryParse(json['trialEnds'] as String? ?? ''),
      remindDays: days.isEmpty ? [1] : days,
      status: PlanStatus.values.byName(json['status'] as String? ?? 'active'),
      manageUrl: json['manageUrl'] as String? ?? '',
      cancelNote: json['cancelNote'] as String? ?? '',
      mark: PlanMark.values.byName(json['mark'] as String? ?? 'cloud'),
      currency: moneyCode(json['currency'] as String? ?? 'VND').code,
      created: DateTime.tryParse(json['created'] as String? ?? '') ?? DateTime.now(),
      rewarded: json['rewarded'] as bool? ?? false,
    );
  }
}

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime addCycle(DateTime value, BillCycle cycle) {
  final day = dateOnly(value);
  return switch (cycle) {
    BillCycle.weekly => day.add(const Duration(days: 7)),
    BillCycle.monthly => addMonths(day, 1),
    BillCycle.quarterly => addMonths(day, 3),
    BillCycle.yearly => addMonths(day, 12),
  };
}

DateTime addMonths(DateTime value, int months) {
  final slot = value.month - 1 + months;
  final year = value.year + slot ~/ 12;
  final month = slot % 12 + 1;
  final last = DateTime(year, month + 1, 0).day;
  final day = value.day > last ? last : value.day;
  return DateTime(year, month, day);
}

int daysUntil(DateTime day, [DateTime? today]) {
  return dateOnly(day).difference(dateOnly(today ?? DateTime.now())).inDays;
}

bool remindsNow(SubPlan plan, [DateTime? today]) {
  if (plan.status != PlanStatus.active) return false;
  final day = dateOnly(today ?? DateTime.now());
  final start = dateOnly(plan.nextRenewal).subtract(Duration(days: plan.remindLead));
  final renewal = dateOnly(plan.nextRenewal);
  return !day.isBefore(start) && !day.isAfter(renewal);
}

bool inTrial(SubPlan plan, [DateTime? today]) {
  final trial = plan.trialEnds;
  if (trial == null || plan.status != PlanStatus.active) return false;
  return !dateOnly(trial).isBefore(dateOnly(today ?? DateTime.now()));
}

DateTime shownDate(SubPlan plan) {
  if (inTrial(plan) && plan.trialEnds != null) return dateOnly(plan.trialEnds!);
  return dateOnly(plan.nextRenewal);
}

bool trialEnding(SubPlan plan, [DateTime? today]) {
  final trial = plan.trialEnds;
  if (trial == null || plan.status != PlanStatus.active) return false;
  final left = daysUntil(trial, today);
  return left >= 0 && left <= (plan.remindLead == 0 ? 3 : plan.remindLead);
}

String money(int amount, [String currency = 'VND']) {
  final spec = moneyCode(currency);
  final sign = amount < 0 ? '-' : '';
  final abs = amount.abs();
  if (spec.decimals == 0) {
    return '$sign${spec.prefix}${_group(abs)}${spec.suffix}';
  }
  final major = abs ~/ 100;
  final minor = (abs % 100).toString().padLeft(2, '0');
  return '$sign${spec.prefix}${_group(major)}.$minor${spec.suffix}';
}

String _group(int value) {
  final digits = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

class MoneyCode {
  const MoneyCode(this.code, this.prefix, this.suffix, this.decimals);

  final String code;
  final String prefix;
  final String suffix;
  final int decimals;
}

const moneyCodes = <MoneyCode>[
  MoneyCode('VND', '', ' VND', 0),
  MoneyCode('USD', '\$', '', 2),
  MoneyCode('EUR', '€', '', 2),
  MoneyCode('GBP', '£', '', 2),
  MoneyCode('JPY', '¥', '', 0),
  MoneyCode('KRW', '₩', '', 0),
  MoneyCode('CNY', 'CN¥', '', 2),
  MoneyCode('THB', '฿', '', 2),
  MoneyCode('SGD', 'S\$', '', 2),
  MoneyCode('AUD', 'A\$', '', 2),
  MoneyCode('CAD', 'C\$', '', 2),
  MoneyCode('INR', '₹', '', 2),
];

MoneyCode moneyCode(String code) {
  for (final spec in moneyCodes) {
    if (spec.code == code) return spec;
  }
  return moneyCodes.first;
}

int parsePrice(String text, String currency) {
  final cleaned = text.trim().replaceAll(',', '');
  if (cleaned.isEmpty) return 0;
  final spec = moneyCode(currency);
  if (spec.decimals == 0) {
    return int.tryParse(cleaned.split('.').first) ?? 0;
  }
  final value = double.tryParse(cleaned);
  if (value == null || value < 0) return 0;
  return (value * 100).round();
}

String priceField(int amount, String currency) {
  if (amount == 0) return '';
  final spec = moneyCode(currency);
  if (spec.decimals == 0) return '$amount';
  return (amount / 100).toStringAsFixed(2);
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String monthDay(DateTime day) => '${_months[day.month - 1]} ${day.day}';

String ticketDay(DateTime day) => '${day.day} ${_months[day.month - 1].toUpperCase()}';

String shortDay(DateTime day) => '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}';

String cycleLabel(BillCycle cycle) => switch (cycle) {
      BillCycle.weekly => 'Weekly',
      BillCycle.monthly => 'Monthly',
      BillCycle.quarterly => 'Quarterly',
      BillCycle.yearly => 'Yearly',
    };

String perLabel(BillCycle cycle) => switch (cycle) {
      BillCycle.weekly => 'week',
      BillCycle.monthly => 'month',
      BillCycle.quarterly => 'quarter',
      BillCycle.yearly => 'year',
    };

String statusLabel(PlanStatus status) => switch (status) {
      PlanStatus.active => 'Active',
      PlanStatus.paused => 'Paused',
      PlanStatus.cancelled => 'Cancelled',
    };

String daysLeftLabel(int days) {
  if (days == 0) return 'Today';
  if (days == 1) return '1 day left';
  if (days > 1) return '$days days left';
  if (days == -1) return '1 day ago';
  return '${days.abs()} days ago';
}
