// lib/models/article.dart
class Article {
  int? id;
  String title;
  String content;
  String url; // 与 feedId 组合在数据库中作为唯一键，避免重复
  String pubDate;
  int feedId; // 与 url 组合成唯一索引
  bool isRead;
  bool isFavorite;
  bool isReadLater;

  Article({
    this.id,
    required this.title,
    required this.content,
    required this.url,
    required this.pubDate,
    required this.feedId,
    this.isRead = false,
    this.isFavorite = false,
    this.isReadLater = false,
  });

  // 从 Map 创建 Article 对象
  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      url: map['url'],
      pubDate: map['pubDate'],
      feedId: map['feedId'],
      isRead: map['isRead'] == 1,
      isFavorite: map['isFavorite'] == 1,
      isReadLater: map['isReadLater'] == 1,
    );
  }

  // 将 Article 对象转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'url': url,
      'pubDate': pubDate,
      'feedId': feedId,
      'isRead': isRead ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'isReadLater': isReadLater ? 1 : 0,
    };
  }

  // 可选：按唯一键判断相等（仅用于内存去重时）
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Article && other.url == url && other.feedId == feedId;
  }

  @override
  int get hashCode => Object.hash(url, feedId);
}
