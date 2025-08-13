// lib/providers/app_state_provider.dart
import 'package:flutter/material.dart';

// 导入所有必需的模型类
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/models/rss_feed.dart';
import 'package:rss_reader/models/folder.dart';
import 'package:rss_reader/models/note.dart';
import 'package:rss_reader/models/video.dart';
import 'package:rss_reader/database/database_helper.dart';
import 'package:rss_reader/services/rss_service.dart';


class AppStateProvider with ChangeNotifier {
  // 数据库助手实例
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  // RSS服务实例
  final RssService _rssService = RssService();

  // 状态数据
  List<RssFeed> _feeds = [];
  List<Article> _articles = [];
  List<Folder> _folders = [];
  List<Video> _videos = [];
  List<Note> _notes = [];
  bool _isSyncing = false;

  // 获取状态数据的方法
  List<RssFeed> get feeds => _feeds;
  List<Article> get articles => _articles;
  List<Folder> get folders => _folders;
  List<Video> get videos => _videos;
  List<Note> get notes => _notes;
  bool get isSyncing => _isSyncing;

  // 初始化方法，在应用启动时调用
  Future<void> initialize() async {
    await _loadFeeds();
    await _loadFolders();
    await _loadArticles();
    await _loadVideos();
    await _loadNotes();
  }

  // 加载 feeds
  Future<void> _loadFeeds() async {
    final feedsFromDb = await _dbHelper.getFeeds();
    _feeds = feedsFromDb.map((map) => RssFeed.fromMap(map)).toList();
    notifyListeners();
  }
  
  // 加载文件夹
  Future<void> _loadFolders() async {
    final foldersFromDb = await _dbHelper.getFolders();
    _folders = foldersFromDb.map((map) => Folder.fromMap(map)).toList();
    notifyListeners();
  }
  
  // 加载文章
  Future<void> _loadArticles() async {
    _articles = await _dbHelper.getArticles();
    notifyListeners();
  }

  // 加载视频
  Future<void> _loadVideos() async {
    final videosFromDb = await _dbHelper.getVideos();
    _videos = videosFromDb.map((map) => Video.fromMap(map)).toList();
    notifyListeners();
  }

  // 加载笔记
  Future<void> _loadNotes() async {
    final notesFromDb = await _dbHelper.getNotes();
    _notes = notesFromDb.map((map) => Note.fromMap(map)).toList();
    notifyListeners();
  }

  // 添加新的 RSS Feed
  Future<void> addFeed(RssFeed feed) async {
    final int insertedId = await _dbHelper.insertFeed(feed.toMap());
    await _loadFeeds();
    // 立即同步新添加的 Feed，使用插入后获得的自增ID
    final RssFeed feedWithId = RssFeed(
      id: insertedId,
      title: feed.title,
      url: feed.url,
      folderId: feed.folderId,
    );
    await syncFeed(feedWithId);
  }

  // 同步单个 RSS Feed
  Future<void> syncFeed(RssFeed feed) async {
    // 检查 feed.id 是否为 null
    if (feed.id == null) {
      print('Error: Feed ID is null, cannot sync.');
      return;
    }
    final result = await _rssService.fetchContent(feed.url, feed.id!);
    // 插入新文章
    for (var article in result.articles) {
      await _dbHelper.insertArticle(article);
    }
    // 插入新视频
    for (var video in result.videos) {
      await _dbHelper.insertVideo(video.toMap());
    }
    await _loadArticles();
    await _loadVideos();
  }
  
