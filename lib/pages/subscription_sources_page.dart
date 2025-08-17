// lib/pages/subscription_sources_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:rss_reader/widgets/gradient_app_bar.dart';
import 'package:rss_reader/dialogs/import_opml_dialog.dart';
class SubscriptionSourcesPage extends StatefulWidget {
  const SubscriptionSourcesPage({super.key});

  @override
  _SubscriptionSourcesPageState createState() => _SubscriptionSourcesPageState();
}

class _SubscriptionSourcesPageState extends State<SubscriptionSourcesPage> {
  List<Map<String, String>> _subscriptionSources = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isEditing = false;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionSources();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 加载订阅源数据
  Future<void> _loadSubscriptionSources() async {
    final prefs = await SharedPreferences.getInstance();
    final sourcesJson = prefs.getString('subscription_sources');
    
    if (sourcesJson != null) {
      final List<dynamic> sourcesList = json.decode(sourcesJson);
      setState(() {
        _subscriptionSources = sourcesList.map((item) => Map<String, String>.from(item)).toList();
      });
    } else {
      // 如果没有保存的数据，加载默认的订阅源
      _loadDefaultSources();
    }
  }

  // 加载默认订阅源
  void _loadDefaultSources() {
    setState(() {
      _subscriptionSources = [
        {
          'name': '知乎用户',
          'url': 'https://rsshub.jardongong.com/zhihu/people/activities/:id',
          'description': '作者 id,可在用户主页 URL 中找到'
        },
        {
          'name': '36氪',
          'url': 'https://www.36kr.com/feed',
          'description': '科技创业资讯'
        },
        {
          'name': '少数派',
          'url': 'https://sspai.com/feed',
          'description': '数字生活指南'
        },
        {
          'name': '爱范儿',
          'url': 'https://www.ifanr.com/feed',
          'description': '科技资讯和评测'
        },
        {
          'name': '虎嗅网',
          'url': 'https://www.huxiu.com/rss/0.xml',
          'description': '商业科技资讯'
        },
        {
          'name': '钛媒体',
          'url': 'https://www.tmtpost.com/rss.xml',
          'description': '科技商业媒体'
        },
        {
          'name': 'CSDN',
          'url': 'https://rsshub.jardongong.com/csdn/blog/:user',
          'description': '最后的user是用户名,从主页获得'
        },
        {
          'name': 'Youtube',
          'url': 'https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID',

          'description': 'CHANNEL_ID是频道ID'
        },
      ];
    });
    _saveSubscriptionSources();
  }

  // 保存订阅源数据
  Future<void> _saveSubscriptionSources() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_sources', json.encode(_subscriptionSources));
  }

  // 显示添加/编辑对话框
  void _showAddEditDialog({int? index}) {
    _isEditing = index != null;
    _editingIndex = index;
    
    if (_isEditing) {
      final source = _subscriptionSources[index!];
      _nameController.text = source['name'] ?? '';
      _urlController.text = source['url'] ?? '';
      _descriptionController.text = source['description'] ?? '';
    } else {
      _nameController.clear();
      _urlController.clear();
      _descriptionController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? '编辑订阅源' : '添加订阅源'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '名称',
                  hintText: '请输入订阅源名称',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'RSS地址',
                  hintText: '请输入RSS源的URL',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '描述',
                  hintText: '请输入订阅源描述（可选）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty && _urlController.text.isNotEmpty) {
                _saveSource();
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('请填写名称和RSS地址'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(_isEditing ? '保存' : '添加'),
          ),
        ],
      ),
    );
  }

  // 保存订阅源
  void _saveSource() {
    final newSource = {
      'name': _nameController.text.trim(),
      'url': _urlController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    setState(() {
      if (_isEditing) {
        _subscriptionSources[_editingIndex!] = newSource;
      } else {
        _subscriptionSources.add(newSource);
      }
    });

    _saveSubscriptionSources();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? '订阅源已更新' : '订阅源已添加'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // 删除订阅源
  void _deleteSource(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除 "${_subscriptionSources[index]['name']}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _subscriptionSources.removeAt(index);
              });
              _saveSubscriptionSources();
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('订阅源已删除'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('删除'),
          ),
        ],
      ),
    );
  }

  // 复制RSS地址
  void _copyRssUrl(String url, String name) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制 $name 的RSS地址到剪贴板'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: "订阅源管理",
        actions: [
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ImportOpmlDialog(),
              );
            },
            tooltip: '导入 OPML',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
            tooltip: '添加订阅源',
          ),
        ],
      ),
      body: _subscriptionSources.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rss_feed_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '暂无订阅源',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '点击右上角的 + 按钮添加订阅源',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _subscriptionSources.length,
              itemBuilder: (context, index) {
                final source = _subscriptionSources[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      source['name']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (source['description']!.isNotEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            source['description']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  source['url']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: Colors.blue.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.copy, size: 16),
                                onPressed: () => _copyRssUrl(source['url']!, source['name']!),
                                tooltip: '复制RSS地址',
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showAddEditDialog(index: index);
                            break;
                          case 'delete':
                            _deleteSource(index);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('编辑'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('删除', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
