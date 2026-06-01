class DurationOption {
  final int minutes;
  final String label;

  const DurationOption({required this.minutes, required this.label});
}

class BookingDurationOptions {
  static const options = [
    DurationOption(minutes: 30, label: '30 min'),
    DurationOption(minutes: 60, label: '1 hour'),
    DurationOption(minutes: 120, label: '2 hours'),
    DurationOption(minutes: 180, label: '3 hours'),
    DurationOption(minutes: 240, label: '4 hours'),
  ];

  static String labelFor(int minutes) {
    for (final o in options) {
      if (o.minutes == minutes) return o.label;
    }
    return '$minutes min';
  }
}
