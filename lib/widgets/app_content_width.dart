import 'package:flutter/material.dart';

import '../utils/layout_breakpoints.dart';

/// Centers [child] in a column capped at [AppLayout.contentMaxWidth].
///
/// On phones the cap never binds (width already under the max). On tablets /
/// wide windows, blank side margins give a reading-width column.
class AppContentWidth extends StatelessWidget {
  const AppContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
        child: SizedBox(
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }
}
