import 'package:intl/intl.dart';

class AppHelpers {
  static String formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);
  static String formatDateTime(DateTime date) => DateFormat('MMM d, yyyy • h:mm a').format(date);
  static String formatTime(DateTime date) => DateFormat('h:mm a').format(date);
  static String formatShortDate(DateTime date) => DateFormat('MMM d').format(date);

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatShortDate(date);
  }

  static String durationLabel(int days) {
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }
}

class Validators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? required(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone is required';
    if (v.trim().length < 10) return 'Enter a valid phone number';
    return null;
  }
}

