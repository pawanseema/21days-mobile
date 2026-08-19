import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/navigation_provider.dart';
import '../../widgets/chrome_portrait.dart';
import '../live/live_screen.dart';
import '../recordings/recordings_screen.dart';
import '../resources/resources_screen.dart';
import '../wisdom/wisdom_screen.dart';

/// Root shell with a four-tab [BottomNavigationBar].
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const _pages = <Widget>[
    LiveScreen(),
    ResourcesScreen(),
    RecordingsScreen(),
    WisdomScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 72,
        leading: const ChromePortrait(),
        title: Text(
          const ['Live & Upcoming', 'Explore', 'Recordings', 'Wisdom'][nav.index],
        ),
      ),
      body: IndexedStack(
        index: nav.index,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: nav.index,
        onTap: context.read<NavigationProvider>().setIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.broadcast_on_home_outlined),
            activeIcon: Icon(Icons.broadcast_on_home),
            label: 'Live',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam_outlined),
            activeIcon: Icon(Icons.videocam),
            label: 'Recordings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'Wisdom',
          ),
        ],
      ),
    );
  }
}
