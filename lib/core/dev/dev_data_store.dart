import 'dart:async';
import 'dart:math';
import '../../shared/models/address_model.dart';
import '../../shared/models/booking_tracking_model.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/review_models.dart';
import '../../shared/models/assistant_verification_model.dart';

/// In-memory backend when API is unreachable (phone without server).
class DevDataStore {
  DevDataStore._();
  static final instance = DevDataStore._();

  static const enabled = bool.fromEnvironment('DEV_MOCK_AUTH', defaultValue: true);

  final _rng = Random();
  final Map<String, BookingModel> _bookings = {};
  final List<Map<String, dynamic>> _transactions = [];
  final List<Map<String, dynamic>> _notifications = [];
  final Map<String, Timer> _simTimers = {};

  double walletBalance = 1000;
  /// Assistant settlement balance (for cash job company share).
  double assistantSettlementBalance = 500;
  String referralCode = 'LIFDEV';
  int totalReferrals = 2;
  double totalEarned = 200;
  bool assistantOnline = false;
  final Map<String, ({double lat, double lng})> _assistantTrack = {};
  bool _seeded = false;
  final Set<String> _rejectedBookingIds = {};
  final Map<String, Map<String, dynamic>> _userProfiles = {
    'dev-user-9876543210': {
      'name': 'Rahul Sharma',
      'phone': '9876543210',
      'avatarUrl': null,
      'profileComplete': true,
    },
  };

  void setAssistantOnline(bool online) => assistantOnline = online;

  Map<String, dynamic>? getUserProfile(String userId) => _userProfiles[userId];

  bool isUserProfileComplete(String userId) =>
      _userProfiles[userId]?['profileComplete'] == true;

  Map<String, dynamic> saveUserProfile(
    String userId, {
    required String name,
    required String phone,
    String? avatarUrl,
  }) {
    final trimmedPhone = phone.trim();
    final profile = {
      'name': name.trim(),
      'phone': trimmedPhone,
      'avatarUrl': avatarUrl,
      'profileComplete': name.trim().length >= 2 && RegExp(r'^[6-9]\d{9}$').hasMatch(trimmedPhone),
    };
    _userProfiles[userId] = profile;
    return profile;
  }

  static const assistantId = 'asst-dev-1';

  static Map<String, dynamic> assistantProfile({double rating = 4.9, int totalJobs = 48, int reviewCount = 42}) => {
        'rating': rating,
        'totalJobs': totalJobs,
        'reviewCount': reviewCount,
      };

  static Map<String, dynamic> assistantSnapshot({double rating = 4.9, int totalJobs = 48, int reviewCount = 42}) => {
        'id': assistantId,
        'name': 'Rohit Kumar',
        'phone': '9876543211',
        'assistantProfile': assistantProfile(rating: rating, totalJobs: totalJobs, reviewCount: reviewCount),
      };

  double _assistantRating = 4.9;
  int _assistantTotalJobs = 48;
  int _assistantReviewCount = 42;
  final Map<String, Map<String, dynamic>> _ratings = {};
  final Map<String, Map<String, dynamic>> _appReviews = {};
  final Set<String> _justPaidBookingIds = {};
  final Map<String, Map<String, Map<String, dynamic>>> _verificationDocs = {};

  static const _verificationTypeDefs = [
    ('profile_photo', 'Profile photo'),
    ('full_address', 'Full address'),
    ('aadhaar', 'Aadhaar card'),
    ('pan', 'PAN card'),
    ('selfie', 'Selfie verification'),
    ('bank_details', 'Bank details'),
    ('security_photo_1', 'Security photo 1'),
    ('security_photo_2', 'Security photo 2'),
    ('security_photo_3', 'Security photo 3'),
    ('security_photo_4', 'Security photo 4'),
    ('security_photo_5', 'Security photo 5'),
  ];

  static final categories = [
    const ServiceCategoryModel(id: 'cat-bag', slug: 'bag_carry', name: 'Bag Carry', baseRate: 49),
    const ServiceCategoryModel(id: 'cat-queue', slug: 'queue', name: 'Queue Help', baseRate: 59),
    const ServiceCategoryModel(id: 'cat-senior', slug: 'senior', name: 'Senior Help', baseRate: 79),
    const ServiceCategoryModel(id: 'cat-family', slug: 'family', name: 'Family Help', baseRate: 69),
    const ServiceCategoryModel(id: 'cat-festival', slug: 'festival', name: 'Festival Help', baseRate: 89),
  ];

