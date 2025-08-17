// lib/pages/notes_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/models/note.dart';
import 'package:rss_reader/providers/app_state_provider.dart';
import 'package:rss_reader/widgets/gradient_app_bar.dart';
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '我的笔记',
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          final List<Note> allNotes = appState.notes;
          if (allNotes.isEmpty) {
            return _buildEmptyState();
          }

          // 按文章分组笔记
          final Map<int, List<Note>> articleIdToNotes = {};
          for (final note in allNotes) {
            articleIdToNotes.putIfAbsent(note.articleId, () => []);
            articleIdToNotes[note.articleId]!.add(note);
          }

          // 构造分组列表（保持稳定顺序）
          final List<int> articleIds = articleIdToNotes.keys.toList();
          articleIds.sort((a, b) => b.compareTo(a));

          return ListView.separated(
            itemCount: articleIds.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final int articleId = articleIds[index];
              final Article matched = appState.articles.firstWhere(
                (a) => a.id == articleId,
                orElse: () => Article(
                  id: articleId,
                  title: '未知文章（ID: $articleId）',
                  content: '',
                  url: '',
                  pubDate: '',
                  feedId: -1,
                ),
              );
              final List<Note> notes = articleIdToNotes[articleId]!..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

              return ExpansionTile(
                key: PageStorageKey('article_notes_$articleId'),
                leading: const Icon(Icons.article_outlined),
                title: Text(
                  matched.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('共 ${notes.length} 条笔记'),
                children: notes.map((n) {
                  return Dismissible(
                    key: ValueKey('note_${n.id ?? n.content.hashCode}'),
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
                      leading: const Icon(Icons.notes_outlined),
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
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.note_alt, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无笔记', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}