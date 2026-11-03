/// Image attachment attached to a waste report.
class ReportImage {
  final String uuid;
  final String url;
  final String? originalFilename;
  final String? mimeType;
  final int? fileSize;
  final DateTime? createdAt;

  const ReportImage({
    required this.uuid,
    required this.url,
    this.originalFilename,
    this.mimeType,
    this.fileSize,
    this.createdAt,
  });

  factory ReportImage.fromJson(Map<String, dynamic> json) {
    return ReportImage(
      uuid: json['uuid'] as String? ?? '',
      url: json['url'] as String? ?? '',
      originalFilename: json['original_filename'] as String?,
      mimeType: json['mime_type'] as String?,
      fileSize: json['file_size'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'url': url,
    'original_filename': originalFilename,
    'mime_type': mimeType,
    'file_size': fileSize,
    'created_at': createdAt?.toIso8601String(),
  };
}
