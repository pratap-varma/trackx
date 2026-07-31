class InstitutionTenant {
  final String id;
  final String displayName;
  final String status; // 'Active', 'Suspended'
  final String primaryTimezone;

  InstitutionTenant({
    required this.id,
    required this.displayName,
    required this.status,
    required this.primaryTimezone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'status': status,
      'primaryTimezone': primaryTimezone,
    };
  }

  factory InstitutionTenant.fromMap(Map<String, dynamic> map) {
    return InstitutionTenant(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? '',
      status: map['status'] ?? 'Active',
      primaryTimezone: map['primaryTimezone'] ?? 'UTC',
    );
  }
}

class InstitutionMembership {
  final String id;
  final String institutionId;
  final String userId;
  final List<String> roleIds; // e.g. ['Student', 'Faculty']
  final String status; // 'Active', 'Revoked'

  InstitutionMembership({
    required this.id,
    required this.institutionId,
    required this.userId,
    required this.roleIds,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institutionId': institutionId,
      'userId': userId,
      'roleIds': roleIds,
      'status': status,
    };
  }

  factory InstitutionMembership.fromMap(Map<String, dynamic> map) {
    return InstitutionMembership(
      id: map['id'] ?? '',
      institutionId: map['institutionId'] ?? '',
      userId: map['userId'] ?? '',
      roleIds: List<String>.from(map['roleIds'] ?? []),
      status: map['status'] ?? 'Active',
    );
  }
}
