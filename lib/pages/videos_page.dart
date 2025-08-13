// lib/pages/videos_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/pages/webview_page.dart';
import 'package:rss_reader/providers/app_state_provider.dart';

class VideosPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("我的收藏"),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          final List<Article> favorites = appState.articles.where((a) => a.isFavorite).toList();
          if (favorites.isEmpty) {
            return const Center(child: Text('暂无收藏'));
          }
          return ListView.separated(
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final article = favorites[index];
              return Dismissible(
                key: ValueKey('fav_${article.id ?? index}'),
                direction: DismissDirection.startToEnd,
                background: Container(
                  color: Colors.orange,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      Icon(Icons.star_border, color: Colors.white),
                      SizedBox(width: 8),
                      Text('取消收藏', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('确认操作'),
                          content: const Text('确定要取消收藏吗？'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('取消')),
                            TextButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('确定')),
                          ],
                        ),
                      ) ?? false;
                },
                onDismissed: (_) async {
                  await Provider.of<AppStateProvider>(context, listen: false).toggleFavoriteStatus(article);
                },
                child: ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (article.url.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WebViewPage(url: article.url, title: article.title, article: article),
                        ),
                      );
                    }
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
