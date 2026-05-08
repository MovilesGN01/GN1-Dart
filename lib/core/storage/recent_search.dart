class RecentSearch {
  final String origin;
  final String destination;
  final int timestampMs;

  const RecentSearch({
    required this.origin,
    required this.destination,
    required this.timestampMs,
  });

  Map<String, dynamic> toMap() => {
        'origin': origin,
        'destination': destination,
        'timestampMs': timestampMs,
      };

  factory RecentSearch.fromMap(Map<String, dynamic> map) => RecentSearch(
        origin: map['origin'] as String,
        destination: map['destination'] as String,
        timestampMs: map['timestampMs'] as int,
      );
}
