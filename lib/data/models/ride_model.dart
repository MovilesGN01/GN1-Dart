class RideModel {
  const RideModel({
    required this.id,
    required this.driverName,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.price,
    required this.seatsAvailable,
    required this.reputationScore,
    required this.hasRainForecast,
    required this.isFemaleDriver,
    required this.eta,
  });

  final String id;
  final String driverName;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final double price;
  final int seatsAvailable;
  final double reputationScore;
  final bool hasRainForecast;
  final bool isFemaleDriver;
  final String eta;

  RideModel copyWith({
    String? id,
    String? driverName,
    String? origin,
    String? destination,
    DateTime? departureTime,
    double? price,
    int? seatsAvailable,
    double? reputationScore,
    bool? hasRainForecast,
    bool? isFemaleDriver,
    String? eta,
  }) {
    return RideModel(
      id: id ?? this.id,
      driverName: driverName ?? this.driverName,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      price: price ?? this.price,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      reputationScore: reputationScore ?? this.reputationScore,
      hasRainForecast: hasRainForecast ?? this.hasRainForecast,
      isFemaleDriver: isFemaleDriver ?? this.isFemaleDriver,
      eta: eta ?? this.eta,
    );
  }

  factory RideModel.fromMap(Map<String, dynamic> map) {
    return RideModel(
      id: map['id'] as String,
      driverName: map['driverName'] as String,
      origin: map['origin'] as String,
      destination: map['destination'] as String,
      departureTime: DateTime.parse(map['departureTime'] as String),
      price: (map['price'] as num).toDouble(),
      seatsAvailable: map['seatsAvailable'] as int,
      reputationScore: (map['reputationScore'] as num).toDouble(),
      hasRainForecast: map['hasRainForecast'] as bool,
      isFemaleDriver: map['isFemaleDriver'] as bool,
      eta: map['eta'] as String,
    );
  }
}
