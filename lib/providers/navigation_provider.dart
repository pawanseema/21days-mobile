import 'package:flutter/foundation.dart';

/// Bottom-nav tab index: Explore, Upcoming, Recordings, optional Wisdom / More.
class NavigationProvider extends ChangeNotifier {
  NavigationProvider({int initialIndex = exploreTabIndex})
      : _index = _clampIndex(initialIndex);

  /// Set to `true` to show the Wisdom tab again (code stays in the repo).
  static const bool showWisdomTab = false;

  /// Set to `true` to show the More tab again (Today's Meditation lives on Explore).
  static const bool showMoreTab = false;

  static const int exploreTabIndex = 0;
  static const int liveTabIndex = 1;
  static const int recordingsTabIndex = 2;

  /// Wisdom is index 3 when enabled; More is last when enabled.
  static int get wisdomTabIndex => 3;

  static int get moreTabIndex => showWisdomTab ? 4 : 3;

  int _index;

  int get index => _index;

  /// Highest valid bottom-nav index given current feature flags.
  static int get maxTabIndex {
    var max = recordingsTabIndex;
    if (showWisdomTab) max += 1;
    if (showMoreTab) max += 1;
    return max;
  }

  static int _clampIndex(int value) {
    final max = maxTabIndex;
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

  void openMoreTab() {
    if (!showMoreTab) return;
    setIndex(moreTabIndex);
  }
}
