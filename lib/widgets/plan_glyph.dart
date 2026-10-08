import 'package:flutter/material.dart';

import '../models/plan.dart';

class PlanTone {
  const PlanTone(this.wash, this.ink);

  final Color wash;
  final Color ink;

  static PlanTone of(PlanMark mark) => switch (mark) {
        PlanMark.cloud => const PlanTone(Color(0xFFD8F8EC), Color(0xFF10303C)),
        PlanMark.play => const PlanTone(Color(0xFFE4DFFC), Color(0xFF5B4AD0)),
        PlanMark.book => const PlanTone(Color(0xFFEDE4FF), Color(0xFF6E4CC4)),
        PlanMark.note => const PlanTone(Color(0xFFF8E8C4), Color(0xFF8A6420)),
        PlanMark.music => const PlanTone(Color(0xFFD9EEF8), Color(0xFF1E6E8C)),
        PlanMark.film => const PlanTone(Color(0xFFF8DCE8), Color(0xFFA04A70)),
        PlanMark.card => const PlanTone(Color(0xFFE7F0E4), Color(0xFF3E6844)),
        PlanMark.spark => const PlanTone(Color(0xFFFDE8D4), Color(0xFFA85A22)),
      };
}

IconData planIcon(PlanMark mark) => switch (mark) {
      PlanMark.cloud => Icons.cloud_outlined,
      PlanMark.play => Icons.play_arrow_rounded,
      PlanMark.book => Icons.menu_book_outlined,
      PlanMark.note => Icons.description_outlined,
      PlanMark.music => Icons.music_note_outlined,
      PlanMark.film => Icons.movie_outlined,
      PlanMark.card => Icons.credit_card_outlined,
      PlanMark.spark => Icons.bolt_outlined,
    };

extension PlanToneContext on PlanTone {
  PlanTone toned(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) return this;
    return PlanTone(
      Color.lerp(wash, const Color(0xFF12181C), 0.72) ?? wash,
      Color.lerp(ink, const Color(0xFFD7DDD9), 0.38) ?? ink,
    );
  }
}

class PlanGlyph extends StatelessWidget {
  const PlanGlyph({super.key, required this.mark, this.size = 44});

  final PlanMark mark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = PlanTone.of(mark).toned(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tone.wash, borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(planIcon(mark), color: tone.ink, size: size * 0.5),
    );
  }
}
