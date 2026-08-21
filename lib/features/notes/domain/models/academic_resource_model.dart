class AcademicResource {
  final String id;
  final String userId;
  final String? subjectId;
  final String? topicId;
  final String title;
  final String
  type; // 'Note', 'Link', 'Video', 'PDF', 'Image', 'Document', 'Practice Set', 'Past Paper', 'Book', 'Other'
  final String? url;
  final String? localFilePath;
  final String? cloudFileReference;
  final String? description;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  AcademicResource({
    required this.id,
    required this.userId,
    this.subjectId,
    this.topicId,
    required this.title,
    required this.type,
    this.url,
    this.localFilePath,
    this.cloudFileReference,
    this.description,
    required this.tags,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  AcademicResource copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? topicId,
    String? title,
    String? type,
    String? url,
    String? localFilePath,
    String? cloudFileReference,
    String? description,
    List<String>? tags,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcademicResource(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      type: type ?? this.type,
      url: url ?? this.url,
      localFilePath: localFilePath ?? this.localFilePath,
      cloudFileReference: cloudFileReference ?? this.cloudFileReference,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subjectId': subjectId,
      'topicId': topicId,
      'title': title,
      'type': type,
      'url': url,
      'localFilePath': localFilePath,
      'cloudFileReference': cloudFileReference,
      'description': description,
      'tags': tags,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AcademicResource.fromMap(Map<String, dynamic> map) {
    return AcademicResource(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      subjectId: map['subjectId'],
      topicId: map['topicId'],
      title: map['title'] ?? '',
      type: map['type'] ?? 'Other',
      url: map['url'],
      localFilePath: map['localFilePath'],
      cloudFileReference: map['cloudFileReference'],
      description: map['description'],
      tags: List<String>.from(map['tags'] ?? []),
      isFavorite: map['isFavorite'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
