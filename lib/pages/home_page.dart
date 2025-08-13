// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/providers/app_state_provider.dart';
import 'package:rss_reader/models/rss_feed.dart';
import 'package:rss_reader/models/folder.dart';
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/pages/article_reader_page.dart';
import 'package:rss_reader/pages/notes_page.dart';
import 'package:rss_reader/pages/videos_page.dart';
import 'package:rss_reader/pages/settings_page.dart';
import 'package:rss_reader/pages/search_page.dart';
import 'package:rss_reader/dialogs/add_feed_dialog.dart';
import 'package:rss_reader/dialogs/add_folder_dialog.dart';
import 'package:rss_reader/pages/webview_page.dart';
import 'package:rss_reader/pages/looklater_page.dart';
import 'package:rss_reader/pages/using_page.dart';
import 'package:rss_reader/pages/subscription_sources_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 当前选中的文章分类
  String _currentFilter = 'all'; // 'all', 'read_later', 'feedId', 'folderId'
  int? _currentFilterId;
  
  // 时间筛选选项
  String _timeFilter = 'all'; // 'all', 'today', 'yesterday', 'week', 'month'

  @override
  void initState() {
    super.initState();
    // 页面加载时初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppStateProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          // 时间筛选按钮
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            tooltip: '时间筛选',
            onSelected: (String value) {
              setState(() {
                _timeFilter = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, size: 20),
                    SizedBox(width: 8),
                    Text('全部时间'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'today',
                child: Row(
                  children: [
                    Icon(Icons.today, size: 20),
                    SizedBox(width: 8),
                    Text('今天'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'yesterday',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 8),
                    Text('昨天'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'week',
                child: Row(
                  children: [
                    Icon(Icons.view_week, size: 20),
                    SizedBox(width: 8),
                    Text('本周'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'month',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 20),
                    SizedBox(width: 8),
                    Text('本月'),
                  ],
                ),
              ),
            ],
          ),
          // 搜索按钮
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
          ),
          // 同步按钮
          Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              return IconButton(
                icon: Icon(Icons.sync),
                onPressed: () {
                  // 调用状态管理中的同步方法
                  appState.syncAllFeeds();
                  print("同步按钮被点击");
                },
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context), // 侧栏
      body: _buildBody(context), // 主内容区
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.rss_feed),
                      title: const Text('添加订阅源'),
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => AddFeedDialog(),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.create_new_folder),
                      title: const Text('新建文件夹'),
                      onTap: () async {
                        Navigator.pop(context);
                        // 复用新增文件夹对话框
                        await showDialog(
                          context: context,
                          builder: (_) => AddFolderDialog(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  // 侧栏部分
  Widget _buildDrawer(BuildContext context) {
    // 使用 Consumer 来监听 AppStateProvider 的变化
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Text(
                  'RSS Super',
                  style: TextStyle(color: const Color.fromARGB(255, 46, 23, 179), fontSize: 24),
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 194, 243, 33),
                ),
              ),
              // “所有” 文章入口
              ListTile(
                leading: Icon(Icons.article),
                title: Text('所有文章'),
                onTap: () {
                  setState(() {
                    _currentFilter = 'all';
                    _currentFilterId = null;
                  });
                  Navigator.pop(context); // 关闭侧栏
                },
              ),
              Divider(),
              // 文件夹列表
              ...appState.folders.map((folder) => _buildFolderTile(folder, appState)),
              Divider(),
              // 特殊入口
              ListTile(
                leading: Icon(Icons.bookmark),
                title: Text('笔记'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotesPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.star),
                title: Text('收藏'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VideosPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.watch_later),
                title: Text('稍后再看'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LookLaterPage()),
                  );
                },
              ),
              Divider(),
              // 设置按钮
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('设置'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
              ),
              Divider(),
                             // 订阅源管理按钮
               ListTile(
                 leading: Icon(Icons.rss_feed),
                 title: Text('订阅源'),
                 onTap: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => SubscriptionSourcesPage()),
                   );
                 },
               ),
               // 使用说明按钮
               ListTile(
                 leading: Icon(Icons.help_outline),
                 title: Text('使用说明'),
                 onTap: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => UsingPage()),
                   );
                 },
               ),
               SizedBox(height: 46)
            ],
          ),
        );
      },
    );
  }

  // 构建文件夹和其下的 Feed 列表
  Widget _buildFolderTile(Folder folder, AppStateProvider appState) {
    final feedsInFolder = appState.feeds.where((feed) => feed.folderId == folder.id).toList();

    return Dismissible(
      key: ValueKey('folder_${folder.id ?? folder.name}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Row(
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text('删除文件夹', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('将删除文件夹“${folder.name}”及其所有订阅源，确定继续？'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) async {
        if (folder.id != null) {
          await appState.deleteFolder(folder.id!);
        }
      },
     child: ExpansionTile(
  leading: Stack(
    clipBehavior: Clip.none,
    children: [
      const Icon(Icons.folder),
      Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          int unread = appState.unreadCountForFolder(folder,appState);
          return unread > 0
              ? Positioned(
                  right: -2, // 调整位置
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : const SizedBox.shrink();
        },
      ),
    ],
  ),
  title: Text(folder.name),
  children: feedsInFolder.map((feed) => _buildFeedTile(feed)).toList(),
),

    );
  }

  // 构建单个 Feed 列表项
  Widget _buildFeedTile(RssFeed feed) {
    return Dismissible(
      key: ValueKey('feed_${feed.id ?? feed.title}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Row(
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text('删除订阅', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('将删除订阅“${feed.title}”，确定继续？'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) async {
        if (feed.id != null) {
          await Provider.of<AppStateProvider>(context, listen: false).deleteFeed(feed.id!);
        }
      },
    child: ListTile(
  leading: Stack(
    clipBehavior: Clip.none,
    children: [
      const Icon(Icons.rss_feed),
      Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          int unread = appState.unreadCountForFeed(feed);
          return unread > 0
              ? Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : const SizedBox.shrink();
        },
      ),
    ],
  ),
  title: Text(feed.title),
  onTap: () {
    setState(() {
      _currentFilter = 'feedId';
      _currentFilterId = feed.id;
    });
    Navigator.pop(context);
  },
),


    );
  }

  // 获取AppBar标题
  String _getAppBarTitle() {
    String baseTitle = "RSS Super";
    if (_timeFilter != 'all') {
      String timeText = '';
      switch (_timeFilter) {
        case 'today':
          timeText = '今天';
          break;
        case 'yesterday':
          timeText = '昨天';
          break;
        case 'week':
          timeText = '本周';
          break;
        case 'month':
          timeText = '本月';
          break;
      }
      return "$baseTitle - $timeText";
    }
    return baseTitle;
  }

  // 检查文章是否在指定的时间范围内
  bool _isArticleInTimeRange(Article article) {
    if (_timeFilter == 'all') return true;
    
    try {
      DateTime? articleDate = _parseDate(article.pubDate);
      if (articleDate == null) return false;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      switch (_timeFilter) {
        case 'today':
          final articleDay = DateTime(articleDate.year, articleDate.month, articleDate.day);
          return articleDay.isAtSameMomentAs(today);
        case 'yesterday':
          final yesterday = today.subtract(Duration(days: 1));
          final articleDay = DateTime(articleDate.year, articleDate.month, articleDate.day);
          return articleDay.isAtSameMomentAs(yesterday);
        case 'week':
          final weekAgo = today.subtract(Duration(days: 7));
          return articleDate.isAfter(weekAgo);
        case 'month':
          final monthAgo = DateTime(now.year, now.month - 1, now.day);
          return articleDate.isAfter(monthAgo);
        default:
          return true;
      }
    } catch (e) {
      return false;
    }
  }

  // 解析日期字符串为DateTime对象
  DateTime? _parseDate(String pubDate) {
    try {
      // 尝试解析 ISO 8601 格式
      if (pubDate.contains('T') && pubDate.contains('Z')) {
        return DateTime.parse(pubDate);
      }
      // 尝试解析 RFC 822 格式 (RSS 标准格式)
      else if (pubDate.contains(',')) {
        // 例如: "Mon, 25 Dec 2023 10:30:00 +0000"
        final parts = pubDate.split(', ');
        if (parts.length >= 2) {
          final datePart = parts[1];
          final timePart = parts.length > 2 ? parts[2] : '';
          final fullDate = '$datePart $timePart';
          return DateTime.tryParse(fullDate);
        }
      }
      // 尝试直接解析
      else {
        return DateTime.tryParse(pubDate);
      }
    } catch (e) {
      // 如果解析失败，返回null
    }
    return null;
  }

  // 格式化日期显示
  String _formatDate(String pubDate) {
    try {
      // 尝试解析常见的日期格式
      DateTime? dateTime;
      
      // 尝试解析 ISO 8601 格式
      if (pubDate.contains('T') && pubDate.contains('Z')) {
        dateTime = DateTime.parse(pubDate);
      }
      // 尝试解析 RFC 822 格式 (RSS 标准格式)
      else if (pubDate.contains(',')) {
        // 例如: "Mon, 25 Dec 2023 10:30:00 +0000"
        final parts = pubDate.split(', ');
        if (parts.length >= 2) {
          final datePart = parts[1];
          final timePart = parts.length > 2 ? parts[2] : '';
          final fullDate = '$datePart $timePart';
          dateTime = DateTime.tryParse(fullDate);
        }
      }
      // 尝试直接解析
      else {
        dateTime = DateTime.tryParse(pubDate);
      }
      
      if (dateTime != null) {
        final now = DateTime.now();
        final difference = now.difference(dateTime);
        
        // 如果是今天
        if (difference.inDays == 0) {
          if (difference.inHours == 0) {
            return '${difference.inMinutes}分钟前';
          } else {
            return '${difference.inHours}小时前';
          }
        }
        // 如果是昨天
        else if (difference.inDays == 1) {
          return '昨天';
        }
        // 如果是一周内
        else if (difference.inDays < 7) {
          return '${difference.inDays}天前';
        }
        // 其他情况显示具体日期
        else {
          // 如果超过一年，显示完整年月日
          if (now.year != dateTime.year) {
            return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
          }
          // 如果是一年内，显示月-日
          else {
            return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
          }
        }
      }
    } catch (e) {
      // 如果解析失败，返回原始字符串
    }
    
    // 如果无法解析，返回原始字符串（截取前20个字符）
    return pubDate.length > 20 ? '${pubDate.substring(0, 20)}...' : pubDate;
  }

  // 主内容区
  Widget _buildBody(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final filteredArticles = appState.articles.where((article) {
          // 首先检查分类筛选
          bool categoryMatch = false;
          if (_currentFilter == 'all') {
            categoryMatch = true;
          } else if (_currentFilter == 'feedId' && _currentFilterId != null) {
            categoryMatch = article.feedId == _currentFilterId;
          }
          
          // 然后检查时间筛选
          bool timeMatch = _isArticleInTimeRange(article);
          
          // 两个条件都满足才显示
          return categoryMatch && timeMatch;
        }).toList();

        if (filteredArticles.isEmpty) {
          String emptyMessage = "没有文章";
          if (_timeFilter != 'all') {
            String timeText = '';
            switch (_timeFilter) {
              case 'today':
                timeText = '今天';
                break;
              case 'yesterday':
                timeText = '昨天';
                break;
              case 'week':
                timeText = '本周';
                break;
              case 'month':
                timeText = '本月';
                break;
            }
            emptyMessage = "没有${timeText}的文章";
          }
          return Center(child: Text("$emptyMessage，请添加 RSS Feed 并同步"));
        }
        return ListView.builder(
          itemCount: filteredArticles.length,
          itemBuilder: (context, index) {
            final article = filteredArticles[index];
            return Dismissible(
              key: ValueKey('article_${article.id ?? index}'),
              direction: DismissDirection.startToEnd,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: Colors.white),
                    SizedBox(width: 8),
                    Text('删除文章', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('确认删除'),
                        content: const Text('确定要删除这篇文章吗？'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('取消')),
                          TextButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('删除')),
                        ],
                      ),
                    ) ?? false;
              },
              onDismissed: (_) async {
                if (article.id != null) {
                  await Provider.of<AppStateProvider>(context, listen: false).deleteArticleById(article.id!);
                }
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    final url = article.url;
                    if (url.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WebViewPage(url: url, title: article.title, article: article),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleReaderPage(article: article),
                        ),
                      );
                    }
                    Provider.of<AppStateProvider>(context, listen: false).markArticleAsRead(article);
                  },
                  child: Container(
                    // 自适应高度，设置一个最小高度即可，避免溢出
                    constraints: const BoxConstraints(minHeight: 110),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            "https://placehold.co/80x80/random/fff?text=IMG",
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, size: 60),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 在文章标题上方添加订阅源名称
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 添加订阅源名称
                              Consumer<AppStateProvider>(
                                builder: (context, appState, _) {
                                  final feed = appState.feeds.firstWhere(
                                    (feed) => feed.id == article.feedId,
                                    orElse: () => RssFeed(id: null, title: '未知来源', url: '', folderId: null),
                                  );
                                  return Text(
                                    feed.title,
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              // 添加发布时间
                              Text(
                                _formatDate(article.pubDate),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                article.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              // 已读百分比（通过 webview 的进度暂时无法同步在列表，这里给占位或从文章字段扩展）
                              Text(
                                article.isRead ? '已读' : '未读',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Consumer<AppStateProvider>(
                                    builder: (context, appState, _) {
                                      // 取最新状态（如收藏/稍后再看切换）
                                      final aid = article.id;
                                      final current = aid == null
                                          ? article
                                          : (appState.articles.firstWhere(
                                              (a) => a.id == aid,
                                              orElse: () => article,
                                            ));
                                      return Row(
                                        children: [
                                          IconButton(
                                            iconSize: 20,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: Icon(current.isFavorite ? Icons.star : Icons.star_border),
                                            tooltip: current.isFavorite ? '取消收藏' : '收藏',
                                            onPressed: aid != null
                                                ? () async {
                                                    await Provider.of<AppStateProvider>(context, listen: false)
                                                        .toggleFavoriteStatus(current);
                                                  }
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            iconSize: 20,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: Icon(current.isReadLater
                                                ? Icons.watch_later
                                                : Icons.watch_later_outlined),
                                            tooltip: current.isReadLater ? '取消稍后再看' : '稍后再看',
                                            onPressed: aid != null
                                                ? () async {
                                                    await Provider.of<AppStateProvider>(context, listen: false)
                                                        .toggleReadLaterStatus(current);
                                                  }
                                                : null,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
