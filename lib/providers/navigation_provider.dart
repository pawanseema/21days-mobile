import 'package:flutter/foundation.dart';

/// Bottom-nav tab index: Live, Resources, Mentor, Wisdom.
class NavigationProvider extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void setIndex(int value) {
    if (value == _index || value < 0 || value > 3) return;
    _index = value;
    notifyListeners();
  }
}
