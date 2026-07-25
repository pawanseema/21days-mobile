/// Mentor assigned to guide a 21-day participant.
class MentorModel {
  const MentorModel({
    required this.id,
    required this.name,
    required this.bio,
    this.specialties = const [],
    this.photoUrl,
    this.email,
  });

  final String id;
  final String name;
  final String bio;
  final List<String> specialties;
  final String? photoUrl;
  final String? email;

  factory MentorModel.fromJson(Map<String, dynamic> json) {
    return MentorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      bio: (json['bio'] ?? '') as String,
      specialties: (json['specialties'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      photoUrl: json['photoUrl'] as String?,
      email: json['email'] as String?,
    );
  }
}
