// lib/dialogs/add_feed_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/providers/app_state_provider.dart';
import 'package:rss_reader/models/rss_feed.dart';
import 'package:rss_reader/models/folder.dart';
import 'package:rss_reader/dialogs/add_folder_dialog.dart';

class AddFeedDialog extends StatefulWidget {
  const AddFeedDialog({super.key});

  @override
  _AddFeedDialogState createState() => _AddFeedDialogState();
}

class _AddFeedDialogState extends State<AddFeedDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  Folder? _selectedFolder;
  String? _customTitle;

  @override
  void initState() {
    super.initState();
    // 确保在对话框构建时，文件夹列表已经被加载
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (appState.folders.isNotEmpty) {
      _selectedFolder = appState.folders.first;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _promptForTitle() async {
    final controller = TextEditingController(text: _customTitle ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('设置订阅名称'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '名称',
              hintText: '例如：博主名称/来源名称',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        _customTitle = result.isEmpty ? null : result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("添加 RSS 订阅源（opml侧栏订阅源导入）"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: "RSS URL",
                      hintText: "例如: https://rsshub.app/bilibili/user/dynamic/2267573",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入一个URL';
                      }
                      if (!Uri.parse(value).isAbsolute) {
                        return '请输入一个有效的URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _customTitle == null || _customTitle!.isEmpty
                              ? '未设置名称（将使用默认名称）'
                              : '名称：${_customTitle!}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('设置名称'),
                        onPressed: _promptForTitle,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (appState.folders.isNotEmpty) ...[
                    DropdownButtonFormField<Folder>(
                      value: _selectedFolder,
                      decoration: InputDecoration(
                        labelText: "选择文件夹",
                      ),
                      items: appState.folders.map((folder) {
                        return DropdownMenuItem(
                          value: folder,
                          child: Text(folder.name),
                        );
                      }).toList(),
                      onChanged: (Folder? newValue) {
                        setState(() {
                          _selectedFolder = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.create_new_folder_outlined),
                        label: const Text('新建文件夹'),
                        onPressed: () async {
                          final created = await showDialog<Folder>(
                            context: context,
                            builder: (context) => AddFolderDialog(),
                          );
                          if (created != null) {
                            setState(() {
                              _selectedFolder = created;
                            });
                          }
                        },
                      ),
                    ),
                  ] else ...[
                    // 如果没有文件夹，可以提供一个添加文件夹的选项
                    OutlinedButton.icon(
                      icon: const Icon(Icons.create_new_folder_outlined),
                      onPressed: () async {
                        final created = await showDialog<Folder>(
                          context: context,
                          builder: (context) => AddFolderDialog(),
                        );
                        if (created != null) {
                          setState(() {
                            _selectedFolder = created;
                          });
                        }
                      },
                      label: const Text("没有文件夹，点击新建一个"),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("取消"),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newFeed = RssFeed(
                title: (_customTitle != null && _customTitle!.trim().isNotEmpty)
                    ? _customTitle!.trim()
                    : '新订阅源', // 初始标题，可在后续解析中更新
                url: _urlController.text,
                folderId: _selectedFolder?.id,
              );
              Provider.of<AppStateProvider>(context, listen: false).addFeed(newFeed);
              Navigator.pop(context); // 关闭对话框
            }
          },
          child: Text("添加"),
        ),
      ],
    );
  }
}
