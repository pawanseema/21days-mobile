import 'package:flutter/foundation.dart';

/// Bottom-nav tab index: Explore, Upcoming (Live), Recordings, (optional Wisdom).
class NavigationProvider extends ChangeNotifier {
  NavigationProvider({int initialIndex = exploreTabIndex})
      : _index = _clampIndex(initialIndex);

  /// Set to `true` to show the Wisdom tab again (code stays in the repo).
  static const bool showWisdomTab = false;

  static const int exploreTabIndex = 0;
  static const int liveTabIndex = 1;
  static const int recordingsTabIndex = 2;

  int _index;

  int get index => _index;

  int get maxTabIndex => showWisdomTab ? 3 : 2;

  static int _clampIndex(int value) {
    final max = showWisdomTab ? 3 : 2;
    if (value < 0) return exploreTabIndex;
    if (value > max) return max;
    return value;
  }

  void setIndex(int value) {
    final next = _clampIndex(value);
    if (next == _index) {
      // Still notify so listeners can react (e.g. reminder deep link refresh).
      notifyListeners();
      return;
    }
    _index = next;
    notifyListeners();
  }

  /// Reserved for [WelcomeScreen] when the start gate is re-enabled.
  void enterApp() => notifyListeners();

  void openLiveTab() => setIndex(liveTabIndex);
}
