// lib/pages/videos_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/models/rss_feed.dart';
import 'package:rss_reader/pages/webview_page.dart';
import 'package:rss_reader/providers/app_state_provider.dart';
import 'package:rss_reader/widgets/article_card.dart';
import 'package:rss_reader/widgets/empty_state.dart';
import 'package:rss_reader/widgets/gradient_app_bar.dart';

class VideosPage extends StatelessWidget {
  const VideosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '我的收藏',
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
          final List<Article> favorites = appState.articles.where((a) => a.isFavorite).toList();
          if (favorites.isEmpty) {
            return EmptyState(
              title: '暂无收藏',
              subtitle: '将喜欢的文章添加到收藏，方便以后查看',
              icon: Icons.favorite_border,
              actionText: '浏览文章',
              onAction: () {
                Navigator.pop(context);
              },
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final article = favorites[index];
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
