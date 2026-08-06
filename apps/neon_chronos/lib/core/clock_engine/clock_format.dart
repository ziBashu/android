/// Pure time formatting helpers (12/24h, labels).
class ClockFormat {
  ClockFormat._();

  static String two(int n) => n.toString().padLeft(2, '0');

  static String hour(DateTime t, {required bool hour24}) {
    if (hour24) return two(t.hour);
    final h = t.hour % 12;
    return two(h == 0 ? 12 : h);
  }

  static String amPm(DateTime t) => t.hour < 12 ? 'AM' : 'PM';

  static String timeHms(DateTime t, {required bool hour24}) {
    return '${hour(t, hour24: hour24)}:${two(t.minute)}:${two(t.second)}';
  }

  static String timeHm(DateTime t, {required bool hour24}) {
    return '${hour(t, hour24: hour24)}:${two(t.minute)}';
  }

  static String timeHmsMs(DateTime base, Duration elapsed) {
    final totalMs = elapsed.inMilliseconds;
    final h = totalMs ~/ 3600000;
    final m = (totalMs % 3600000) ~/ 60000;
    final s = (totalMs % 60000) ~/ 1000;
    final cs = (totalMs % 1000) ~/ 10;
    if (h > 0) {
      return '${two(h)}:${two(m)}:${two(s)}.${two(cs)}';
    }
    return '${two(m)}:${two(s)}.${two(cs)}';
  }

  static String countdown(Duration d) {
    final total = d.inSeconds.clamp(0, 359999);
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) return '${two(h)}:${two(m)}:${two(s)}';
    return '${two(m)}:${two(s)}';
  }

  static String weekday(DateTime t) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[(t.weekday - 1).clamp(0, 6)];
  }

  static String dateLine(DateTime t) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final m = months[(t.month - 1).clamp(0, 11)];
    return '$m ${two(t.day)} ${t.year}';
  }

  /// Fraction of local day elapsed [0, 1].
  static double dayProgress(DateTime t) {
    final sec = t.hour * 3600 + t.minute * 60 + t.second + t.millisecond / 1000;
    return (sec / 86400).clamp(0.0, 1.0);
  }
}
