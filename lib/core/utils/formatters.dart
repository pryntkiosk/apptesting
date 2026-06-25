import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  /// Parse an ISO8601 string (UTC) to local DateTime, tolerant of nulls.
  static DateTime? parse(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.toLocal();
  }

  /// e.g. "Jun 26, 14:32"
  static String dateTime(String? iso) {
    final dt = parse(iso);
    if (dt == null) return '—';
    return DateFormat('MMM d, HH:mm').format(dt);
  }

  /// Relative time like "5m ago", "2h ago", "3d ago".
  static String relative(String? iso) {
    final dt = parse(iso);
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  static String titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
