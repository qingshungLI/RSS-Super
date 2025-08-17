// lib/database/database_helper.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/models/folder.dart';
import 'package:rss_reader/models/rss_feed.dart';
import 'package:rss_reader/models/video.dart';
import 'package:rss_reader/models/note.dart';
class DatabaseHelper {
  static final _databaseName = "rss_reader.db";
  static final _databaseVersion = 3; // 将数据库版本号更新为3

  // 表名
  static final tableArticles = 'articles';
  static final tableFeeds = 'feeds';
  static final tableFolders = 'folders';
  static final tableVideos = 'videos';
  static final tableNotes = 'notes';

  // Articles 表字段
  static final columnArticleId = 'id';
  static final columnArticleTitle = 'title';
  static final columnArticleContent = 'content';
  static final columnArticleUrl = 'url';
  static final columnArticlePubDate = 'pubDate';
  static final columnArticleFeedId = 'feedId';
  static final columnArticleIsRead = 'isRead';
  static final columnArticleIsFavorite = 'isFavorite'; // 新增的收藏字段
  static final columnArticleIsReadLater = 'isReadLater'; // 新增的稍后再看字段

  // Feeds 表字段
  static final columnFeedId = 'id';
  static final columnFeedTitle = 'title';
  static final columnFeedUrl = 'url';
  static final columnFeedFolderId = 'folderId';

  // Folders 表字段
  static final columnFolderId = 'id';
  static final columnFolderName = 'name';

  // Videos 表字段
  static final columnVideoId = 'id';
  static final columnVideoTitle = 'title';
  static final columnVideoUrl = 'url';
  static final columnVideoThumbnail = 'thumbnail';
  static final columnVideoFeedId = 'feedId';

// Notes 表字段
  static final columnNoteId = 'id';
  static final columnNoteContent = 'content';
  static final columnNoteArticleId = 'articleId';
  static final columnNoteHighlightText = 'highlightText';

