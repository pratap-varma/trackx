class StudentGroup {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String institutionId;
  final String visibility; // 'Private', 'Discoverable'
  final int memberLimit;

  StudentGroup({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.institutionId,
    required this.visibility,
    required this.memberLimit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'institutionId': institutionId,
      'visibility': visibility,
      'memberLimit': memberLimit,
    };
  }

  factory StudentGroup.fromMap(Map<String, dynamic> map) {
    return StudentGroup(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      institutionId: map['institutionId'] ?? '',
      visibility: map['visibility'] ?? 'Private',
      memberLimit: map['memberLimit'] ?? 10,
    );
  }
}

class GroupMembership {
  final String groupId;
  final String userId;
  final String role; // 'Owner', 'Moderator', 'Member'
  final String status; // 'Active', 'Banned'

  GroupMembership({
    required this.groupId,
    required this.userId,
    required this.role,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'userId': userId,
      'role': role,
      'status': status,
    };
  }

  factory GroupMembership.fromMap(Map<String, dynamic> map) {
    return GroupMembership(
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? '',
      role: map['role'] ?? 'Member',
      status: map['status'] ?? 'Active',
    );
  }
}
