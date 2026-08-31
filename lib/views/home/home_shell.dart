import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/navigation_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chrome_header.dart';
import '../live/live_screen.dart';
import '../recordings/recordings_screen.dart';
import '../resources/resources_screen.dart';
import '../wisdom/wisdom_screen.dart';

/// Root shell with bottom navigation.
///
/// Wisdom UI/code remains in the repo; flip [NavigationProvider.showWisdomTab]
/// to restore the tab.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static List<Widget> get _pages => [
        const ResourcesScreen(),
        const LiveScreen(),
        const RecordingsScreen(),
        if (NavigationProvider.showWisdomTab) const WisdomScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final index = nav.index.clamp(0, _pages.length - 1);
    final colors = context.colors;

    return Scaffold(
      appBar: ChromeHeader.preferredSizeFor(context),
      body: IndexedStack(
        index: index,
        children: _pages,
      ),
      // Column keeps the shelf strip in the nav slot so Scaffold cannot clip
      // an upward BoxShadow under the opaque body.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ChromeShelfUp(),
          Material(
            color: colors.chromeBackground,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 1,
                  width: double.infinity,
                  color: colors.ink.withValues(alpha: 0.154),
                ),
                BottomNavigationBar(
                  elevation: 0,
                  currentIndex: index,
                  onTap: context.read<NavigationProvider>().setIndex,
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.explore_outlined),
                      activeIcon: Icon(Icons.explore),
                      label: 'Explore',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.event_outlined),
                      activeIcon: Icon(Icons.event),
                      label: 'Upcoming',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.videocam_outlined),
                      activeIcon: Icon(Icons.videocam),
                      label: 'Recordings',
                    ),
                    if (NavigationProvider.showWisdomTab)
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.auto_awesome_outlined),
                        activeIcon: Icon(Icons.auto_awesome),
                        label: 'Wisdom',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft fade from blue content into the yellow bottom tabs (Option 2 ledge).
class _ChromeShelfUp extends StatelessWidget {
  const _ChromeShelfUp();

  @override
  Widget build(BuildContext context) {
    final ink = context.colors.ink;
    return IgnorePointer(
      child: SizedBox(
        height: 10,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ink.withValues(alpha: 0),
                ink.withValues(alpha: 0.11),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
