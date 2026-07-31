class ApiClient {
  final String id;
  final String ownerId;
  final String applicationName;
  final List<String> redirectUris;
  final List<String> approvedScopes;
  final String status; // 'Active', 'Suspended'

  ApiClient({
    required this.id,
    required this.ownerId,
    required this.applicationName,
    required this.redirectUris,
    required this.approvedScopes,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'applicationName': applicationName,
      'redirectUris': redirectUris,
      'approvedScopes': approvedScopes,
      'status': status,
    };
  }

  factory ApiClient.fromMap(Map<String, dynamic> map) {
    return ApiClient(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      applicationName: map['applicationName'] ?? '',
      redirectUris: List<String>.from(map['redirectUris'] ?? []),
      approvedScopes: List<String>.from(map['approvedScopes'] ?? []),
      status: map['status'] ?? 'Active',
    );
  }
}
