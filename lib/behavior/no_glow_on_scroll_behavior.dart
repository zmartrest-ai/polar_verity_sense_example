import 'package:flutter/widgets.dart';

class NoGlowOnScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // This line removes the glow effect
    return child;
  }
}
