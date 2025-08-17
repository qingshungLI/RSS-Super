// lib/services/rss_service.dart
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart' as webfeed;
import 'dart:convert';
// 导入必需的模型类
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/models/video.dart';
import 'package:rss_reader/services/config.dart';
class RssParseResult {
  final List<Article> articles;
  final List<Video> videos;

  RssParseResult({required this.articles, required this.videos});
}

class RssService {
  static final Map<String, DateTime> _lastRequestStartByHost = {};

  Future<void> _enforceHostRateLimit(Uri uri) async {
    final String host = uri.host;
    final now = DateTime.now();
    final previous = _lastRequestStartByHost[host];
    // 基础间隔：常规 2s，rsshub 类域名提高到 6s，外加 0~300ms 抖动
    final bool isRssHub = host.contains('rsshub');
    final baseGap = Duration(seconds: isRssHub ? 6 : 2);
    final jitter = Duration(milliseconds: (now.microsecondsSinceEpoch % 300));
    final minGap = baseGap + jitter;
    if (previous != null) {
      final elapsed = now.difference(previous);
      if (elapsed < minGap) {
        await Future.delayed(minGap - elapsed);
      }
    }
    _lastRequestStartByHost[host] = DateTime.now();
  }
  // 定义一个异步方法，用于获取和解析RSS文章和视频
  Future<RssParseResult> fetchContent(String url, int feedId) async {
    // 规范化：支持 rsshub:// 前缀
    String normalizedUrl = url;
    if (url.startsWith('rsshub://')) {
      normalizedUrl = 'https://rsshub.app/${url.substring('rsshub://'.length)}';
    }

    final firstUri = Uri.parse(normalizedUrl);
    final List<Uri> candidates = [firstUri];
    if (firstUri.host.contains('rsshub')) {
      // 使用可配置镜像候选
      for (final host in AppConfig.rssHubHosts) {
        if (host == firstUri.host) continue;
        candidates.add(firstUri.replace(scheme: 'https', host: host));
      }
    }

    for (final uri in candidates) {
      int attempt = 0;
      const int maxAttempts = 5;
      int delayMs = 1500;

      while (true) {
        attempt++;
        try {
          await _enforceHostRateLimit(uri);
          final headers = <String, String>{
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Flutter RSS Reader) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36',
            'Accept': 'application/rss+xml, application/atom+xml, application/xml;q=0.9, text/xml;q=0.8, */*;q=0.5',
            'Accept-Encoding': 'gzip',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Connection': 'keep-alive',
          };
          if (uri.scheme == 'http' || uri.scheme == 'https') {
            headers['Referer'] = uri.origin;
          }
          final response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            return _parseFeedBytes(response.bodyBytes, feedId);
          }

          // 429/5xx重试
          if ((response.statusCode == 429 || response.statusCode >= 500) && attempt < maxAttempts) {
            int waitMs = delayMs;
            final retryAfter = response.headers['retry-after'];
            if (retryAfter != null) {
              final parsed = int.tryParse(retryAfter);
              if (parsed != null) {
                waitMs = parsed * 1000;
              }
            }
            await Future.delayed(Duration(milliseconds: waitMs));
            delayMs *= 2;
            continue;
          }

          // 其他非 200 状态：尝试下一个候选域名
          break;
        } on TimeoutException {
          if (attempt >= maxAttempts) {
            break;
          }
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs *= 2;
        } catch (e) {
          // 解析/网络异常：尝试下一个候选域名
          break;
        }
      }
    }

    print('Error fetching RSS feed: all candidates failed');
    return RssParseResult(articles: [], videos: []);
  }

  RssParseResult _parseFeedBytes(List<int> bodyBytes, int feedId) {
    final String xml = utf8.decode(bodyBytes);
    final List<Article> articles = [];
    final List<Video> videos = [];

    // 优先尝试RSS
    try {
      final rss = webfeed.RssFeed.parse(xml);
      if (rss.items != null) {
        for (final item in rss.items!) {
          if (item.enclosure != null && (item.enclosure!.type ?? '').startsWith('video/')) {
            videos.add(
              Video(
                id: null,
                title: item.title ?? 'No Title',
                url: item.enclosure!.url ?? (item.link ?? ''),
                tags: [],
                feedId: feedId,
                thumbnailUrl: (item.media != null && item.media!.thumbnails != null && item.media!.thumbnails!.isNotEmpty)
                    ? (item.media!.thumbnails!.first.url ?? '')
                    : '',
                description: item.description ?? 'No Content',
              ),
            );
          } else {
            articles.add(
              Article(
                id: null,
                title: item.title ?? 'No Title',
                content: item.description ?? 'No Content',
                url: item.link ?? '',
                pubDate: item.pubDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
                feedId: feedId,
              ),
            );
          }
        }
        return RssParseResult(articles: articles, videos: videos);
      }
    } catch (_) {
      // ignore and try Atom
    }

    // 尝试Atom
    try {
      final atom = webfeed.AtomFeed.parse(xml);
      if (atom.items != null) {
        for (final entry in atom.items!) {
          final link = (entry.links?.isNotEmpty == true) ? (entry.links!.first.href ?? '') : '';
          final content = entry.summary ?? entry.content ?? '';
          articles.add(
            Article(
              id: null,
              title: entry.title ?? 'No Title',
              content: content.isNotEmpty ? content : 'No Content',
              url: link,
              pubDate: entry.updated?.toIso8601String() ?? DateTime.now().toIso8601String(),
              feedId: feedId,
            ),
          );
        }
        return RssParseResult(articles: articles, videos: videos);
      }
    } catch (e) {
      // 解析失败
      print('Error parsing feed: $e');
    }

    return RssParseResult(articles: [], videos: []);
  }
}
