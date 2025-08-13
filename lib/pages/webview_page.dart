// lib/pages/webview_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/models/note.dart';
import 'package:rss_reader/models/rss_feed.dart';
import 'package:rss_reader/providers/app_state_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String? title;
  final Article? article; // 可选：用于关联笔记

  const WebViewPage({Key? key, required this.url, this.title, this.article}) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() async {
    String urlToLoad = widget.url;
    
    // 检查是否是自定义协议
    if (_isCustomProtocol(widget.url)) {
      // 尝试在外部应用中打开
          urlToLoad = _convertToHttpUrl(widget.url);
        }
     

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (v) => setState(() => _progress = v),
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() => _isLoading = false),
          onNavigationRequest: (NavigationRequest request) async {
            // 处理页面内的自定义协议链接
            if (_isCustomProtocol(request.url)) {
              try {
                // 获取 RSS feed 的 URL 而不是 request.url
                String rssFeedUrl = '';
                if (widget.article != null) {
                  final appState = Provider.of<AppStateProvider>(context, listen: false);
                  final feed = appState.feeds.firstWhere(
                    (feed) => feed.id == widget.article!.feedId,
                    orElse: () => RssFeed(id: null, title: '未知来源', url: '', folderId: null),
                  );
                  rssFeedUrl = feed.url;
                }
                
                final uri = Uri.parse(_convertToHttpUrl(rssFeedUrl.isNotEmpty ? rssFeedUrl : request.url));
                final canLaunch = await canLaunchUrl(uri);
                if (canLaunch) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已在外部应用中打开')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('无法打开链接: ${request.url}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('打开链接失败: $e')),
                );
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    try {
      await _controller.loadRequest(Uri.parse(urlToLoad));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载页面失败: $e')),
        );
      }
    }
  }

  bool _isCustomProtocol(String url) {
    final customProtocols = [
      'bilibili://',
      'youku://',
      'iqiyi://',
      'qq://',
      'weixin://',
      'alipay://',
      'taobao://',
      'tmall://',
      'zhihu://',
      'douyin://',
      'kuaishou://',
    ];
    return customProtocols.any((protocol) => url.startsWith(protocol));
  }

String _convertToHttpUrl(String url) {
  if(url.contains('bilibili/')){
    if (url.contains('rsshub.jordangong.com/bilibili/user/')) {
      final parts = url.split('/');
      if (parts.length >= 2) {
        final id = parts.last; // 获取最后一个部分作为 ID
        if (id.isNotEmpty && int.tryParse(id) != null) {
          return 'https://space.bilibili.com/$id';
        }
      }
    }
    
    
    return 'https://www.bilibili.com';
  }
  
  if(url.contains('zhihu/')){
    if (url.contains('rsshub.jordangong.com/zhihu/')) {
      final parts = url.split('/');
      if (parts.length >= 2) {
        final id = parts.last; // 获取最后一个部分作为 ID
        if (id.isNotEmpty) {
          return 'https://www.zhihu.com/people/$id';
        }
      }
    }
    
    return 'https://www.zhihu.com';
  }
  
  return url;
}
  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法在浏览器中打开该链接')),
      );
    }
  }

  Future<void> _openNotesSheet() async {
    final articleId = widget.article?.id;
    if (articleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法添加笔记：文章未持久化')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ArticleNotesSheet(articleId: articleId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? '原文'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openInBrowser,
            tooltip: '浏览器打开',
          ),
          if (widget.article != null)
            Consumer<AppStateProvider>(
              builder: (context, appState, _) {
                final int? aid = widget.article!.id;
                Article? current;
                if (aid != null) {
                  current = appState.articles.firstWhere(
                    (a) => a.id == aid,
                    orElse: () => widget.article!,
                  );
                } else {
                  current = widget.article!;
                }

                final bool canToggle = current.id != null;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: current.isFavorite ? '取消收藏' : '收藏',
                      icon: Icon(
                        current.isFavorite ? Icons.star : Icons.star_border,
                      ),
                      onPressed: canToggle
                          ? () async {
                              await appState.toggleFavoriteStatus(current!);
                            }
                          : null,
                    ),
                    IconButton(
                      tooltip: current.isReadLater ? '取消稍后再看' : '稍后再看',
                      icon: Icon(
                        current.isReadLater ? Icons.watch_later : Icons.watch_later_outlined,
                      ),
                      onPressed: canToggle
                          ? () async {
                              await appState.toggleReadLaterStatus(current!);
                            }
                          : null,
                    ),
                  ],
                );
              },
            ),
        ],
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress / 100),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
      floatingActionButton: widget.article?.id != null
          ? FloatingActionButton.extended(
              onPressed: _openNotesSheet,
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('笔记'),
            )
          : null,
    );
  }
}

class ArticleNotesSheet extends StatefulWidget {
  final int articleId;
  const ArticleNotesSheet({Key? key, required this.articleId}) : super(key: key);

  @override
  State<ArticleNotesSheet> createState() => _ArticleNotesSheetState();
}

class _ArticleNotesSheetState extends State<ArticleNotesSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('笔记', style: Theme.of(context).textTheme.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '记录你的想法...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ElevatedButton(
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    final appState = Provider.of<AppStateProvider>(context, listen: false);
                    await appState.addNote(Note(content: text, articleId: widget.articleId));
                    if (!mounted) return;
                    _controller.clear();
                    FocusScope.of(context).unfocus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('笔记已保存')),
                    );
                  },
                  child: const Text('保存笔记'),
                ),
              ),
              const Divider(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text('历史笔记', style: Theme.of(context).textTheme.titleMedium),
              ),
                  Expanded(
                    child: Consumer<AppStateProvider>(
                      builder: (ctx, appState, _) {
                        final notes = appState.notes.where((n) => n.articleId == widget.articleId).toList();
                        if (notes.isEmpty) {
                          return const Center(child: Text('暂无笔记'));
                        }
                        return ListView.separated(
                          itemCount: notes.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final n = notes[index];
                            return Dismissible(
                              key: ValueKey('note_${n.id ?? index}'),
                              direction: DismissDirection.startToEnd,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('删除', style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                      context: context,
                                      builder: (dCtx) => AlertDialog(
                                        title: const Text('确认删除'),
                                        content: const Text('确定要删除该笔记吗？'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(dCtx).pop(false),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(dCtx).pop(true),
                                            child: const Text('删除'),
                                          ),
                                        ],
                                      ),
                                    ) ?? false;
                              },
                              onDismissed: (_) async {
                                if (n.id != null) {
                                  await Provider.of<AppStateProvider>(context, listen: false).deleteNote(n.id!);
                                }
                              },
                              child: ListTile(
                                dense: true,
                                title: Text(n.content),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: '编辑',
                                  onPressed: () async {
                                    final edited = await showDialog<String>(
                                      context: context,
                                      builder: (dCtx) {
                                        final controller = TextEditingController(text: n.content);
                                        return AlertDialog(
                                          title: const Text('编辑笔记'),
                                          content: TextField(
                                            controller: controller,
                                            maxLines: 4,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(dCtx).pop(),
                                              child: const Text('取消'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(dCtx).pop(controller.text.trim()),
                                              child: const Text('保存'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (edited != null && edited.isNotEmpty && n.id != null) {
                                      final updated = Note(
                                        id: n.id,
                                        content: edited,
                                        articleId: n.articleId,
                                        highlightText: n.highlightText,
                                      );
                                      await Provider.of<AppStateProvider>(context, listen: false).updateNote(updated);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}


