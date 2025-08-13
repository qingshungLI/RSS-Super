// lib/models/folder.dart
class Folder {
  final int? id;
  final String name;

  Folder({
    this.id,
    required this.name,
  });

  // 将 Folder 对象转换为 Map，以便存储到数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // 从数据库的 Map 中创建 Folder 对象
  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }
}
