// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rss_reader/providers/theme_provider.dart';
import 'package:rss_reader/widgets/gradient_app_bar.dart';
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeMode _themeMode = ThemeMode.system;
 
  String _rsshubServer = 'https://rsshub.jordangong.app';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {

 
      // 从ThemeProvider获取当前主题
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      _themeMode = themeProvider.themeMode;
      
   
     
      _rsshubServer = prefs.getString('rsshubServer') ?? 'https://rsshub.app';
    });
  }

  // 保存设置
  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is ThemeMode) {
      await prefs.setString(key, _getThemeModeString(value));
    }
  }


  String _getThemeModeString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      case ThemeMode.system:
      default: return 'system';
    }
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return '浅色';
      case ThemeMode.dark: return '深色';
      case ThemeMode.system:
      default: return '跟随系统';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: "设置",
        centerTitle: true,
      ),
      body: ListView(
        children: [
         
           
              _buildListTile(
                "主题模式",
                _getThemeModeText(_themeMode),
                Icons.palette,
                () => _showThemeModeDialog(),
              ),
    
         
         
              _buildListTile(
                "RSSHub服务器",
                _rsshubServer,
                Icons.dns,
                () => _showRsshubServerDialog(),
              ),
          
          _buildSection(
            "关于",
            Icons.info,
            [
              _buildListTile(
                "应用版本",
                "1.0.0",
                Icons.app_settings_alt,
                null,
              ),
              
              _buildListTile(
                "意见反馈",
                "2731468336@qq.com邮件反馈",
                Icons.feedback,
                null,
              ),

              _buildListTile(
                "开源网址",
                "MIT License",
                Icons.code,
                () => _launchUrl("https://github.com/example/rss-super"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue.shade600, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(String title, String subtitle, IconData icon, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title),
      subtitle: SelectableText(subtitle, style: TextStyle(fontSize: 12)),
      trailing: onTap != null ? Icon(Icons.chevron_right, color: Colors.grey.shade400) : null,
      onTap: onTap,
    );
  }

  
  
 
  void _showThemeModeDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('主题模式'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<ThemeMode>(
            title: Text('浅色'),
            value: ThemeMode.light,
            groupValue: _themeMode,
            onChanged: (newValue) {
              setState(() => _themeMode = newValue!);
              _saveSetting('themeMode', _themeMode);
              _applyThemeChange();
              Navigator.pop(context); // 选择后直接关闭
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text('深色'),
            value: ThemeMode.dark,
            groupValue: _themeMode,
            onChanged: (newValue) {
              setState(() => _themeMode = newValue!);
              _saveSetting('themeMode', _themeMode);
              _applyThemeChange();
              Navigator.pop(context);
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text('跟随系统'),
            value: ThemeMode.system,
            groupValue: _themeMode,
            onChanged: (newValue) {
              setState(() => _themeMode = newValue!);
              _saveSetting('themeMode', _themeMode);
              _applyThemeChange();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}


  void _applyThemeChange() {
    // 通过Provider应用主题更改
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setThemeMode(_themeMode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('主题设置已应用')),
    );
  }

 

  

  void _showRsshubServerDialog() {
    final controller = TextEditingController(text: _rsshubServer);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('RSSHub服务器'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '服务器地址',
            hintText: 'https://rsshub.jordangong.app',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),
          ElevatedButton(
            onPressed: () {
              setState(() => _rsshubServer = controller.text);
              _saveSetting('rsshubServer', controller.text);
              Navigator.pop(context);
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }


  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('无法打开链接: $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
