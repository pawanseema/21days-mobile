import '../models/mentor_model.dart';

/// Mentor assignment + request flow (stubbed until a mentor API exists).
class MentorService {
  MentorModel? _assigned = const MentorModel(
    id: 'mentor_ananya',
    name: 'Ananya Sharma',
    bio:
        'Ananya has been practicing Sahaja Yoga for twelve years and loves '
        'supporting new seekers through their first 21 days of meditation.',
    specialties: ['New seekers', 'Subtle system', 'Evening collectives'],
    email: 'ananya.mentor@example.com',
  );

  bool _requestPending = false;

  MentorModel? get assignedMentor => _assigned;

  bool get hasPendingRequest => _requestPending;

  Future<MentorModel?> fetchAssignedMentor() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _assigned;
  }

  /// Submits a mentor request. Clears assignment if none exists yet.
  Future<bool> requestMentor({String? note}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _requestPending = true;
    // Keep existing assignment if present; otherwise leave null until matched.
    return true;
  }

  /// Demo helper — clear assignment to exercise the empty state.
  void clearAssignmentForDemo() {
    _assigned = null;
    _requestPending = false;
  }
}
