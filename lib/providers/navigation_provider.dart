import 'package:flutter/foundation.dart';

/// Bottom-nav tab index: Live, Resources, Recordings, Wisdom.
class NavigationProvider extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void setIndex(int value) {
    if (value < 0 || value > 3) return;
    if (value == _index) {
      // Still notify so listeners can react (e.g. reminder deep link refresh).
      notifyListeners();
      return;
    }
    _index = value;
    notifyListeners();
  }

  /// Live tab index.
  static const int liveTabIndex = 0;

  void openLiveTab() => setIndex(liveTabIndex);
}
