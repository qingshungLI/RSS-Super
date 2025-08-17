import 'package:flutter/material.dart';
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/widgets/modern_card.dart';

class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final Function(Article)? onToggleFavorite;
  final Function(Article)? onToggleReadLater;
  final bool isRead;
  final bool showImage;
  final String? feedTitle;

  const ArticleCard({
    super.key,
    required this.article,
    this.onTap,
    this.onDismiss,
    this.onToggleFavorite,
    this.onToggleReadLater,
    this.isRead = false,
    this.showImage = true,
    this.feedTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和来源信息
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      article.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                        color: isRead 
                            ? theme.textTheme.bodyMedium?.color?.withOpacity(0.7)
                            : theme.textTheme.titleMedium?.color,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // 来源和时间
                    Row(
                      children: [
                        // 来源图标
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.rss_feed,
                            size: 12,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        
                        // 来源名称
                        Expanded(
                          child: Text(
                            feedTitle ?? 'RSS Feed ${article.feedId}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // 发布时间
                        Text(
                          _formatDate(article.pubDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 文章图片占位符
              if (showImage) ...[
                const SizedBox(width: 12),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.article,
                    color: theme.dividerColor.withOpacity(0.5),
                    size: 32,
                  ),
                ),
              ],
            ],
          ),
          
          // 文章摘要
          if (article.content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _cleanDescription(article.content),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // 底部操作栏
          const SizedBox(height: 12),
          Row(
            children: [
              // 阅读状态指示器
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isRead 
                      ? Colors.transparent
                      : theme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 文章标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'RSS',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              const Spacer(),
              
              // 操作按钮
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 稍后阅读按钮
                  IconButton(
                    icon: Icon(
                      article.isReadLater ? Icons.watch_later : Icons.watch_later_outlined,
                      size: 18,
                      color: article.isReadLater 
                          ? theme.primaryColor
                          : theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                    onPressed: () {
                      if (onToggleReadLater != null) {
                        onToggleReadLater!(article);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: article.isReadLater ? '取消稍后阅读' : '稍后阅读',
                  ),
                  
                  // 收藏按钮（原分享按钮）
                  IconButton(
                    icon: Icon(
                      article.isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: article.isFavorite 
                          ? Colors.red
                          : theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                    onPressed: () {
                      if (onToggleFavorite != null) {
                        onToggleFavorite!(article);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: article.isFavorite ? '取消收藏' : '收藏',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String pubDate) {
    try {
      DateTime? date = _parseDate(pubDate);
      if (date == null) return '';
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}分钟前';
        }
        return '${difference.inHours}小时前';
      } else if (difference.inDays == 1) {
        return '昨天';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}天前';
      } else {
        return '${date.month}-${date.day}';
      }
    } catch (e) {
      return '';
    }
  }

  DateTime? _parseDate(String pubDate) {
    try {
      if (pubDate.contains('T') && pubDate.contains('Z')) {
        return DateTime.parse(pubDate);
      }
      
      // 尝试其他常见格式
      final formats = [
        'EEE, dd MMM yyyy HH:mm:ss Z',
        'yyyy-MM-dd HH:mm:ss',
        'dd/MM/yyyy HH:mm:ss',
      ];
      
      for (final format in formats) {
        try {
          return DateFormat(format).parse(pubDate);
        } catch (e) {
          continue;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  String _cleanDescription(String description) {
    // 移除HTML标签
    String cleaned = description.replaceAll(RegExp(r'<[^>]*>'), '');
    // 移除多余的空白字符
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }
}

// 简单的日期格式化类
class DateFormat {
  final String pattern;
  
  DateFormat(this.pattern);
  
  DateTime parse(String input) {
    // 这里实现简单的日期解析
    // 实际项目中建议使用 intl 包
    return DateTime.parse(input);
  }
}
