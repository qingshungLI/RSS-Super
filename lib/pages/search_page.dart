// lib/pages/search_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/providers/app_state_provider.dart';
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/models/folder.dart';
import 'package:rss_reader/models/rss_feed.dart';
import 'package:rss_reader/pages/webview_page.dart';
import 'package:rss_reader/widgets/article_card.dart';
import 'package:rss_reader/widgets/empty_state.dart';
import 'package:rss_reader/widgets/gradient_app_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Article> _searchResults = [];
  bool _isSearching = false;
  
  // 搜索范围选择
  String _searchScope = 'all'; // 'all', 'folder', 'feed'
  int? _selectedFolderId;
  int? _selectedFeedId;
  
  // 下拉选项
  List<Folder> _folders = [];
  List<RssFeed> _feeds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    setState(() {
      _folders = appState.folders;
      _feeds = appState.feeds;
    });
  }

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    List<Article> results = [];

    // 根据搜索范围过滤文章
    List<Article> articlesToSearch = appState.articles;
    
    if (_searchScope == 'folder' && _selectedFolderId != null) {
      // 搜索指定文件夹下的文章
      final folderFeeds = _feeds.where((feed) => feed.folderId == _selectedFolderId).toList();
      final folderFeedIds = folderFeeds.map((feed) => feed.id).where((id) => id != null).cast<int>().toList();
      articlesToSearch = articlesToSearch.where((article) => folderFeedIds.contains(article.feedId)).toList();
    } else if (_searchScope == 'feed' && _selectedFeedId != null) {
      // 搜索指定订阅源的文章
      articlesToSearch = articlesToSearch.where((article) => article.feedId == _selectedFeedId).toList();
    }

    // 执行搜索
    results = articlesToSearch.where((article) {
      final searchQuery = query.toLowerCase();
      return article.title.toLowerCase().contains(searchQuery) ||
             article.content.toLowerCase().contains(searchQuery);
    }).toList();

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '搜索文章',
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _performSearch,
            tooltip: '搜索',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索控制面板
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 搜索输入框
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '输入关键词搜索文章...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),
                // 搜索范围选择
                Row(
                  children: [
                    const Text('搜索范围: ', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _searchScope,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('全部')),
                        DropdownMenuItem(value: 'folder', child: Text('文件夹')),
                        DropdownMenuItem(value: 'feed', child: Text('订阅源')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _searchScope = value!;
                          _selectedFolderId = null;
                          _selectedFeedId = null;
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    if (_searchScope == 'folder')
                      DropdownButton<int?>(
                        value: _selectedFolderId,
                        hint: const Text('选择文件夹'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('请选择')),
                          ..._folders.map((folder) => DropdownMenuItem<int?>(
                            value: folder.id,
                            child: Text(folder.name),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFolderId = value;
                          });
                        },
                      ),
                    if (_searchScope == 'feed')
                      DropdownButton<int?>(
                        value: _selectedFeedId,
                        hint: const Text('选择订阅源'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('请选择')),
                          ..._feeds.map((feed) => DropdownMenuItem<int?>(
                            value: feed.id,
                            child: Text(feed.title),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFeedId = value;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          // 搜索结果
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      if (_searchController.text.isEmpty) {
        return EmptyState(
          title: '开始搜索',
          subtitle: '输入关键词搜索感兴趣的文章',
          icon: Icons.search,
          actionText: '浏览文章',
          onAction: () {
            Navigator.pop(context);
          },
        );
      } else {
        return EmptyState(
          title: '未找到相关文章',
          subtitle: '尝试使用不同的关键词或调整搜索范围',
          icon: Icons.search_off,
          actionText: '重新搜索',
          onAction: () {
            _searchController.clear();
            setState(() {
              _searchResults = [];
            });
          },
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final article = _searchResults[index];
        return Consumer<AppStateProvider>(
          builder: (context, appState, _) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ArticleCard(
                article: article,
                isRead: article.isRead,
                feedTitle: appState.feeds.firstWhere(
                  (feed) => feed.id == article.feedId,
                  orElse: () => RssFeed(id: null, title: '未知来源', url: '', folderId: null),
                ).title,
                onTap: () {
                  if (article.url.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WebViewPage(
                          url: article.url,
                          title: article.title,
                          article: article,
                        ),
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
