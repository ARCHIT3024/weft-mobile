import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import 'issue_visuals.dart';

/// Round category glyph: white icon on the category colour, white ring so it
/// stays distinct on any map tile. Labelled for screen readers unless
/// [excludeFromSemantics] (use that when a text label sits right next to it).
class CategoryIcon extends StatelessWidget {
  const CategoryIcon(
    this.category, {
    super.key,
    this.size = 40,
    this.excludeFromSemantics = false,
  });

  final IssueCategory category;
  final double size;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    final v = category.visual;
    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: v.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size >= 32 ? 2 : 1.5),
      ),
      child: Icon(v.icon, color: Colors.white, size: size * 0.55),
    );
    if (excludeFromSemantics) return ExcludeSemantics(child: circle);
    return Semantics(label: v.label, image: true, child: circle);
  }
}