  // 同步所有 RSS Feed
  Future<void> syncAllFeeds() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();
    try {
      for (var feed in _feeds) {
        await syncFeed(feed);
        // 节流，避免触发对方 429 频率限制
        await Future.delayed(const Duration(seconds: 2));
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // 删除 Feed
  Future<void> deleteFeed(int id) async {
    // 先删除该订阅源下的所有文章和视频
    await _dbHelper.deleteArticlesByFeedId(id);
    await _dbHelper.deleteVideosByFeedId(id);
    // 然后删除订阅源本身
    await _dbHelper.deleteFeed(id);
    _articles.removeWhere((article) => article.feedId == id);
    _videos.removeWhere((video) => video.feedId == id);
    _feeds.removeWhere((feed) => feed.id == id);
  
  // 通知所有监听者，状态已更新
  notifyListeners();
  }
  
  // 更新 Feed
  Future<void> updateFeed(RssFeed feed) async {
    await _dbHelper.updateFeed(feed.toMap());
    await _loadFeeds();
  }

  // 添加文件夹
  Future<void> addFolder(Folder folder) async {
    await _dbHelper.insertFolder(folder.toMap());
    await _loadFolders();
  }

  // 删除文件夹
  Future<void> deleteFolder(int id) async {
    // 先删除该文件夹下所有订阅源的文章和视频
    await _dbHelper.deleteArticlesByFolderId(id);
    await _dbHelper.deleteVideosByFolderId(id);
    // 然后删除文件夹本身
    await _dbHelper.deleteFolder(id);
    await _loadFolders();
    await _loadFeeds(); // 删除文件夹后也需要重新加载 feeds
    await _loadArticles(); // 删除文件夹后也需要重新加载文章列表
    await _loadVideos(); // 删除文件夹后也需要重新加载视频列表
  }

  // 更新文件夹
  Future<void> updateFolder(Folder folder) async {
    await _dbHelper.updateFolder(folder.toMap());
    await _loadFolders();
  }
  
  // 标记文章为已读
  Future<void> markArticleAsRead(Article article) async {
    final updatedArticle = Article(
      id: article.id,
      title: article.title,
      content: article.content,
      url: article.url,
      pubDate: article.pubDate,
      feedId: article.feedId,
      isRead: true,
    );
    // 这里调用了更新方法
    await _dbHelper.updateArticle(updatedArticle);
    await _loadArticles();
  }

  // 搜索文章
  Future<List<Article>> searchArticles(String query) async {
    final articlesFromDb = await _dbHelper.searchArticles(query);
    return articlesFromDb.map((map) => Article.fromMap(map)).toList();
  }

   // 新增：添加笔记
  Future<void> addNote(Note note) async {
    await _dbHelper.insertNote(note.toMap());
    await _loadNotes(); // 重新加载笔记列表
  }

  // 删除笔记
  Future<void> deleteNote(int id) async {
    await _dbHelper.deleteNote(id);
    await _loadNotes();
  }
  
  // 更新笔记
  Future<void> updateNote(Note note) async {
    await _dbHelper.updateNote(note.toMap());
    await _loadNotes();
  }
    // 切换文章的收藏状态
  Future<void> toggleFavoriteStatus(Article article) async {
    article.isFavorite = !article.isFavorite;
    await _dbHelper.updateArticle(article);
    notifyListeners();
  }

  // 切换文章的稍后再看状态
  Future<void> toggleReadLaterStatus(Article article) async {
    article.isReadLater = !article.isReadLater;
    await _dbHelper.updateArticle(article);
    notifyListeners();
  }

  // 删除单篇文章
  Future<void> deleteArticleById(int id) async {
    await _dbHelper.deleteArticle(id);
    _articles.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
  extension UnreadCountExtension on AppStateProvider {
  // 获取某个 Feed 的未读文章数量
  int unreadCountForFeed(RssFeed feed) {
    return articles.where((a) => a.feedId == feed.id && !a.isRead).length;
  }

  // 计算指定文件夹的未读文章数量
 int unreadCountForFolder(Folder folder, AppStateProvider appState) {
  // 找到该文件夹下的所有 Feed
  final feedsInFolder = appState.feeds.where((feed) => feed.folderId == folder.id).toList();

  // 对每个 Feed 统计未读文章数量并累加
  int count = 0;
  for (var feed in feedsInFolder) {
    count += appState.articles.where((a) => a.feedId == feed.id && !a.isRead).length;
  }

  return count;
}
  }