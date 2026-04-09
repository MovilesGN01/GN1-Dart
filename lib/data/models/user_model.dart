class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.reputationScore,
    required this.punctualityRate,
    required this.ridesPerMonth,
    required this.savedRoute,
  });

  final String id;
  final String name;
  final String email;
  final double reputationScore;
  final double punctualityRate;
  final int ridesPerMonth;
  final String savedRoute;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    double? reputationScore,
    double? punctualityRate,
    int? ridesPerMonth,
    String? savedRoute,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      reputationScore: reputationScore ?? this.reputationScore,
      punctualityRate: punctualityRate ?? this.punctualityRate,
      ridesPerMonth: ridesPerMonth ?? this.ridesPerMonth,
      savedRoute: savedRoute ?? this.savedRoute,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      reputationScore: (map['reputationScore'] as num).toDouble(),
      punctualityRate: (map['punctualityRate'] as num).toDouble(),
      ridesPerMonth: map['ridesPerMonth'] as int,
      savedRoute: map['savedRoute'] as String,
    );
  }
}
