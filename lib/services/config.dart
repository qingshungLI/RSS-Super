// lib/services/config.dart

class AppConfig {
  // 可配置的 RSSHub 域名候选列表（按优先级顺序）
  // 如果默认域名在你的网络环境下不可达，请在这里添加一个可访问的镜像域名
  // 例如：'your.self.hosted.rsshub.example.com'
  static List<String> rssHubHosts = <String>[
    'rsshub.app',
    'rsshub.rssforever.com',
    'rsshub.uneasy.win',
  ];
}


