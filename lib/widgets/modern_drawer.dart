import 'package:flutter/material.dart';
import 'package:rss_reader/models/rss_feed.dart';
import 'package:rss_reader/models/folder.dart';
import 'package:rss_reader/widgets/modern_card.dart';

class ModernDrawer extends StatelessWidget {
  final List<RssFeed> feeds;
  final List<Folder> folders;
  final String currentFilter;
  final int? currentFilterId;
  final Function(String, int?) onFilterChanged;
  final VoidCallback onNotes;
  final VoidCallback onVideos;
  final VoidCallback onLookLater;
  final VoidCallback onSettings;
  final VoidCallback onSubscriptionSources;
  final VoidCallback onUsing;
  final Function(Folder)? onDeleteFolder; // Added
  final Function(RssFeed)? onDeleteFeed; // Added for feed deletion

  const ModernDrawer({
    super.key,
    required this.feeds,
    required this.folders,
    required this.currentFilter,
    this.currentFilterId,
    required this.onFilterChanged,
    required this.onNotes,
    required this.onVideos,
    required this.onLookLater,
    required this.onSettings,
    required this.onSubscriptionSources,
    required this.onUsing,
    this.onDeleteFolder, // Added
    this.onDeleteFeed, // Added
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF0F0F23),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFFAFAFA),
                  ],
          ),
        ),
        child: Column(
          children: [
            // 头部
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                      ? [const Color(0xFF8B5CF6), const Color(0xFF6366F1)]
                      : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.rss_feed,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RSS Super',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 内容区域
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // 所有文章
                  _buildDrawerItem(
                    context,
                    icon: Icons.article,
                    title: '所有文章',
                    isSelected: currentFilter == 'all',
                    onTap: () => onFilterChanged('all', null),
                  ),
                  
                  const Divider(height: 1),
                  
                  // 文件夹
                  if (folders.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        '文件夹',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.textTheme.titleSmall?.color?.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...folders.map((folder) => _buildFolderItem(context, folder)),
                    const Divider(height: 1),
                  ],
                  
                  // 功能菜单
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '功能',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.textTheme.titleSmall?.color?.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  _buildDrawerItem(
                    context,
                    icon: Icons.bookmark,
                    title: '笔记',
                    onTap: onNotes,
                  ),
                  
                  _buildDrawerItem(
                    context,
                    icon: Icons.star,
                    title: '收藏',
                    onTap: onVideos,
                  ),
                  
                  _buildDrawerItem(
                    context,
                    icon: Icons.watch_later,
                    title: '稍后再看',
                    onTap: onLookLater,
                  ),
                  
                  const Divider(height: 1),
                  
                  // 管理菜单
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '管理',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.textTheme.titleSmall?.color?.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  _buildDrawerItem(
                    context,
                    icon: Icons.rss_feed,
                    title: '订阅源',
                    onTap: onSubscriptionSources,
                  ),
                  
                  _buildDrawerItem(
                    context,
                    icon: Icons.help_outline,
                    title: '使用说明',
                    onTap: onUsing,
                  ),
                  
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings,
                    title: '设置',
                    onTap: onSettings,
                  ),
                  

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? theme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected 
                  ? Border.all(
                      color: theme.primaryColor.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected 
                      ? theme.primaryColor
                      : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected 
                          ? theme.primaryColor
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.primaryColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFolderItem(BuildContext context, Folder folder) {
    final feedsInFolder = feeds.where((feed) => feed.folderId == folder.id).toList();
    
    return Dismissible(
      key: Key('folder_${folder.id}'),
      direction: DismissDirection.endToStart,
      movementDuration: const Duration(milliseconds: 200),
      resizeDuration: const Duration(milliseconds: 200),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('确认删除'),
              content: Text('确定要删除文件夹 "${folder.name}" 吗？\n\n删除后，该文件夹下的所有订阅源和文章也将被删除。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('删除'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        if (onDeleteFolder != null) {
          onDeleteFolder!(folder);
        }
      },
      child: ExpansionTile(
        leading: Icon(
          Icons.folder,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
        title: Text(
          folder.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${feedsInFolder.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.swipe_left,
              size: 16,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4),
            ),
          ],
        ),
        children: feedsInFolder.map((feed) {
          final isSelected = currentFilter == 'feedId' && currentFilterId == feed.id;
          
          return Dismissible(
            key: Key('feed_${feed.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(left: 16, right: 8, bottom: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 20,
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('确认删除'),
                    content: Text('确定要删除订阅源 "${feed.title}" 吗？\n\n删除后，该订阅源的所有文章也将被删除。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('删除'),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) {
              if (onDeleteFeed != null) {
                onDeleteFeed!(feed);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 8, bottom: 2),
              child: _buildDrawerItem(
                context,
                icon: Icons.rss_feed,
                title: feed.title,
                isSelected: isSelected,
                onTap: () => onFilterChanged('feedId', feed.id),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
