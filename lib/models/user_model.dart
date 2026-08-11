/// Authenticated or guest participant profile.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.authProvider = AuthProviderType.email,
  });

  final String id;

  /// Empty for local guests; otherwise the account email (username).
  final String email;
  final String? displayName;
  final String? photoUrl;
  final AuthProviderType authProvider;

  bool get isGuest => authProvider == AuthProviderType.guest;

  String get greetingName {
    if (isGuest) return 'Guest';
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim().split(' ').first;
    }
    if (email.contains('@')) return email.split('@').first;
    return 'Seeker';
  }

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
      email: (json['email'] as String?) ?? '',
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      authProvider: AuthProviderType.values.firstWhere(
        (e) => e.name == json['authProvider'],
        orElse: () => AuthProviderType.email,
      ),
    );
  }

  /// Local-only guest identity (not stored in Firebase).
  static const guest = UserModel(
    id: 'guest_local',
    email: '',
    displayName: 'Guest',
    authProvider: AuthProviderType.guest,
  );
}

enum AuthProviderType { email, google, guest }
