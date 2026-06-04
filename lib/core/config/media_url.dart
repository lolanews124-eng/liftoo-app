import 'app_config.dart';

/// Resolves upload paths and fixes localhost URLs from dev admin uploads.
String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  final raw = url.trim();
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    final lower = raw.toLowerCase();
    if (lower.contains('localhost') || lower.contains('127.0.0.1')) {
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.path.isNotEmpty) {
        return '${AppConfig.apiUrl}${uri.path}';
      }
    }
    return raw;
  }
  if (raw.startsWith('/')) return '${AppConfig.apiUrl}$raw';
  return '${AppConfig.apiUrl}/$raw';
}
