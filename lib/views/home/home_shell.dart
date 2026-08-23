import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/navigation_provider.dart';
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

    return Scaffold(
      appBar: const ChromeHeader(),
      body: IndexedStack(
        index: index,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
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
    );
  }
}
