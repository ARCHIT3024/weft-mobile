import 'package:flutter/material.dart';

import '../theme.dart';

/// Weft brand mark: teal rounded tile with a city glyph, optional wordmark.
class WeftLogo extends StatelessWidget {
  const WeftLogo({
    super.key,
    this.size = 100,
    this.showWordmark = true,
    this.onDark = true,
  });

  final double size;
  final bool showWordmark;

  /// Wordmark colour: white on navy backgrounds, navy on light ones.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Weft',
      image: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: WeftColors.teal,
              borderRadius: BorderRadius.circular(size * 0.24),
            ),
            child: Icon(
              Icons.location_city_rounded,
              size: size * 0.56,
              color: Colors.white,
            ),
          ),
          if (showWordmark) ...[
            SizedBox(height: size * 0.24),
            Text(
              'Weft',
              style: TextStyle(
                color: onDark ? Colors.white : WeftColors.navy,
                fontSize: size * 0.36,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
