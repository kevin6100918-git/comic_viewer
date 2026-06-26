enum FileType {
  image,
  video,
  audio,
  document,
  folder,
  other;

  static FileType fromFileType(String? fileType) => switch (fileType) {
        'image' => FileType.image,
        'video' => FileType.video,
        'audio' => FileType.audio,
        'pdf' => FileType.document,
        'document' => FileType.document,
        _ => FileType.other,
      };
}

class FileEntry {
  final String name;
  final String updated;
  final double? ctime;
  final FileType type;

  const FileEntry({
    required this.name,
    required this.updated,
    required this.ctime,
    required this.type,
  });

  factory FileEntry.fromJson(Map<String, dynamic> json) {
    final isDir = json['type'] == 'dir';
    return FileEntry(
      name: json['name'] as String,
      updated: json['updated']?.toString() ?? '',
      ctime: (json['ctime'] as num?)?.toDouble(),
      type: isDir
          ? FileType.folder
          : FileType.fromFileType(json['file_type'] as String?),
    );
  }
}
