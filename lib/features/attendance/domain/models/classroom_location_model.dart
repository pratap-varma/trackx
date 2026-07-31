class ClassroomLocation {
  final String id;
  final String userId;
  final String semesterId;
  final String? subjectId;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? building;
  final String? room;
  final bool isEnabled;
  final int createdAt;
  final int updatedAt;

  ClassroomLocation({
    required this.id,
    required this.userId,
    required this.semesterId,
    this.subjectId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.building,
    this.room,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'semesterId': semesterId,
      'subjectId': subjectId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'building': building,
      'room': room,
      'isEnabled': isEnabled,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ClassroomLocation.fromMap(Map<String, dynamic> map) {
    return ClassroomLocation(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      subjectId: map['subjectId'],
      name: map['name'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 50.0,
      building: map['building'],
      room: map['room'],
      isEnabled: map['isEnabled'] ?? true,
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
    );
  }
}
