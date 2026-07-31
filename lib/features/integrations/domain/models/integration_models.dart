class Institution {
  final String id;
  final String name;
  final String shortName;
  final String domain;
  final bool isVerified;

  Institution({
    required this.id,
    required this.name,
    required this.shortName,
    required this.domain,
    required this.isVerified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'domain': domain,
      'isVerified': isVerified,
    };
  }

  factory Institution.fromMap(Map<String, dynamic> map) {
    return Institution(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      shortName: map['shortName'] ?? '',
      domain: map['domain'] ?? '',
      isVerified: map['isVerified'] ?? false,
    );
  }
}

class InstitutionConnection {
  final String id;
  final String userId;
  final String institutionId;
  final String connectionStatus; // 'Connected', 'Disconnected'
  final List<String> grantedScopes;
  final DateTime connectedAt;

  InstitutionConnection({
    required this.id,
    required this.userId,
    required this.institutionId,
    required this.connectionStatus,
    required this.grantedScopes,
    required this.connectedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'institutionId': institutionId,
      'connectionStatus': connectionStatus,
      'grantedScopes': grantedScopes,
      'connectedAt': connectedAt.toIso8601String(),
    };
  }

  factory InstitutionConnection.fromMap(Map<String, dynamic> map) {
    return InstitutionConnection(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      institutionId: map['institutionId'] ?? '',
      connectionStatus: map['connectionStatus'] ?? 'Disconnected',
      grantedScopes: List<String>.from(map['grantedScopes'] ?? []),
      connectedAt: DateTime.parse(
        map['connectedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class IntegrationAuditEntry {
  final String id;
  final String action;
  final String status;
  final DateTime timestamp;

  IntegrationAuditEntry({
    required this.id,
    required this.action,
    required this.status,
    required this.timestamp,
  });
}
