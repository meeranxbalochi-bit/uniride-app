import 'bus.dart';

/// A pre-defined route template that can be assigned to a bus.
class RoutePreset {
  final String id;
  final String name;
  final String description;
  final String color;
  final List<BusStop> stops;

  const RoutePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    this.stops = const [],
  });

  factory RoutePreset.fromMap(String docId, Map<String, dynamic> map) {
    final rawStops = map['stops'] as List<dynamic>? ?? [];
    final parsedStops = rawStops
        .map((s) => BusStop.fromMap(s as Map<String, dynamic>))
        .toList();

    return RoutePreset(
      id: docId,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      color: map['color'] as String? ?? '#3b82f6',
      stops: parsedStops,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'color': color,
        'stops': stops.map((s) => s.toMap()).toList(),
      };
}
