// lib/pages/looklater_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/models/rss_feed.dart';
import 'package:rss_reader/pages/webview_page.dart';
import 'package:rss_reader/providers/app_state_provider.dart';
import 'package:rss_reader/widgets/article_card.dart';
import 'package:rss_reader/widgets/empty_state.dart';
import 'package:rss_reader/widgets/gradient_app_bar.dart';

class LookLaterPage extends StatelessWidget {
  const LookLaterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '稍后再看',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              Provider.of<AppStateProvider>(context, listen: false).initialize();
            },
            tooltip: '刷新',
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          final List<Article> readLater = appState.articles.where((a) => a.isReadLater).toList();
          if (readLater.isEmpty) {
            return EmptyState(
              title: '暂无稍后再看',
              subtitle: '将感兴趣的文章添加到稍后再看，方便以后阅读',
              icon: Icons.bookmark_border,
              actionText: '浏览文章',
              onAction: () {
                Navigator.pop(context);
              },
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: readLater.length,
            itemBuilder: (context, index) {
              final article = readLater[index];
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
                          builder: (_) => WebViewPage(url: article.url, title: article.title, article: article),
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
      ),
    );
  }
}


