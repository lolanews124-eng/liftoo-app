import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import '../realtime/socket_service.dart';
import '../storage/token_storage.dart';
import '../storage/referral_storage.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/assistant/data/assistant_verification_repository.dart';
import '../../features/booking/data/booking_repository.dart';
import '../../features/reviews/data/reviews_repository.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../../features/customer/addresses/addresses_repository.dart';
import '../../features/support/data/support_repository.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/promos/data/promos_repository.dart';
import '../../features/payouts/data/payouts_repository.dart';

final tokenStorageProvider = Provider((ref) => TokenStorage());

final referralStorageProvider = Provider((ref) => ReferralStorage());

final connectivityServiceProvider = Provider((ref) => ConnectivityService());

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onlineStream;
});

final apiClientProvider = Provider((ref) {
  return ApiClient(
    ref.watch(tokenStorageProvider),
    ref.watch(connectivityServiceProvider),
  );
});

final socketServiceProvider = Provider((ref) => SocketService());

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(socketServiceProvider),
  );
});

final bookingRepositoryProvider = Provider((ref) {
  return BookingRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final walletRepositoryProvider = Provider((ref) {
  return WalletRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final reviewsRepositoryProvider = Provider((ref) {
  return ReviewsRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final assistantVerificationRepositoryProvider = Provider((ref) {
  return AssistantVerificationRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final addressesRepositoryProvider = Provider((ref) {
  return AddressesRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider));
});

final supportRepositoryProvider = Provider((ref) {
  return SupportRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider));
});

final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider));
});

final promosRepositoryProvider = Provider((ref) {
  return PromosRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider));
});

final payoutsRepositoryProvider = Provider((ref) {
  return PayoutsRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider));
});
