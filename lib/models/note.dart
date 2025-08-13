// lib/models/note.dart
class Note {
  int? id;
  String content;
  int articleId;
  String? highlightText;

  Note({
    this.id,
    required this.content,
    required this.articleId,
    this.highlightText,
  });

  // 从 Map 创建 Note 对象
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      content: map['content'],
      articleId: map['articleId'],
      highlightText: map['highlightText'],
    );
  }

  // 将 Note 对象转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'articleId': articleId,
      'highlightText': highlightText,
    };
  }
}