  // 私有的命名构造函数
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // 数据库实例
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // 添加数据库升级回调
    );
  }

  // 创建数据库表
  Future _onCreate(Database db, int version) async {
    // 创建 articles 表
    await db.execute('''
      CREATE TABLE $tableArticles (
        $columnArticleId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnArticleTitle TEXT NOT NULL,
        $columnArticleContent TEXT NOT NULL,
        $columnArticleUrl TEXT NOT NULL,
        $columnArticlePubDate TEXT NOT NULL,
        $columnArticleFeedId INTEGER NOT NULL,
        $columnArticleIsRead INTEGER NOT NULL DEFAULT 0,
        $columnArticleIsFavorite INTEGER NOT NULL DEFAULT 0,
        $columnArticleIsReadLater INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // 创建 feeds 表
    await db.execute('''
      CREATE TABLE $tableFeeds (
        $columnFeedId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnFeedTitle TEXT NOT NULL,
        $columnFeedUrl TEXT NOT NULL,
        $columnFeedFolderId INTEGER
      )
    ''');
    // 创建 folders 表
    await db.execute('''
      CREATE TABLE $tableFolders (
        $columnFolderId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnFolderName TEXT NOT NULL
      )
    ''');
    // 创建 videos 表
    await db.execute('''
      CREATE TABLE $tableVideos (
        $columnVideoId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnVideoTitle TEXT NOT NULL,
        $columnVideoUrl TEXT NOT NULL,
        $columnVideoThumbnail TEXT,
        $columnVideoFeedId INTEGER NOT NULL
      )
    ''');
    // 创建 notes 表
    await db.execute('''
      CREATE TABLE $tableNotes (
        $columnNoteId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnNoteContent TEXT NOT NULL,
        $columnNoteArticleId INTEGER NOT NULL,
        $columnNoteHighlightText TEXT
      )
    ''');

    // 为文章添加唯一索引，避免重复（同一 feed 下的相同 URL 视为同一篇）
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_articles_url_feed ON $tableArticles($columnArticleUrl, $columnArticleFeedId)');
  }

  // 数据库升级方法
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 从版本1升级到版本2，添加新字段
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE $tableArticles ADD COLUMN $columnArticleIsFavorite INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE $tableArticles ADD COLUMN $columnArticleIsReadLater INTEGER DEFAULT 0");
    }
    // 从版本2升级到版本3，清理重复并添加唯一索引
    if (oldVersion < 3) {
      // 删除同一 (url, feedId) 的重复文章，保留 id 最大的一条
      await db.execute('''
        DELETE FROM $tableArticles
        WHERE $columnArticleId NOT IN (
          SELECT MAX($columnArticleId) FROM $tableArticles GROUP BY $columnArticleUrl, $columnArticleFeedId
        )
      ''');
      // 添加唯一索引
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_articles_url_feed ON $tableArticles($columnArticleUrl, $columnArticleFeedId)');
    }
  }

  // 插入数据
  Future<int> insertArticle(Article article) async {
    final Database db = await instance.database;
    // 使用 UPSERT，避免重复，并尽量保留已读/收藏/稍后再看等状态
    final sql = '''
      INSERT INTO $tableArticles (
        $columnArticleTitle,
        $columnArticleContent,
        $columnArticleUrl,
        $columnArticlePubDate,
        $columnArticleFeedId,
        $columnArticleIsRead,
        $columnArticleIsFavorite,
        $columnArticleIsReadLater
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT($columnArticleUrl, $columnArticleFeedId) DO UPDATE SET
        $columnArticleTitle=excluded.$columnArticleTitle,
        $columnArticleContent=excluded.$columnArticleContent,
        $columnArticlePubDate=excluded.$columnArticlePubDate,
        $columnArticleIsRead=MAX($tableArticles.$columnArticleIsRead, excluded.$columnArticleIsRead),
        $columnArticleIsFavorite=MAX($tableArticles.$columnArticleIsFavorite, excluded.$columnArticleIsFavorite),
        $columnArticleIsReadLater=MAX($tableArticles.$columnArticleIsReadLater, excluded.$columnArticleIsReadLater)
    ''';
    return await db.rawInsert(sql, [
      article.title,
      article.content,
      article.url,
      article.pubDate,
      article.feedId,
      article.isRead ? 1 : 0,
      article.isFavorite ? 1 : 0,
      article.isReadLater ? 1 : 0,
    ]);
  }
  Future<int> insertFeed(Map<String, dynamic> feed) async {
    Database db = await instance.database;
    return await db.insert(tableFeeds, feed, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  Future<int> insertFolder(Map<String, dynamic> folder) async {
    Database db = await instance.database;
    return await db.insert(tableFolders, folder, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  Future<int> insertVideo(Map<String, dynamic> video) async {
    Database db = await instance.database;
    return await db.insert(tableVideos, video, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  Future<int> insertNote(Map<String, dynamic> note) async {
    Database db = await instance.database;
    return await db.insert(tableNotes, note, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // 查询数据
  Future<List<Article>> getArticles() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableArticles);
    return List.generate(maps.length, (i) {
      return Article.fromMap(maps[i]);
    });
  }
  Future<List<Map<String, dynamic>>> getFeeds() async {
    Database db = await instance.database;
    return await db.query(tableFeeds);
  }
  Future<List<Map<String, dynamic>>> getFolders() async {
    Database db = await instance.database;
    return await db.query(tableFolders);
  }
  Future<List<Map<String, dynamic>>> getVideos() async {
    Database db = await instance.database;
    return await db.query(tableVideos);
  }
  Future<List<Map<String, dynamic>>> getNotes() async {
    Database db = await instance.database;
    return await db.query(tableNotes);
  }
  Future<List<Map<String, dynamic>>> searchArticles(String query) async {
    Database db = await instance.database;
    return await db.query(
      tableArticles,
      where: "$columnArticleTitle LIKE ?",
      whereArgs: ['%$query%'],
    );
  }

  // 更新数据
  Future<int> updateFeed(Map<String, dynamic> feed) async {
    Database db = await instance.database;
    int id = feed[columnFeedId];
    return await db.update(
      tableFeeds,
      feed,
      where: '$columnFeedId = ?',
      whereArgs: [id],
    );
  }
  Future<int> updateFolder(Map<String, dynamic> folder) async {
    Database db = await instance.database;
    int id = folder[columnFolderId];
    return await db.update(
      tableFolders,
      folder,
      where: '$columnFolderId = ?',
      whereArgs: [id],
    );
  }

  // 新增的 updateArticle 方法
  Future<int> updateArticle(Article article) async {
    Database db = await instance.database;
    int? id = article.id;
    if (id != null) {
      return await db.update(
        tableArticles,
        article.toMap(),
        where: '$columnArticleId = ?',
        whereArgs: [id],
      );
    }
    return 0;
  }

  // 删除数据
  Future<int> deleteArticle(int id) async {
    Database db = await instance.database;
    return await db.delete(
      tableArticles,
      where: '$columnArticleId = ?',
      whereArgs: [id],
    );
  }
  
  // 根据订阅源ID删除相关文章
  Future<int> deleteArticlesByFeedId(int feedId) async {
    Database db = await instance.database;
    return await db.delete(
      tableArticles,
      where: '$columnArticleFeedId = ?',
      whereArgs: [feedId],
    );
  }
  
  // 根据订阅源ID删除相关视频
  Future<int> deleteVideosByFeedId(int feedId) async {
    Database db = await instance.database;
    return await db.delete(
      tableVideos,
      where: '$columnVideoFeedId = ?',
      whereArgs: [feedId],
    );
  }
  
  // 根据文件夹ID删除相关文章（通过该文件夹下的所有订阅源）
  Future<int> deleteArticlesByFolderId(int folderId) async {
    Database db = await instance.database;
    // 先获取该文件夹下的所有订阅源ID
    final List<Map<String, dynamic>> feeds = await db.query(
      tableFeeds,
      where: '$columnFeedFolderId = ?',
      whereArgs: [folderId],
      columns: [columnFeedId],
    );
    
    if (feeds.isEmpty) return 0;
    
    // 提取订阅源ID列表
    final List<int> feedIds = feeds.map((feed) => feed[columnFeedId] as int).toList();
    
    // 删除这些订阅源下的所有文章
    return await db.delete(
      tableArticles,
      where: '$columnArticleFeedId IN (${List.filled(feedIds.length, '?').join(',')})',
      whereArgs: feedIds,
    );
  }
  
  // 根据文件夹ID删除相关视频（通过该文件夹下的所有订阅源）
  Future<int> deleteVideosByFolderId(int folderId) async {
    Database db = await instance.database;
    // 先获取该文件夹下的所有订阅源ID
    final List<Map<String, dynamic>> feeds = await db.query(
      tableFeeds,
      where: '$columnFeedFolderId = ?',
      whereArgs: [folderId],
      columns: [columnFeedId],
    );
    
    if (feeds.isEmpty) return 0;
    
    // 提取订阅源ID列表
    final List<int> feedIds = feeds.map((feed) => feed[columnFeedId] as int).toList();
    
    // 删除这些订阅源下的所有视频
    return await db.delete(
      tableVideos,
      where: '$columnVideoFeedId IN (${List.filled(feedIds.length, '?').join(',')})',
      whereArgs: feedIds,
    );
  }
  
  Future<int> deleteFeed(int id) async {
    Database db = await instance.database;
    return await db.delete(
      tableFeeds,
      where: '$columnFeedId = ?',
      whereArgs: [id],
    );
  }
  Future<int> deleteFolder(int id) async {
    Database db = await instance.database;
    return await db.delete(
      tableFolders,
      where: '$columnFolderId = ?',
      whereArgs: [id],
    );
  }
  Future<int> deleteVideo(int id) async {
    Database db = await instance.database;
    return await db.delete(
      tableVideos,
      where: '$columnVideoId = ?',
      whereArgs: [id],
    );
  }
  Future<int> deleteNote(int id) async {
    Database db = await instance.database;
    return await db.delete(
      tableNotes,
      where: '$columnNoteId = ?',
      whereArgs: [id],
    );
  }

  // 更新 Note
  Future<int> updateNote(Map<String, dynamic> note) async {
    Database db = await instance.database;
    final int? id = note[columnNoteId] as int?;
    if (id == null) return 0;
    return await db.update(
      tableNotes,
      note,
      where: '$columnNoteId = ?',
      whereArgs: [id],
    );
  }
}
