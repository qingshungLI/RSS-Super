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
import 'package:rss_reader/widgets/gradient_app_bar.dart';
import 'package:rss_reader/widgets/modern_card.dart';
import 'package:rss_reader/widgets/modern_button.dart';
import 'package:rss_reader/widgets/article_card.dart';
import 'package:rss_reader/widgets/empty_state.dart';
import 'package:rss_reader/widgets/modern_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
      appBar: GradientAppBar(
        title: _getAppBarTitle(),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          // 时间筛选按钮
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
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
                    Icon(Icons.all_inclusive, size: 20, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text('全部时间'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'today',
                child: Row(
                  children: [
                    Icon(Icons.today, size: 20, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text('今天'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'yesterday',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text('昨天'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'week',
                child: Row(
                  children: [
                    Icon(Icons.view_week, size: 20, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text('本周'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'month',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 20, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text('本月'),
                  ],
                ),
              ),
            ],
          ),
          // 搜索按钮
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
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
                icon: const Icon(Icons.sync, color: Colors.white),
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
      drawer: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
                     return ModernDrawer(
             feeds: appState.feeds,
             folders: appState.folders,
             currentFilter: _currentFilter,
             currentFilterId: _currentFilterId,
             onFilterChanged: (filter, filterId) {
               setState(() {
                 _currentFilter = filter;
                 _currentFilterId = filterId;
               });
               Navigator.pop(context);
             },
             onNotes: () {
               Navigator.pop(context);
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => NotesPage()),
               );
             },
             onVideos: () {
               Navigator.pop(context);
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => VideosPage()),
               );
             },
             onLookLater: () {
               Navigator.pop(context);
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const LookLaterPage()),
               );
             },
             onSettings: () {
               Navigator.pop(context);
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => SettingsPage()),
               );
             },
             onSubscriptionSources: () {
               Navigator.pop(context);
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => SubscriptionSourcesPage()),
               );
             },
             onUsing: () {
               Navigator.pop(context);
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => UsingPage()),
               );
             },
             onDeleteFolder: (folder) async {
               await appState.deleteFolder(folder.id!);
             },
             onDeleteFeed: (feed) async {
               await appState.deleteFeed(feed.id!);
             },
           );
        },
      ),
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
          String emptyTitle = "没有文章";
          String emptySubtitle = "请添加 RSS Feed 并同步";
          
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
            emptyTitle = "没有$timeText的文章";
            emptySubtitle = "尝试调整时间筛选或添加更多订阅源";
          }
          
          return EmptyState(
            title: emptyTitle,
            subtitle: emptySubtitle,
            icon: Icons.article_outlined,
            actionText: '添加订阅源',
            onAction: () {
              showDialog(
                context: context,
                builder: (context) => AddFeedDialog(),
              );
            },
          );
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
              child: ArticleCard(
                article: article,
                isRead: article.isRead,
                feedTitle: appState.feeds.firstWhere(
                  (feed) => feed.id == article.feedId,
                  orElse: () => RssFeed(id: null, title: '未知来源', url: '', folderId: null),
                ).title,
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
                onToggleFavorite: (article) {
                  Provider.of<AppStateProvider>(context, listen: false).toggleFavoriteStatus(article);
                },
                onToggleReadLater: (article) {
                  Provider.of<AppStateProvider>(context, listen: false).toggleReadLaterStatus(article);
                },
              ),
            );
          },
        );
      },
    );
  }
}
