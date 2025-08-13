// lib/models/rss_feed.dart
class RssFeed {
  final int? id;
  final String title;
  final String url;
  final int? folderId;

  RssFeed({
    this.id,
    required this.title,
    required this.url,
    this.folderId,
  });

  // 将 RssFeed 对象转换为 Map，以便存储到数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'folderId': folderId,
    };
  }

  // 从数据库的 Map 中创建 RssFeed 对象
  factory RssFeed.fromMap(Map<String, dynamic> map) {
    return RssFeed(
      id: map['id'] as int?,
      title: map['title'] as String,
      url: map['url'] as String,
      folderId: map['folderId'] as int?,
    );
  }
}
