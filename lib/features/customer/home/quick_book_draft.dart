/// Pre-filled values from home Quick Book.
class QuickBookDraft {
  final String? categorySlug;
  final String? locationId;
  final String? venueName;
  final double? lat;
  final double? lng;
  final int? durationMin;

  const QuickBookDraft({
    this.categorySlug,
    this.locationId,
    this.venueName,
    this.lat,
    this.lng,
    this.durationMin,
  });
}
