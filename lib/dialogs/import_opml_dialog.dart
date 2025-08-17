// lib/dialogs/import_opml_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/providers/app_state_provider.dart';
import 'package:rss_reader/models/rss_feed.dart';
import 'package:rss_reader/models/folder.dart';
import 'package:rss_reader/widgets/modern_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import 'dart:io';

class ImportOpmlDialog extends StatefulWidget {
  const ImportOpmlDialog({super.key});

  @override
  State<ImportOpmlDialog> createState() => _ImportOpmlDialogState();
}

class _ImportOpmlDialogState extends State<ImportOpmlDialog> {
  bool _isLoading = false;
  String _selectedFilePath = '';
  List<OpmlOutline> _outlines = [];
  Map<String, bool> _selectedOutlines = {};
  String? _errorMessage;
  int? _selectedFolderId; // 添加文件夹选择
  Map<String, String> _customTitles = {}; // 自定义标题
  bool _showCreateFolder = false; // 是否显示创建文件夹
  final TextEditingController _newFolderController = TextEditingController(); // 新文件夹名称

  @override
  void dispose() {
    _newFolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入 OPML'),
      content:SingleChildScrollView(
      child: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            
            // 文件选择
            if (_selectedFilePath.isEmpty) ...[
              const Text('选择 OPML 文件：'),
              const SizedBox(height: 12),
              ModernButton(
                text: '选择文件',
                onPressed: _pickFile,
                icon: Icons.file_upload,
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.file_present, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFilePath.split('/').last,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _selectedFilePath = '';
                        _outlines = [];
                        _selectedOutlines = {};
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ],
            
            if (_outlines.isNotEmpty) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('选择要导入的订阅源：'),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _selectAll,
                        child: const Text('全选'),
                      ),
                      TextButton(
                        onPressed: _deselectAll,
                        child: const Text('取消全选'),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              Consumer<AppStateProvider>(
                builder: (context, appState, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('选择目标文件夹（可选）：'), // 第一行文字
                      Row(
                        children: [
                          const Spacer(), // 让按钮靠右
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showCreateFolder = !_showCreateFolder;
                                if (!_showCreateFolder) {
                                  _newFolderController.clear();
                                }
                              });
                            },
                            icon: Icon(
                              _showCreateFolder ? Icons.remove : Icons.add,
                              size: 16,
                            ),
                            label: Text(_showCreateFolder ? '取消' : '新建文件夹'),
                          ),
                        ],
                      ),
                    ],
                  ),

                      const SizedBox(height: 8),
                      if (_showCreateFolder) ...[
                        Row(
                          children: [
                           Expanded(
                            child: TextField(
                              controller: _newFolderController,
                              decoration: const InputDecoration(
                                hintText: '输入文件夹名称',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onChanged: (_) {
                                setState(() {}); // 更新按钮状态
                              },
                            ),
                          ),

                            const SizedBox(width: 8),
                           ElevatedButton(
                              onPressed: _newFolderController.text.trim().isNotEmpty
                                  ? () async {
                                      final folder = Folder(name: _newFolderController.text.trim());
                                      await appState.addFolder(folder);
                                      setState(() {
                                        _showCreateFolder = false;
                                        _newFolderController.clear();
                                        _selectedFolderId = folder.id; // 创建成功后自动选中
                                      });
                                    }
                                  : null,
                              child: const Text('创建'),
                            ),

                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      DropdownButtonFormField<int?>(
                        value: _selectedFolderId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: const Text('不分组'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('不分组'),
                          ),
                          ...appState.folders.map((folder) => DropdownMenuItem<int?>(
                            value: folder.id,
                            child: Text(folder.name),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFolderId = value;
                          });
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _outlines.length,
                  itemBuilder: (context, index) {
                    final outline = _outlines[index];
                    final customTitle = _customTitles[outline.xmlUrl] ?? outline.title;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: CheckboxListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                customTitle,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () => _showEditTitleDialog(outline, customTitle),
                              tooltip: '编辑标题',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          outline.xmlUrl,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: _selectedOutlines[outline.xmlUrl] ?? false,
                        onChanged: (value) {
                          setState(() {
                            _selectedOutlines[outline.xmlUrl] = value ?? false;
                          });
                        },
                        dense: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
                 if (_outlines.isNotEmpty)
           ModernButton(
             text: '导入',
             onPressed: _isLoading ? null : _importSelected,
             isLoading: _isLoading,
           ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['opml', 'xml'],
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path!;
          _errorMessage = null;
        });
        await _parseOpmlFile();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '选择文件失败: $e';
      });
    }
  }

  Future<void> _parseOpmlFile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 读取文件内容
      final file = File(_selectedFilePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      final content = await file.readAsString();
      
      // 解析 OPML XML
      final document = XmlDocument.parse(content);
      final opmlElement = document.findElements('opml').firstOrNull;
      if (opmlElement == null) {
        throw Exception('无效的 OPML 文件格式');
      }

      final bodyElement = opmlElement.findElements('body').firstOrNull;
      if (bodyElement == null) {
        throw Exception('OPML 文件缺少 body 元素');
      }

      final outlines = <OpmlOutline>[];
      
      // 递归解析 outline 元素
      void parseOutlines(XmlElement element, [String? parentTitle]) {
        for (final child in element.children) {
          if (child is XmlElement && child.name.local == 'outline') {
            final title = child.getAttribute('title') ?? child.getAttribute('text') ?? '';
            final xmlUrl = child.getAttribute('xmlUrl') ?? child.getAttribute('url') ?? '';
            final htmlUrl = child.getAttribute('htmlUrl') ?? child.getAttribute('link') ?? '';
            
            // 如果有 xmlUrl，说明这是一个 feed
            if (xmlUrl.isNotEmpty) {
              final feedTitle = title.isNotEmpty ? title : _extractTitleFromUrl(xmlUrl);
              outlines.add(OpmlOutline(
                title: feedTitle,
                xmlUrl: xmlUrl,
                htmlUrl: htmlUrl,
              ));
            } else if (title.isNotEmpty) {
              // 这是一个文件夹，递归解析其子元素
              parseOutlines(child, title);
            }
          }
        }
      }
      
      parseOutlines(bodyElement);
      
      if (outlines.isEmpty) {
        throw Exception('OPML 文件中没有找到有效的订阅源');
      }
      
      setState(() {
        _outlines = outlines;
        
        // 默认全选
        for (final outline in _outlines) {
          _selectedOutlines[outline.xmlUrl] = true;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '解析 OPML 文件失败: $e';
        _isLoading = false;
      });
    }
  }

  // 从 URL 中提取标题
  String _extractTitleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      if (host.isNotEmpty) {
        return host.replaceAll('www.', '').split('.').first;
      }
    } catch (e) {
      // 忽略解析错误
    }
    return '未知订阅源';
  }

  // 显示编辑标题对话框
  void _showEditTitleDialog(OpmlOutline outline, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑标题'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入新的标题',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                setState(() {
                  _customTitles[outline.xmlUrl] = newTitle;
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _selectAll() {
    setState(() {
      for (final outline in _outlines) {
        _selectedOutlines[outline.xmlUrl] = true;
      }
    });
  }

  void _deselectAll() {
    setState(() {
      for (final outline in _outlines) {
        _selectedOutlines[outline.xmlUrl] = false;
      }
    });
  }

  Future<void> _importSelected() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final selectedOutlines = _outlines.where((outline) => _selectedOutlines[outline.xmlUrl] == true).toList();
      
      int successCount = 0;
      for (final outline in selectedOutlines) {
        try {
          final customTitle = _customTitles[outline.xmlUrl] ?? outline.title;
          final feed = RssFeed(
            title: customTitle,
            url: outline.xmlUrl,
            folderId: _selectedFolderId, // 使用选择的文件夹
          );
          await appState.addFeed(feed);
          successCount++;
        } catch (e) {
          print('导入订阅源失败: ${outline.title} - $e');
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功导入 $successCount 个订阅源${_selectedFolderId != null ? '到指定文件夹' : ''}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '导入失败: $e';
        _isLoading = false;
      });
    }
  }
}

class OpmlOutline {
  final String title;
  final String xmlUrl;
  final String htmlUrl;

  OpmlOutline({
    required this.title,
    required this.xmlUrl,
    required this.htmlUrl,
  });
}
