import 'package:flutter/foundation.dart';

import '../models/mentor_model.dart';
import '../services/mentor_service.dart';

/// Mentor tab state: assigned mentor + request action.
class MentorProvider extends ChangeNotifier {
  MentorProvider({MentorService? mentorService})
      : _mentorService = mentorService ?? MentorService() {
    load();
  }

  final MentorService _mentorService;

  MentorModel? _mentor;
  bool _loading = true;
  bool _requesting = false;
  bool _requestPending = false;
  String? _message;

  MentorModel? get mentor => _mentor;
  bool get isLoading => _loading;
  bool get isRequesting => _requesting;
  bool get requestPending => _requestPending;
  String? get message => _message;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _mentor = await _mentorService.fetchAssignedMentor();
    _requestPending = _mentorService.hasPendingRequest;
    _loading = false;
    notifyListeners();
  }

  Future<void> requestMentor({String? note}) async {
    _requesting = true;
    _message = null;
    notifyListeners();
    final ok = await _mentorService.requestMentor(note: note);
    _requestPending = _mentorService.hasPendingRequest;
    _message = ok
        ? 'Your mentor request has been submitted. We will match you soon.'
        : 'Unable to submit request. Please try again.';
    _requesting = false;
    notifyListeners();
  }
}