  void ensureSeeded() {
    if (_seeded) return;
    _seeded = true;

    _transactions.addAll([
      {
        'id': 'tx-1',
        'type': 'credit',
        'amount': 500,
        'description': 'Welcome bonus',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': 'tx-2',
        'type': 'debit',
        'amount': 120,
        'description': 'Booking payment',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
    ]);

    _notifications.addAll([
      {
        'id': 'n-1',
        'title': 'Welcome to Liftoo!',
        'body': 'Book your first assistant and get ₹50 off.',
        'readAt': null,
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 'n-2',
        'title': 'Rohit is on the way',
        'body': 'Your assistant will reach P&M Mall in ~5 mins.',
        'readAt': null,
        'createdAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      },
      {
        'id': 'n-3',
        'title': 'Refer & Earn ₹100',
        'body': 'Share code LIFDEV with friends.',
        'readAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
    ]);

    final cat = categories.first;
    _bookings['demo-active-1'] = BookingModel(
      id: 'demo-active-1',
      status: 'arriving',
      durationMin: 60,
      venueName: 'P&M Mall, Patna',
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      addressFormatted: 'P&M Mall, Fraser Road, Patna',
      lat: 25.609,
      lng: 85.137,
      serviceFee: 49,
      platformFee: 4.9,
      totalAmount: 53.9,
      category: cat,
      customer: const {'name': 'Amit Verma', 'phone': '9123456780'},
      assistant: assistantSnapshot(),
      statusHistory: [
        StatusHistoryModel(status: 'searching', createdAt: DateTime.now().subtract(const Duration(minutes: 12))),
        StatusHistoryModel(status: 'assigned', createdAt: DateTime.now().subtract(const Duration(minutes: 8))),
        StatusHistoryModel(status: 'arriving', createdAt: DateTime.now().subtract(const Duration(minutes: 3))),
      ],
    );

    _bookings['demo-search-1'] = BookingModel(
      id: 'demo-search-1',
      status: 'searching',
      durationMin: 120,
      venueName: 'City Centre, Patna',
      scheduledAt: DateTime.now().add(const Duration(minutes: 45)),
      addressFormatted: 'City Centre, Buddha Colony, Patna',
      lat: 25.6011,
      lng: 85.1198,
      serviceFee: 118,
      platformFee: 11.8,
      totalAmount: 129.8,
      category: categories[2],
      customer: const {'name': 'Priya Sharma', 'phone': '9988776655'},
      statusHistory: [
        StatusHistoryModel(status: 'searching', createdAt: DateTime.now().subtract(const Duration(minutes: 2))),
      ],
    );

    _bookings['demo-done-1'] = BookingModel(
      id: 'demo-done-1',
      status: 'completed',
      durationMin: 60,
      venueName: 'Maurya Lok, Patna',
      scheduledAt: DateTime.now().subtract(const Duration(days: 2)),
      addressFormatted: 'Maurya Lok, Patna',
      lat: 25.61,
      lng: 85.14,
      serviceFee: 59,
      platformFee: 5.9,
      totalAmount: 64.9,
      category: categories[1],
      assistant: assistantSnapshot(),
      payment: {
        'method': 'wallet',
        'status': 'completed',
        'amount': 64.9,
        'paidAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      statusHistory: [
        StatusHistoryModel(status: 'completed', createdAt: DateTime.now().subtract(const Duration(days: 2))),
      ],
    );

    _bookings['demo-cancel-1'] = BookingModel(
      id: 'demo-cancel-1',
      status: 'cancelled',
      durationMin: 30,
      venueName: 'City Centre, Patna',
      scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
      addressFormatted: 'City Centre, Patna',
      lat: 25.60,
      lng: 85.13,
      serviceFee: 24.5,
      platformFee: 2.45,
      totalAmount: 26.95,
      category: cat,
      statusHistory: [
        StatusHistoryModel(status: 'cancelled', createdAt: DateTime.now().subtract(const Duration(days: 1))),
      ],
    );
  }

  ServiceCategoryModel? categoryBySlug(String slug) {
    try {
      return categories.firstWhere((c) => c.slug == slug);
    } catch (_) {
      return null;
    }
  }

  ServiceCategoryModel? categoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<BookingModel> getBookings({String? status, String? asRole}) {
    ensureSeeded();
    var all = _bookings.values.toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    if (asRole == 'assistant') {
      all = all
          .where((b) => b.assistant != null && b.assistant!['id'] == assistantId)
          .toList();
    }

    if (status == null) return all.map(_hydrate).toList();
    if (status == 'upcoming') {
      return all.where((b) => b.isActive).map(_hydrate).toList();
    }
    if (status == 'completed') {
      return all.where((b) => b.status == 'completed').map(_hydrate).toList();
    }
    if (status == 'cancelled') {
      return all.where((b) => b.status == 'cancelled').map(_hydrate).toList();
    }
    if (status == 'searching') {
      return all
          .where((b) => b.status == 'searching' && !_rejectedBookingIds.contains(b.id))
          .map(_hydrate)
          .toList();
    }
    return all.where((b) => b.status == status).map(_hydrate).toList();
  }

  BookingModel? getActiveBooking() {
    final upcoming = getBookings(status: 'upcoming');
    return upcoming.isEmpty ? null : upcoming.first;
  }

  BookingModel getBooking(String id) {
    ensureSeeded();
    final b = _bookings[id];
    if (b == null) throw Exception('Booking not found');
    return _hydrate(b);
  }

  BookingModel _hydrate(BookingModel b) {
    final rating = _ratings[b.id];
    final appReview = _appReviews[b.id];
    Map<String, dynamic>? assistant = b.assistant;
    if (assistant != null) {
      assistant = Map<String, dynamic>.from(assistant);
      assistant['assistantProfile'] = assistantProfile(
        rating: _assistantRating,
        totalJobs: _assistantTotalJobs,
        reviewCount: _assistantReviewCount,
      );
    }
    var result = _copy(b, assistant: assistant, rating: rating, appReview: appReview);
    if (b.status == 'searching') {
      result = _copy(result, searchAvailability: _mockSearchAvailability(b));
    }
    if (b.assistant != null && ['assigned', 'arriving', 'started'].contains(b.status)) {
      result = _copy(result, tracking: _mockTracking(b));
    }
    return result;
  }

  Map<String, dynamic> getAvailabilitySummary(double lat, double lng) => {
        'totalOnline': 4,
        'nearbyAvailable': 3,
        'within2Km': 2,
        'matchRadiusKm': 10,
        'zones': [
          {'label': 'Within 2 km', 'count': 2},
          {'label': '2–5 km', 'count': 1},
        ],
        'message': '3 assistants available near you',
      };

  /// Online assistants around pickup (for booking map step).
  List<Map<String, dynamic>> getNearbyAssistants(double lat, double lng) => [
        {
          'id': 'asst-rohit',
          'name': 'Rohit Kumar',
          'lat': lat + 0.0082,
          'lng': lng + 0.0055,
          'distanceKm': '1.1',
          'rating': 4.9,
          'totalJobs': 48,
          'assistantCode': 'LF-1001',
          'isOnline': true,
        },
        {
          'id': 'asst-priya',
          'name': 'Priya Sharma',
          'lat': lat - 0.0065,
          'lng': lng + 0.0092,
          'distanceKm': '1.4',
          'rating': 4.8,
          'totalJobs': 32,
          'assistantCode': 'LF-1002',
          'isOnline': true,
        },
        {
          'id': 'asst-amit',
          'name': 'Amit Singh',
          'lat': lat + 0.012,
          'lng': lng - 0.007,
          'distanceKm': '2.0',
          'rating': 4.7,
          'totalJobs': 21,
          'assistantCode': 'LF-1003',
          'isOnline': true,
        },
      ];

  void updateAssistantLocation(double lat, double lng) {
    for (final id in _assistantTrack.keys) {
      _assistantTrack[id] = (lat: lat, lng: lng);
    }
    if (_assistantTrack.isEmpty) {
      _assistantTrack['default'] = (lat: lat, lng: lng);
    }
  }

  BookingModel setArriving(String id) {
    final current = getBooking(id);
    final track = _assistantTrack[id] ?? _trackStart(current);
    _assistantTrack[id] = track;
    final updated = _copy(
      current,
      status: 'arriving',
      history: [
        ...current.statusHistory,
        StatusHistoryModel(status: 'arriving', createdAt: DateTime.now()),
      ],
    );
    _bookings[id] = updated;
    return _hydrate(updated);
  }

  ({double lat, double lng}) _trackStart(BookingModel b) =>
      (lat: b.lat + 0.025, lng: b.lng + 0.018);

  ({double lat, double lng}) _trackPos(BookingModel b) {
    final start = _assistantTrack[b.id] ?? _trackStart(b);
    if (b.status == 'assigned') return start;
    if (b.status == 'arriving') {
      final t = 0.55;
      return (
        lat: start.lat + (b.lat - start.lat) * t,
        lng: start.lng + (b.lng - start.lng) * t,
      );
    }
    return (lat: b.lat, lng: b.lng);
  }

  BookingSearchAvailability _mockSearchAvailability(BookingModel b) => BookingSearchAvailability(
        nearbyAvailable: 3,
        matchRadiusKm: 10,
        areaLabel: b.venueName,
        zones: const [
          BookingZoneAvailability(label: 'Within 2 km', count: 2),
          BookingZoneAvailability(label: '2–5 km', count: 1),
        ],
        notifiedCount: 2,
        message: '3 assistants available near ${b.venueName}',
      );

  BookingTrackingModel _mockTracking(BookingModel b) {
    final pos = _trackPos(b);
    const distance = 2.4;
    return BookingTrackingModel(
      customer: BookingTrackingPoint(lat: b.lat, lng: b.lng, label: b.venueName, address: b.addressFormatted),
      assistant: BookingTrackingPoint(
        lat: pos.lat,
        lng: pos.lng,
        name: b.assistant?['name'] as String? ?? 'Assistant',
      ),
      distanceKm: b.status == 'started' ? '0.0' : distance.toStringAsFixed(1),
      etaMinutes: b.status == 'started' ? 0 : 8,
      statusMessage: b.status == 'assigned'
          ? 'Assistant confirmed — getting ready to leave'
          : b.status == 'arriving'
              ? 'Assistant is on the way to you'
              : 'Service in progress at your location',
      progress: b.status == 'assigned' ? 0.25 : b.status == 'arriving' ? 0.65 : 1,
    );
  }

  BookingModel createBooking(Map<String, dynamic> body) {
    ensureSeeded();
    final catId = body['categoryId'] as String;
    final cat = categoryById(catId) ?? categories.first;
    final duration = body['durationMin'] as int;
    final serviceFee = cat.baseRate * (duration / 60);
    final platformFee = serviceFee * 0.1;
    final id = 'bk-${DateTime.now().millisecondsSinceEpoch}';

    final booking = BookingModel(
      id: id,
      status: 'pending',
      durationMin: duration,
      venueName: body['venueName'] as String,
      scheduledAt: DateTime.parse(body['scheduledAt'] as String),
      addressFormatted: body['addressFormatted'] as String,
      lat: (body['lat'] as num).toDouble(),
      lng: (body['lng'] as num).toDouble(),
      serviceFee: serviceFee,
      platformFee: platformFee,
      totalAmount: serviceFee + platformFee,
      category: cat,
      statusHistory: [
        StatusHistoryModel(status: 'pending', createdAt: DateTime.now()),
      ],
    );
    _bookings[id] = booking;
    _addNotification('Booking created', '${cat.name} at ${booking.venueName}');
    return booking;
  }

  BookingModel confirmBooking(String id) {
    final current = getBooking(id);
    final updated = _copy(current, status: 'searching', history: [
      ...current.statusHistory,
      StatusHistoryModel(status: 'searching', createdAt: DateTime.now()),
    ]);
    _bookings[id] = updated;
    _simulateProgress(id);
    _addNotification('Finding assistant', 'Searching near ${updated.venueName}...');
    return updated;
  }

  void _simulateProgress(String id) {
    _simTimers[id]?.cancel();
    _simTimers[id] = Timer(const Duration(seconds: 2), () {
      _setStatus(id, 'assigned', assignAssistant: true);
      _addNotification('Assistant assigned', '${assistantSnapshot()['name']} accepted your booking.');
      _simTimers[id] = Timer(const Duration(seconds: 3), () {
        _setStatus(id, 'arriving');
        _addNotification('On the way', '${assistantSnapshot()['name']} is arriving. Share OTP when they reach you.');
        _simTimers[id] = Timer(const Duration(seconds: 8), () {
          final current = _bookings[id];
          if (current != null && current.status == 'arriving') {
            startService(id);
            _addNotification('Service started', 'OTP verified. Your service timer is now running.');
          }
        });
      });
    });
  }

  BookingModel verifyServiceOtp(String id, String otp) {
    final current = getBooking(id);
    final expected = current.serviceOtp ?? '1234';
    if (otp.trim() != expected) {
      throw Exception('Invalid OTP');
    }
    if (current.status == 'started') return current;
    if (!['assigned', 'arriving'].contains(current.status)) {
      throw Exception('Cannot start service in current status');
    }
    return startService(id);
  }

  BookingModel startService(String id) {
    final current = getBooking(id);
    final updated = _copy(
      current,
      status: 'started',
      serviceOtp: current.serviceOtp ?? '1234',
      history: [
        ...current.statusHistory,
        StatusHistoryModel(status: 'started', createdAt: DateTime.now()),
      ],
    );
    _bookings[id] = updated;
    _addNotification('Service started', 'Timer is running. Assistant is helping you shop.');
    _simTimers[id]?.cancel();
    _simTimers[id] = Timer(const Duration(seconds: 25), () {
      completeService(id);
      _addNotification('Service completed', 'Please complete payment for your booking.');
    });
    return updated;
  }

  BookingModel completeService(String id) {
    final current = getBooking(id);
    final assistantEarning = (current.serviceFee * 0.8).roundToDouble();
    final companyShare = current.totalAmount - assistantEarning;
    final updated = _copy(
      current,
      status: 'completed',
      payment: {
        'amount': current.totalAmount,
        'status': 'pending',
      },
      paymentConfirmOtp: '1234',
      assistantEarningAmount: assistantEarning,
      companyShareAmount: companyShare,
      history: [
        ...current.statusHistory,
        StatusHistoryModel(status: 'completed', createdAt: DateTime.now()),
      ],
    );
    _bookings[id] = updated;
    _addNotification('Service completed', 'Please pay ₹${current.totalAmount.toStringAsFixed(0)} for your booking.');
    return updated;
  }

  BookingModel markCashCollected(String id) {
    final b = getBooking(id);
    if (b.status != 'completed') throw Exception('Booking not completed');
    if (b.isPaid) throw Exception('Already paid');
    final companyShare = b.companyShareAmount ?? (b.totalAmount - b.serviceFee * 0.8);
    if (assistantSettlementBalance < companyShare) {
      throw Exception(
        'Add at least ₹${companyShare.toStringAsFixed(0)} to settlement wallet (current ₹${assistantSettlementBalance.toStringAsFixed(0)})',
      );
    }
    final updated = _copy(
      b,
      payment: {
        'amount': b.totalAmount,
        'status': 'pending',
        'method': 'cash',
        'cashCollectedAt': DateTime.now().toIso8601String(),
      },
    );
    _bookings[id] = updated;
    return updated;
  }

  PaymentResultModel confirmCashPayment(String id, String otp) {
    final b = getBooking(id);
    if (b.paymentConfirmOtp != otp.trim()) throw Exception('Invalid payment OTP');
    if (b.payment?['cashCollectedAt'] == null) {
      throw Exception('Assistant must confirm cash received first');
    }
    return payBooking(id, 'cash');
  }

  BookingModel acceptBooking(String id) {
    final current = getBooking(id);
    if (current.status != 'searching') throw Exception('Booking not available');
    _simTimers[id]?.cancel();
    final updated = _copy(
      current,
      status: 'assigned',
      assistant: assistantSnapshot(),
      serviceOtp: '1234',
      history: [
        ...current.statusHistory,
        StatusHistoryModel(status: 'assigned', createdAt: DateTime.now()),
      ],
    );
    _bookings[id] = updated;
    _assistantTrack[id] = _trackStart(updated);
    return _hydrate(updated);
  }

  void rejectBooking(String id, {required String reason}) {
    _rejectedBookingIds.add(id);
    _simTimers[id]?.cancel();
  }

  BookingModel cancelBooking(String id, {required String reason, String? note}) {
    final current = getBooking(id);
    if (!current.isActive) return current;
    _simTimers[id]?.cancel();
    final cancelNote = note != null && note.isNotEmpty ? '$reason — $note' : reason;
    final updated = _copy(
      current,
      status: 'cancelled',
      history: [
        ...current.statusHistory,
        StatusHistoryModel(status: 'cancelled', note: cancelNote, createdAt: DateTime.now()),
      ],
    );
    _bookings[id] = updated;
    _addNotification('Booking cancelled', '${current.venueName} booking was cancelled.');
    return updated;
  }

  void addWalletMoney(double amount, {String method = 'upi'}) {
    ensureSeeded();
    walletBalance += amount;
    final methodLabel = method == 'card' ? 'Card' : 'UPI';
    _transactions.insert(0, {
      'id': 'tx-${_rng.nextInt(99999)}',
      'type': 'credit',
      'amount': amount,
      'description': 'Wallet top-up via $methodLabel',
      'createdAt': DateTime.now().toIso8601String(),
    });
    _addNotification('Wallet credited', '₹${amount.toStringAsFixed(0)} added via $methodLabel');
  }

  void markNotificationRead(String id) {
    final i = _notifications.indexWhere((n) => n['id'] == id);
    if (i >= 0) {
      _notifications[i] = {..._notifications[i], 'readAt': DateTime.now().toIso8601String()};
    }
  }

  void _setStatus(String id, String status, {bool assignAssistant = false}) {
    final current = _bookings[id];
    if (current == null) return;
    final otp = status == 'arriving' && current.serviceOtp == null ? '1234' : current.serviceOtp;
    _bookings[id] = _copy(
      current,
      status: status,
      assistant: assignAssistant ? assistantSnapshot() : current.assistant,
      serviceOtp: otp,
      history: [
        ...current.statusHistory,
        StatusHistoryModel(status: status, createdAt: DateTime.now()),
      ],
    );
  }

  void markJustPaid(String bookingId) => _justPaidBookingIds.add(bookingId);

  bool wasJustPaid(String bookingId) => _justPaidBookingIds.contains(bookingId);

  void clearJustPaid(String bookingId) => _justPaidBookingIds.remove(bookingId);

  PaymentResultModel payBooking(String id, String method) {
    final b = getBooking(id);
    if (b.status != 'completed') throw Exception('Complete the service first');
    if (b.isPaid) throw Exception('Payment already completed');
    if (method == 'cash' && b.payment?['cashCollectedAt'] == null) {
      throw Exception('Assistant must confirm cash received first');
    }
    if (method == 'wallet') {
      if (walletBalance < b.totalAmount) {
        throw Exception('Insufficient wallet balance');
      }
      walletBalance -= b.totalAmount;
      _transactions.insert(0, {
        'id': 'tx-${_rng.nextInt(99999)}',
        'type': 'debit',
        'amount': b.totalAmount,
        'description': 'Booking ${b.id}',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    if (method == 'cash') {
      final companyShare = b.companyShareAmount ?? (b.totalAmount - b.serviceFee * 0.8);
      if (assistantSettlementBalance < companyShare) {
        throw Exception('Insufficient settlement wallet for company share');
      }
      assistantSettlementBalance -= companyShare;
    }
    final assistantEarning = b.assistantEarningAmount ?? (b.serviceFee * 0.8);
    _bookings[id] = _copy(
      b,
      status: 'completed',
      payment: {
        'method': method,
        'status': 'completed',
        'amount': b.totalAmount,
        'paidAt': DateTime.now().toIso8601String(),
        if (b.payment?['cashCollectedAt'] != null) 'cashCollectedAt': b.payment!['cashCollectedAt'],
      },
      clearPaymentOtp: true,
      assistantEarningAmount: assistantEarning,
    );
    _addNotification('Payment successful', '₹${b.totalAmount.toStringAsFixed(0)} paid via ${method.toUpperCase()}');
    markJustPaid(id);
    final updated = getBooking(id);
    return PaymentResultModel(
      payment: updated.payment,
      booking: updated,
      nextStep: updated.nextStep,
      walletBalance: walletBalance,
    );
  }

  ServiceReviewResult submitServiceReview(String bookingId, int stars, {String? comment}) {
    final b = getBooking(bookingId);
    if (b.payment == null) throw Exception('Payment required before review');
    if (b.rating != null) throw Exception('Booking already rated');

    _ratings[bookingId] = {
      'id': 'r-$bookingId',
      'stars': stars,
      if (comment != null) 'comment': comment,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _assistantReviewCount++;
    _assistantRating = ((_assistantRating * (_assistantReviewCount - 1)) + stars) / _assistantReviewCount;
    _addNotification('Thanks for your review!', 'You rated your assistant $stars stars.');

    return ServiceReviewResult(
      id: 'r-$bookingId',
      stars: stars,
      comment: comment,
      nextStep: 'rate_app',
      assistantStats: getAssistantStats(assistantId),
    );
  }

  void submitAppReview(int stars, {String? bookingId, String? comment}) {
    if (bookingId != null) {
      final b = getBooking(bookingId);
      if (b.rating == null) throw Exception('Service review required first');
      if (b.appReview != null) throw Exception('App review already submitted');
      _appReviews[bookingId] = {
        'id': 'ar-$bookingId',
        'stars': stars,
        if (comment != null) 'comment': comment,
        'createdAt': DateTime.now().toIso8601String(),
      };
    }
    _addNotification('Thank you!', 'Your feedback helps us improve Liftoo.');
  }

  AssistantStatsModel getAssistantStats(String userId) => AssistantStatsModel(
        userId: userId,
        name: assistantSnapshot()['name'] as String,
        rating: _assistantRating,
        totalJobs: _assistantTotalJobs,
        reviewCount: _assistantReviewCount,
      );

  Map<String, dynamic> getWallet() {
    ensureSeeded();
    return {
      'balance': walletBalance,
      'transactions': List<Map<String, dynamic>>.from(_transactions),
    };
  }

  Map<String, dynamic> getReferrals() {
    ensureSeeded();
    return {
      'code': referralCode,
      'totalReferrals': totalReferrals,
      'totalEarned': totalEarned,
      'rewardPerReferral': 100,
      'referrals': [
        {
          'name': 'Rahul S.',
          'status': 'completed',
          'earned': 100,
          'date': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
        },
        {
          'name': 'Neha K.',
          'status': 'completed',
          'earned': 100,
          'date': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        },
      ],
    };
  }

  Map<String, dynamic> getEarnings() {
    ensureSeeded();
    return {
      'todayEarnings': 320,
      'weeklyEarnings': 1450,
      'totalEarnings': 5200,
      'todayJobs': 2,
      'totalJobs': 12,
      'history': [
        {
          'description': 'Bag Carry • P&M Mall',
          'amount': 39,
          'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        },
        {
          'description': 'Queue Help • Maurya Lok',
          'amount': 47,
          'createdAt': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        },
        {
          'description': 'Senior Help • City Centre',
          'amount': 63,
          'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
      ],
    };
  }

  List<Map<String, dynamic>> getNotifications() {
    ensureSeeded();
    return List<Map<String, dynamic>>.from(_notifications);
  }

  int get unreadNotificationCount =>
      getNotifications().where((n) => n['readAt'] == null).length;

  VerificationBundleModel getVerificationBundle(String userId) {
    ensureSeeded();
    final userDocs = _verificationDocs[userId] ?? {};
    final documents = _verificationTypeDefs.map((def) {
      final stored = userDocs[def.$1];
      if (stored == null) {
        return VerificationDocumentModel(
          type: VerificationDocType.fromApi(def.$1)!,
          label: def.$2,
          status: VerificationStatus.notSubmitted,
          canEdit: true,
        );
      }
      return VerificationDocumentModel.fromJson({
        'type': def.$1,
        'label': def.$2,
        ...stored,
        'canEdit': stored['status'] == 'rejected' || stored['status'] == 'not_submitted',
      });
    }).toList();

    final verifiedCount = documents.where((d) => d.isVerified).length;
    final pendingCount = documents.where((d) => d.isPending).length;
    final rejectedCount = documents.where((d) => d.isRejected).length;

    return VerificationBundleModel(
      documents: documents,
      summary: VerificationSummaryModel(
        totalRequired: documents.length,
        verifiedCount: verifiedCount,
        pendingCount: pendingCount,
        rejectedCount: rejectedCount,
        completionPercent: documents.isEmpty ? 0 : ((verifiedCount / documents.length) * 100).round(),
        fullyVerified: verifiedCount == documents.length,
      ),
    );
  }

  VerificationBundleModel submitVerificationDocument(
    String userId,
    String type, {
    String? fileUrl,
    String? textValue,
    Map<String, dynamic>? metadata,
  }) {
    ensureSeeded();
    _verificationDocs.putIfAbsent(userId, () => {});
    final existing = _verificationDocs[userId]![type];
    final status = existing?['status'] as String?;
    if (status == 'pending' || status == 'verified') {
      throw Exception('Document is locked while pending or after verification');
    }

    _verificationDocs[userId]![type] = {
      'status': 'pending',
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (textValue != null) 'textValue': textValue,
      if (metadata != null) 'metadata': metadata,
      'adminNote': null,
      'uploadedAt': DateTime.now().toIso8601String(),
      'verifiedAt': null,
    };
    _addNotification('Document submitted', 'Your $type is pending admin verification.');
    return getVerificationBundle(userId);
  }

  void _addNotification(String title, String body) {
    _notifications.insert(0, {
      'id': 'n-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'body': body,
      'readAt': null,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  BookingModel _copy(
    BookingModel b, {
    String? status,
    Map<String, dynamic>? assistant,
    List<StatusHistoryModel>? history,
    Map<String, dynamic>? payment,
    Map<String, dynamic>? rating,
    Map<String, dynamic>? appReview,
    String? serviceOtp,
    BookingSearchAvailability? searchAvailability,
    BookingTrackingModel? tracking,
    String? paymentConfirmOtp,
    double? assistantEarningAmount,
    double? companyShareAmount,
    bool clearPaymentOtp = false,
  }) {
    return BookingModel(
      id: b.id,
      status: status ?? b.status,
      durationMin: b.durationMin,
      venueName: b.venueName,
      scheduledAt: b.scheduledAt,
      addressFormatted: b.addressFormatted,
      lat: b.lat,
      lng: b.lng,
      serviceFee: b.serviceFee,
      platformFee: b.platformFee,
      totalAmount: b.totalAmount,
      serviceOtp: serviceOtp ?? b.serviceOtp,
      category: b.category,
      customer: b.customer,
      assistant: assistant ?? b.assistant,
      statusHistory: history ?? b.statusHistory,
      payment: payment ?? b.payment,
      rating: rating ?? b.rating,
      appReview: appReview ?? b.appReview,
      searchAvailability: searchAvailability ?? b.searchAvailability,
      tracking: tracking ?? b.tracking,
      paymentConfirmOtp: clearPaymentOtp ? null : (paymentConfirmOtp ?? b.paymentConfirmOtp),
      assistantEarningAmount: assistantEarningAmount ?? b.assistantEarningAmount,
      companyShareAmount: companyShareAmount ?? b.companyShareAmount,
    );
  }

  final List<Map<String, dynamic>> _addresses = [];
  final List<Map<String, dynamic>> _supportTickets = [];
  final Map<String, List<Map<String, dynamic>>> _chatMessages = {};

  List<AddressModel> getAddresses() {
    if (_addresses.isEmpty) {
      _addresses.addAll([
        {
          'id': 'addr-home',
          'label': 'Home',
          'formattedAddress': 'Fraser Road, Patna',
          'lat': 25.6093,
          'lng': 85.1376,
          'isDefault': true,
        },
      ]);
    }
    return _addresses.map((e) => AddressModel.fromJson(e)).toList();
  }

  AddressModel addAddress(String label, String formattedAddress, double lat, double lng, bool isDefault) {
    if (isDefault) {
      for (final a in _addresses) {
        a['isDefault'] = false;
      }
    }
    final a = {
      'id': 'addr-${DateTime.now().millisecondsSinceEpoch}',
      'label': label,
      'formattedAddress': formattedAddress,
      'lat': lat,
      'lng': lng,
      'isDefault': isDefault,
    };
    _addresses.add(a);
    return AddressModel.fromJson(a);
  }

  void deleteAddress(String id) => _addresses.removeWhere((a) => a['id'] == id);

  void setDefaultAddress(String id) {
    for (final a in _addresses) {
      a['isDefault'] = a['id'] == id;
    }
  }

  List<Map<String, dynamic>> getSupportTickets() => List.from(_supportTickets);

  Map<String, dynamic> createSupportTicket(String subject, String message) {
    final t = {
      'id': 't-${DateTime.now().millisecondsSinceEpoch}',
      'subject': subject,
      'message': message,
      'status': 'open',
      'adminReply': null,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _supportTickets.insert(0, t);
    return t;
  }

  List<Map<String, dynamic>> getChatMessages(String bookingId) =>
      List.from(_chatMessages[bookingId] ?? []);

  Map<String, dynamic> sendChatMessage(
    String bookingId,
    String message, {
    String? senderId,
    String? senderName,
  }) {
    final m = {
      'id': 'cm-${DateTime.now().millisecondsSinceEpoch}',
      'bookingId': bookingId,
      'senderId': senderId ?? 'dev-user',
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
      'sender': {
        'id': senderId ?? 'dev-user',
        'name': senderName ?? 'You',
      },
    };
    _chatMessages.putIfAbsent(bookingId, () => []).add(m);
    return m;
  }
}
