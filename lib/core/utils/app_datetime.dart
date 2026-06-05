import 'package:intl/intl.dart';

/// Liftoo app timezone — India Standard Time (Kolkata), UTC+5:30.
const Duration kIstOffset = Duration(hours: 5, minutes: 30);

DateTime toAppTime(DateTime value) {
  final utc = value.toUtc();
  return DateTime.fromMillisecondsSinceEpoch(
    utc.millisecondsSinceEpoch + kIstOffset.inMilliseconds,
  );
}

DateTime? parseAppTime(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final dt = DateTime.tryParse(iso);
  return dt == null ? null : toAppTime(dt);
}

DateTime appNow() => toAppTime(DateTime.now().toUtc());

bool isAppToday(DateTime value) {
  final ist = toAppTime(value);
  final now = appNow();
  return ist.year == now.year && ist.month == now.month && ist.day == now.day;
}

String formatAppDateTime(
  DateTime value, {
  String pattern = 'd MMM yyyy, h:mm a',
}) =>
    DateFormat(pattern).format(toAppTime(value));

String formatAppDateTimeIso(
  String? iso, {
  String pattern = 'd MMM yyyy, h:mm a',
}) {
  final dt = parseAppTime(iso);
  if (dt == null) return '';
  return DateFormat(pattern).format(dt);
}

String formatAppDateIso(
  String? iso, {
  String pattern = 'd MMM yyyy',
}) =>
    formatAppDateTimeIso(iso, pattern: pattern);
