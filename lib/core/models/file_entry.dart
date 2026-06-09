enum FileType {
  image,
  video,
  audio,
  document,
  archive,
  code,
  executable,
  font,
  folder,
  other;

  static FileType fromString(String value) => switch (value) {
        'image' => FileType.image,
        'video' => FileType.video,
        'audio' => FileType.audio,
        'document' => FileType.document,
        'archive' => FileType.archive,
        'code' => FileType.code,
        'executable' => FileType.executable,
        'font' => FileType.font,
        'folder' => FileType.folder,
        _ => FileType.other,
      };
}

class FileEntry {
  final String name;
  final String updated;
  final FileType type;

  const FileEntry({
    required this.name,
    required this.updated,
    required this.type,
  });

  factory FileEntry.fromJson(Map<String, dynamic> json) => FileEntry(
        name: json['name'] as String,
        updated: json['updated'] as String,
        type: FileType.fromString(json['type'] as String),
      );
}
