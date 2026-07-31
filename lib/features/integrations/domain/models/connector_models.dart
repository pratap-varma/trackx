class ConnectorSpec {
  final String id;
  final String institutionId;
  final String version;
  final String authType; // 'OAuth2', 'APIKey'
  final String apiBaseUrl;
  final int rateLimitPerMinute;
  final String status; // 'Active', 'Suspended', 'Deprecated'

  ConnectorSpec({
    required this.id,
    required this.institutionId,
    required this.version,
    required this.authType,
    required this.apiBaseUrl,
    required this.rateLimitPerMinute,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institutionId': institutionId,
      'version': version,
      'authType': authType,
      'apiBaseUrl': apiBaseUrl,
      'rateLimitPerMinute': rateLimitPerMinute,
      'status': status,
    };
  }

  factory ConnectorSpec.fromMap(Map<String, dynamic> map) {
    return ConnectorSpec(
      id: map['id'] ?? '',
      institutionId: map['institutionId'] ?? '',
      version: map['version'] ?? '1.0.0',
      authType: map['authType'] ?? 'OAuth2',
      apiBaseUrl: map['apiBaseUrl'] ?? '',
      rateLimitPerMinute: map['rateLimitPerMinute'] ?? 60,
      status: map['status'] ?? 'Active',
    );
  }
}
