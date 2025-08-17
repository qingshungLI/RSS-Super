// lib/pages/using_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rss_reader/widgets/gradient_app_bar.dart';
class UsingPage extends StatefulWidget {
  const UsingPage({super.key});

  @override
  _UsingPageState createState() => _UsingPageState();
}

class _UsingPageState extends State<UsingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: "使用说明",
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              " RSS Super 简介",
              "RSS Super 是一款功能强大的 RSS 阅读器，帮助您高效地获取和管理各种信息源。",
              Icons.rss_feed,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              " 添加订阅源",
              "1. 点击右下角的 + 按钮\n2. 选择 '添加订阅源'\n3. 输入 RSS 源的 URL\n4. 选择所属文件夹（可选）\n5. 点击确认添加",
              Icons.add_circle_outline,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              " 文件夹管理",
              "• 创建文件夹来组织订阅源\n• 点击右下角的 + 按钮选择 '新建文件夹'\n• 在侧栏中展开文件夹查看订阅源\n• 左滑删除文件夹或订阅源\n•当订阅源或文件夹中有未读文章时显示红点",
              Icons.folder,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              "时间筛选",
              "• 点击右上角的筛选图标\n• 选择时间范围：今天、昨天、本周、本月\n• 快速查看特定时间段的文章",
              Icons.filter_list,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              "搜索功能",
              "• 点击右上角的搜索图标\n• 在文章标题和内容中搜索关键词\n• 快速找到感兴趣的文章",
              Icons.search,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              "收藏功能",
              "• 点击文章下方的星形图标收藏文章\n• 在侧栏的 '收藏' 中查看所有收藏文章\n• 再次点击取消收藏",
              Icons.star,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              " 稍后再看",
              "• 点击文章下方的时钟图标标记为稍后再看\n• 在侧栏的 '稍后再看' 中查看\n• 方便稍后阅读重要文章",
              Icons.watch_later,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              " 笔记功能",
              "• 在文章阅读页面点击右下角的笔记按钮\n• 为文章添加个人笔记和想法\n• 在侧栏的 '笔记' 中查看所有笔记",
              Icons.note,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              " 同步功能",
              "• 点击右上角的同步图标\n• 自动获取所有订阅源的最新文章\n• 保持信息源的及时更新",
              Icons.sync,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              "删除操作",
              "• 右滑文章、订阅源或文件夹\n• 点击删除按钮确认删除\n• 删除操作不可恢复，请谨慎操作",
              Icons.delete,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              " 设置",
              "• 在侧栏中点击 '设置'\n• 配置应用的各种参数\n• 个性化您的阅读体验",
              Icons.settings,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              " 使用技巧",
              "• 定期同步获取最新内容\n• 使用文件夹整理订阅源\n• 利用时间筛选快速浏览\n• 收藏重要文章便于回顾\n• 添加笔记记录阅读心得",
              Icons.lightbulb,
            ),
            const SizedBox(height: 24),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        "温馨提示",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                   const SizedBox(height: 8),
                   _buildLinkText(
                     "RSS Super 支持多种 RSS 格式，有官方源也支持rsshub。关于rsshub，请参见",
                     "https://docs.rsshub.app/guide/",
                     "，rsshub常见不稳定报错，请修改服务器，参见",
                     "https://www.1itao.com/rsshub.html",
                   ),
                   Container(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建包含链接的文本
  Widget _buildLinkText(String beforeText, String url1, String middleText, String url2) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: Colors.blue.shade600,
        ),
        children: [
          TextSpan(text: beforeText),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => _launchUrl(url1),
              child: Text(
                'RSSHub 官方文档',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          TextSpan(text: middleText),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => _launchUrl(url2),
              child: Text(
                'RSSHub 服务器',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 启动URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // 如果无法启动URL，显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('无法打开链接: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
