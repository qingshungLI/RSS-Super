// lib/pages/search_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/providers/app_state_provider.dart';
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/models/folder.dart';
import 'package:rss_reader/models/rss_feed.dart';
import 'package:rss_reader/pages/webview_page.dart';

class SearchPage extends StatefulWidget {
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
      appBar: AppBar(
        title: const Text("搜索文章"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            padding: const EdgeInsets.all(16),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 8),
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
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      if (_searchController.text.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('输入关键词开始搜索', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        );
      } else {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('未找到相关文章', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        );
      }
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final article = _searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.article_outlined),
            title: Text(
              article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      article.isRead ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16,
                      color: article.isRead ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      article.isRead ? '已读' : '未读',
                      style: TextStyle(
                        fontSize: 12,
                        color: article.isRead ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (article.isFavorite)
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                    if (article.isReadLater)
                      const Icon(Icons.watch_later, size: 16, color: Colors.blue),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
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
            },
          ),
        );
      },
    );
  }
}
