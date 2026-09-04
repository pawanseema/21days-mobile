import 'package:flutter/material.dart';

import '../utils/layout_breakpoints.dart';

/// Vertical list of result cards; switches to a 2-column row layout when the
/// available width is at least [AppLayout.exploreTwoColumnMinWidth].
class ResponsiveResultList extends StatelessWidget {
  const ResponsiveResultList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 28),
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = AppLayout.exploreColumnsFor(constraints.maxWidth);
        if (columns <= 1) {
          return ListView.separated(
            padding: padding,
            itemCount: itemCount,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppLayout.exploreGridGap),
            itemBuilder: itemBuilder,
          );
        }

        final rowCount = (itemCount + columns - 1) ~/ columns;
        return ListView.builder(
          padding: padding,
          itemCount: rowCount,
          itemBuilder: (context, row) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: row == rowCount - 1 ? 0 : AppLayout.exploreGridGap,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var col = 0; col < columns; col++) ...[
                      if (col > 0)
                        const SizedBox(width: AppLayout.exploreGridGap),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final index = row * columns + col;
                            if (index >= itemCount) {
                              return const SizedBox.shrink();
                            }
                            return itemBuilder(context, index);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
