class Partner {
  final String id;
  final String legalName;
  final String displayName;
  final String partnerType; // 'Institution', 'EducationalContent'
  final String verificationStatus; // 'Approved', 'UnderReview', 'Suspended'
  final List<String> approvedScopes;

  Partner({
    required this.id,
    required this.legalName,
    required this.displayName,
    required this.partnerType,
    required this.verificationStatus,
    required this.approvedScopes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'legalName': legalName,
      'displayName': displayName,
      'partnerType': partnerType,
      'verificationStatus': verificationStatus,
      'approvedScopes': approvedScopes,
    };
  }

  factory Partner.fromMap(Map<String, dynamic> map) {
    return Partner(
      id: map['id'] ?? '',
      legalName: map['legalName'] ?? '',
      displayName: map['displayName'] ?? '',
      partnerType: map['partnerType'] ?? 'Institution',
      verificationStatus: map['verificationStatus'] ?? 'UnderReview',
      approvedScopes: List<String>.from(map['approvedScopes'] ?? []),
    );
  }
}
