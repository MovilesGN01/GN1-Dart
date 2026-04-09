class UserModel {
  final String id;
  final String name;
  final String email;
  final double reputationScore;
  final double driverRating;
  final String role;
  final bool verified;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.reputationScore,
    required this.driverRating,
    required this.role,
    required this.verified,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      reputationScore:
          (data['reputationScore'] as num?)?.toDouble() ?? 0.0,
      driverRating: (data['driverRating'] as num?)?.toDouble() ?? 0.0,
      role: data['role'] as String? ?? 'passenger',
      verified: data['verified'] as bool? ?? false,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    double? reputationScore,
    double? driverRating,
    String? role,
    bool? verified,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      reputationScore: reputationScore ?? this.reputationScore,
      driverRating: driverRating ?? this.driverRating,
      role: role ?? this.role,
      verified: verified ?? this.verified,
    );
  }
}
