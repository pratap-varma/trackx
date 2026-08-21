class SubscriptionEntitlement {
  final String id;
  final String ownerId;
  final String planId; // 'Free', 'ProStudent'
  final String status; // 'Active', 'GracePeriod', 'Expired'
  final DateTime expiresAt;

  SubscriptionEntitlement({
    required this.id,
    required this.ownerId,
    required this.planId,
    required this.status,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'planId': planId,
      'status': status,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory SubscriptionEntitlement.fromMap(Map<String, dynamic> map) {
    return SubscriptionEntitlement(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      planId: map['planId'] ?? 'Free',
      status: map['status'] ?? 'Active',
      expiresAt: DateTime.parse(
        map['expiresAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
