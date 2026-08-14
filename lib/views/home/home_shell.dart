import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../account/account_screen.dart';
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
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          nav.index == 0
              ? AppConstants.appName
              : const ['Live', 'Resources', 'Recordings', 'Wisdom'][nav.index],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  user.greetingName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.chromeForeground,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Account',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AccountScreen(),
                ),
              );
            },
            icon: const Icon(Icons.manage_accounts_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
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
            icon: Icon(Icons.video_library_outlined),
            activeIcon: Icon(Icons.video_library),
            label: 'Resources',
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
