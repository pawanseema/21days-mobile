import 'package:flutter/foundation.dart';

/// Bottom-nav tab index: Explore, Upcoming (Live), Recordings, (optional Wisdom).
class NavigationProvider extends ChangeNotifier {
  /// Set to `true` to show the Wisdom tab again (code stays in the repo).
  static const bool showWisdomTab = false;

  static const int exploreTabIndex = 0;
  static const int liveTabIndex = 1;
  static const int recordingsTabIndex = 2;

  int _index = exploreTabIndex;

  int get index => _index;

  int get maxTabIndex => showWisdomTab ? 3 : 2;

  void setIndex(int value) {
    if (value < 0 || value > maxTabIndex) return;
    if (value == _index) {
      // Still notify so listeners can react (e.g. reminder deep link refresh).
      notifyListeners();
      return;
    }
    _index = value;
    notifyListeners();
  }

  /// Reserved for [WelcomeScreen] when the start gate is re-enabled.
  void enterApp() => notifyListeners();

  void openLiveTab() => setIndex(liveTabIndex);
}
