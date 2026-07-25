/// Authenticated participant profile.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.authProvider = AuthProviderType.email,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final AuthProviderType authProvider;

  String get greetingName =>
      (displayName != null && displayName!.trim().isNotEmpty)
          ? displayName!.trim().split(' ').first
          : email.split('@').first;

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    AuthProviderType? authProvider,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      authProvider: authProvider ?? this.authProvider,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'authProvider': authProvider.name,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      authProvider: AuthProviderType.values.firstWhere(
        (e) => e.name == json['authProvider'],
        orElse: () => AuthProviderType.email,
      ),
    );
  }
}

enum AuthProviderType { email, google }
