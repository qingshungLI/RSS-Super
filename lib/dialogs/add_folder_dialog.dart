// lib/dialogs/add_folder_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/models/folder.dart';
import 'package:rss_reader/providers/app_state_provider.dart';

class AddFolderDialog extends StatefulWidget {
  @override
  State<AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends State<AddFolderDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createFolder() async {
    if (!_formKey.currentState!.validate()) return;
    final String name = _nameController.text.trim();
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    await appState.addFolder(Folder(name: name));
    // 通过名称在最新的列表中找到新建的文件夹对象
    final Folder? created = appState.folders.firstWhere(
      (f) => f.name == name,
      orElse: () => Folder(name: name),
    );
    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建文件夹'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '文件夹名称',
            hintText: '例如：科技、视频、博客',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入文件夹名称';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _createFolder,
          child: const Text('创建'),
        ),
      ],
    );
  }
}


