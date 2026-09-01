/// GPS coordinates and velocity of a bus at a point in time.
class BusLocation {
  final double lat;
  final double lng;
  final double speed; // km/h
  final double heading; // 0-360 degrees
  final int updatedAt;

  const BusLocation({
    required this.lat,
    required this.lng,
    this.speed = 0.0,
    this.heading = 0.0,
    required this.updatedAt,
  });

  factory BusLocation.fromMap(Map<String, dynamic> map) {
    return BusLocation(
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      updatedAt:
          map['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'speed': speed,
        'heading': heading,
        'updatedAt': updatedAt,
      };
}

/// A stop along a bus route.
class BusStop {
  final String id;
  final String name;
  final String? campusArea;
  final double lat;
  final double lng;
  final int order;
  final int? estimatedStaySec;

  const BusStop({
    required this.id,
    required this.name,
    this.campusArea,
    required this.lat,
    required this.lng,
    required this.order,
    this.estimatedStaySec,
  });

  factory BusStop.fromMap(Map<String, dynamic> map) {
    return BusStop(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      campusArea: map['campusArea'] as String?,
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      order: map['order'] as int? ?? 0,
      estimatedStaySec: map['estimatedStaySec'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'campusArea': campusArea,
        'lat': lat,
        'lng': lng,
        'order': order,
        'estimatedStaySec': estimatedStaySec,
      };
}

/// Full bus model matching the Firestore 'buses' collection.
class Bus {
  final String id;
  final String busNumber;
  final String busName;
  final String plateNumber;
  final String fleetCode;
  final String? driverId;
  final String driverName;
  final String? driverPhone;
  final int capacity;
  final int currentPassengers;
  final String routeName;
  final String routeColor;
  final List<BusStop> stops;
  final String status; // 'offline' | 'online' | 'in_transit' | 'idle' | 'maintenance'
  final BusLocation? currentLocation;
  final int lastStopIndex;
  final int nextStopIndex;
  final int nextStopEtaMinutes;
  final String? announcement;
  final String? announcementType;
  final int? createdAt;
  final int? updatedAt;

  const Bus({
    required this.id,
    required this.busNumber,
    required this.busName,
    required this.plateNumber,
    required this.fleetCode,
    this.driverId,
    this.driverName = 'Unassigned',
    this.driverPhone,
    this.capacity = 40,
    this.currentPassengers = 0,
    this.routeName = '',
    this.routeColor = '#3b82f6',
    this.stops = const [],
    this.status = 'offline',
    this.currentLocation,
    this.lastStopIndex = 0,
    this.nextStopIndex = 0,
    this.nextStopEtaMinutes = 0,
    this.announcement,
    this.announcementType,
    this.createdAt,
    this.updatedAt,
  });

  factory Bus.fromFirestore(String docId, Map<String, dynamic> map) {
    final rawStops = map['stops'] as List<dynamic>? ?? [];
    final parsedStops = rawStops
        .map((s) => BusStop.fromMap(s as Map<String, dynamic>))
        .toList();

    return Bus(
      id: docId,
      busNumber: map['busNumber'] as String? ?? '',
      busName: map['busName'] as String? ?? '',
      plateNumber: map['plateNumber'] as String? ?? '',
      fleetCode: map['fleetCode'] as String? ?? '',
      driverId: map['driverId'] as String?,
      driverName: map['driverName'] as String? ?? 'Unassigned',
      driverPhone: map['driverPhone'] as String?,
      capacity: map['capacity'] as int? ?? 40,
      currentPassengers: map['currentPassengers'] as int? ?? 0,
      routeName: map['routeName'] as String? ?? '',
      routeColor: map['routeColor'] as String? ?? '#3b82f6',
      stops: parsedStops,
      status: map['status'] as String? ?? 'offline',
      currentLocation: map['currentLocation'] != null
          ? BusLocation.fromMap(map['currentLocation'] as Map<String, dynamic>)
          : null,
      lastStopIndex: map['lastStopIndex'] as int? ?? 0,
      nextStopIndex: map['nextStopIndex'] as int? ?? 0,
      nextStopEtaMinutes: map['nextStopEtaMinutes'] as int? ?? 0,
      announcement: map['announcement'] as String?,
      announcementType: map['announcementType'] as String?,
      createdAt: map['createdAt'] as int?,
      updatedAt: map['updatedAt'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'busNumber': busNumber,
        'busName': busName,
        'plateNumber': plateNumber,
        'fleetCode': fleetCode,
        'driverId': driverId,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'capacity': capacity,
        'currentPassengers': currentPassengers,
        'routeName': routeName,
        'routeColor': routeColor,
        'stops': stops.map((s) => s.toMap()).toList(),
        'status': status,
        'currentLocation': currentLocation?.toMap(),
        'lastStopIndex': lastStopIndex,
        'nextStopIndex': nextStopIndex,
        'nextStopEtaMinutes': nextStopEtaMinutes,
        'announcement': announcement,
        'announcementType': announcementType,
        'createdAt': createdAt ?? DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

  /// Whether the bus is actively broadcasting GPS.
  bool get isLive =>
      status == 'online' || status == 'in_transit';
}
