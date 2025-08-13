// lib/models/video.dart
class Video {
  final int? id;
  final String url;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final List<String> tags;
  final int feedId;

  Video({
    this.id,
    required this.url,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.tags,
    required this.feedId,
  });

  // 将 Video 对象转换为 Map，以便存储到数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'tags': tags.join(','), // 将标签列表转换为逗号分隔的字符串
      'feedId': feedId,
    };
  }

  // 从数据库的 Map 中创建 Video 对象
  factory Video.fromMap(Map<String, dynamic> map) {
    return Video(
      id: map['id'] as int?,
      url: map['url'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      tags: (map['tags'] as String).split(','), // 将逗号分隔的字符串转换回列表
      feedId: map['feedId'] as int,
    );
  }
}
