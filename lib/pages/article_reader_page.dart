// lib/pages/article_reader_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/models/note.dart';
import 'package:rss_reader/providers/app_state_provider.dart';
import 'package:webview_flutter/webview_flutter.dart'; // <--- 导入 WebView
import 'package:rss_reader/pages/webview_page.dart';

String convertBilibiliDeepLinkToHttp(String url) {
  if (url.startsWith('bilibili://')) {
    try {
      final uri = Uri.parse(url);
      final openAppUrlEncoded = uri.queryParameters['open_app_url'];
      if (openAppUrlEncoded != null && openAppUrlEncoded.isNotEmpty) {
        final openAppUrl = Uri.decodeComponent(openAppUrlEncoded);
        return openAppUrl;
      }
    } catch (e) {
      // 解析失败，返回原链接
      print('解析 bilibili 深链失败: $e');
      return url;
    }
  }
  // 不是 bilibili://，直接返回原链接
  return url;
}


class ArticleReaderPage extends StatefulWidget {
  final Article article;

  const ArticleReaderPage({super.key, required this.article});

  @override
  _ArticleReaderPageState createState() => _ArticleReaderPageState();
}

class _ArticleReaderPageState extends State<ArticleReaderPage> {
  // 滚动控制器，用于计算阅读进度
  final ScrollController _scrollController = ScrollController();
  // 当前阅读百分比
  double _readPercentage = 0.0;
  // 用于笔记对话框的控制器
  final _noteController = TextEditingController();
  @override
  void dispose() {
    _scrollController.removeListener(_updateReadPercentage);
    _scrollController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateReadPercentage() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      if (maxScroll > 0) {
        setState(() {
          _readPercentage = (currentScroll / maxScroll);
        });
      }
    }
  }//待在homepage中体现
  // --- 为 WebView 创建一个 Controller ---
  late final WebViewController _webViewController;
  String? _errorMessage;

  // 用于追踪 WebView 的加载进度
  int _loadingPercentage = 0;

  @override
  void initState() {
    super.initState();
    // 监听滚动，计算阅读进度
    _scrollController.addListener(_updateReadPercentage);


    // --- 初始化 WebView Controller ---
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // 开启 JS 支持
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingPercentage = progress;
            });
          },
          onPageStarted: (String url) {
             setState(() {
              _loadingPercentage = 0;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _loadingPercentage = 100;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = "❌ 加载失败：${error.description}";
            });
          },
          // 你可以在这里限制导航，防止用户跳出当前文章页面
          onNavigationRequest: (NavigationRequest request) {
            // if (!request.url.startsWith(widget.article.link)) {
            //   return NavigationDecision.prevent;
            // }
            return NavigationDecision.navigate;
          },
        ),
      )
      // --- 加载文章的原始链接 ---
      
      ..loadRequest(Uri.parse(widget.article.url));
  }
  


  // --- 笔记UI模块，这是一个独立的、可复用的 Widget ---
  Widget _buildNotesPanel(BuildContext context, AppStateProvider appState) {
    // 这里你可以获取与当前文章相关的笔记列表
    // final notes = appState.getNotesForArticle(widget.article.id!);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.2)),
        ],
      ),
      child: Column(
        children: [
          // 面板的拖拽指示器
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // 笔记输入区
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "记录你的想法...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_noteController.text.isNotEmpty) {
                  final newNote = Note(
                  content: _noteController.text,
                  articleId: widget.article.id!,
                );
                 // TODO: appState.addNote(newNote); // 调用 Provider 保存笔记
                _noteController.clear();
                FocusScope.of(context).unfocus(); // 收起键盘
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('笔记已保存!'))
                );
              }
            },
            child: Text("保存笔记"),
          ),
          Divider(height: 32),
          Text("历史笔记", style: Theme.of(context).textTheme.titleMedium),
          // 笔记列表
          Expanded(
            child: ListView.builder( // 假设这里展示历史笔记
              itemCount: 0, // TODO: 替换为真实笔记数量
              itemBuilder: (context, index) {
                return ListTile(
                  // title: Text(notes[index].content),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final updatedArticle = appState.articles.firstWhere(
            (a) => a.id == widget.article.id,
            orElse: () => widget.article);

        return Scaffold(
          appBar: AppBar(
            title: Text(updatedArticle.title),
            actions: [
              IconButton(
                tooltip: '查看原文',
                icon: const Icon(Icons.open_in_new),
                onPressed: () {
                  final url = updatedArticle.url;
                  if (url.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WebViewPage(url: url, title: updatedArticle.title),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // --- 1. WebView 作为背景 ---
              WebViewWidget(controller: _webViewController),
              
              // --- WebView 加载进度条 ---
              if (_loadingPercentage < 100)
                LinearProgressIndicator(value: _loadingPercentage / 100),
              
              // --- 2. 笔记面板，浮动在上方 ---
              DraggableScrollableSheet(
                initialChildSize: 0.1,  // 初始状态下，面板只占屏幕的10%
                minChildSize: 0.1,      // 最小占10%
                maxChildSize: 0.8,      // 最大可以拖到80%
                builder: (context, scrollController) {
                  // 把笔记面板放到一个可滚动视图中，这样它自己也能滚动
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: _buildNotesPanel(context, appState),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}