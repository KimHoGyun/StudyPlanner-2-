class ChatMessage {
  final int id;
  final int studyGroupId;
  final User sender;
  final String content;
  final String messageType; // 'text', 'file', 'image', 'announcement'
  final String? fileName;
  final String? fileUrl;
  final DateTime createdAt;
  final bool isDeleted;

  ChatMessage({
    required this.id,
    required this.studyGroupId,
    required this.sender,
    required this.content,
    required this.messageType,
    this.fileName,
    this.fileUrl,
    required this.createdAt,
    this.isDeleted = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      studyGroupId: json['studyGroupId'],
      sender: User.fromJson(json['sender']),
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      fileName: json['fileName'],
      fileUrl: json['fileUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studyGroupId': studyGroupId,
      'sender': sender.toJson(),
      'content': content,
      'messageType': messageType,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'createdAt': createdAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  bool get isFile => messageType == 'file' || messageType == 'image';
  bool get isImage => messageType == 'image';
  bool get isAnnouncement => messageType == 'announcement';
}

class FileAttachment {
  final int id;
  final int studyGroupId;
  final User uploader;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;

  FileAttachment({
    required this.id,
    required this.studyGroupId,
    required this.uploader,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    return FileAttachment(
      id: json['id'],
      studyGroupId: json['studyGroupId'],
      uploader: User.fromJson(json['uploader']),
      fileName: json['fileName'],
      fileUrl: json['fileUrl'],
      fileType: json['fileType'],
      fileSize: json['fileSize'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studyGroupId': studyGroupId,
      'uploader': uploader.toJson(),
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  bool get isImage => fileType.startsWith('image/');
  bool get isPdf => fileType == 'application/pdf';
  bool get isDocument => fileType.contains('document') || fileType.contains('text');
}

class User {
  final int id;
  final String name;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}