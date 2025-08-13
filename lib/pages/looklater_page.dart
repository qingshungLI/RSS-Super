// lib/pages/looklater_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/pages/webview_page.dart';
import 'package:rss_reader/providers/app_state_provider.dart';

class LookLaterPage extends StatelessWidget {
  const LookLaterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('稍后再看'),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          final List<Article> readLater = appState.articles.where((a) => a.isReadLater).toList();
          if (readLater.isEmpty) {
            return const Center(child: Text('暂无“稍后再看”条目'));
          }
          return ListView.separated(
            itemCount: readLater.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final article = readLater[index];
              return Dismissible(
                key: ValueKey('later_${article.id ?? index}'),
                direction: DismissDirection.startToEnd,
                background: Container(
                  color: Colors.blueGrey,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      Icon(Icons.watch_later_outlined, color: Colors.white),
                      SizedBox(width: 8),
                      Text('移出稍后再看', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('确认操作'),
                          content: const Text('确定要移出“稍后再看”吗？'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('取消')),
                            TextButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('确定')),
                          ],
                        ),
                      ) ?? false;
                },
                onDismissed: (_) async {
                  await Provider.of<AppStateProvider>(context, listen: false).toggleReadLaterStatus(article);
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


