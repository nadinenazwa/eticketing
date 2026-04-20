import 'package:intl/intl.dart';

class DateFormatter {
  static String format(DateTime date) =>
      DateFormat('dd MMM yyyy, HH:mm').format(date);

  static String formatShort(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60)  return '${diff.inSeconds} detik lalu';
    if (diff.inMinutes < 60)  return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24)    return '${diff.inHours} jam lalu';
    if (diff.inDays < 7)      return '${diff.inDays} hari lalu';
    if (diff.inDays < 30)     return '${(diff.inDays / 7).floor()} minggu lalu';
    if (diff.inDays < 365)    return '${(diff.inDays / 30).floor()} bulan lalu';
    return '${(diff.inDays / 365).floor()} tahun lalu';
  }
}
