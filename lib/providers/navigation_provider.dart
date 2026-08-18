import 'package:flutter/foundation.dart';

/// Bottom-nav tab index: Live, Explore, Recordings, Wisdom.
class NavigationProvider extends ChangeNotifier {
  int _index = 0;

  /// Whether the user has left the welcome screen for the tab shell.
  bool _inApp = false;

  int get index => _index;
  bool get inApp => _inApp;

  void enterApp() {
    if (_inApp) return;
    _inApp = true;
    notifyListeners();
  }

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
