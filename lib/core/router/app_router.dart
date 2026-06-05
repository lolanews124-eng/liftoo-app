import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'initial_route.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/setup_profile_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/otp_login_args.dart';
import '../../features/auth/presentation/setup_profile_args.dart';
import '../../features/role_selection/role_selection_screen.dart';
import '../../features/customer/home/customer_home_screen.dart';
import '../../features/customer/home/quick_book_draft.dart';
import '../../features/customer/home/service_search_screen.dart';
import '../../features/customer/booking/booking_wizard_screen.dart';
import '../../features/customer/booking/live_booking_screen.dart';
import '../../features/customer/bookings/my_bookings_screen.dart';
import '../../features/customer/profile/customer_profile_screen.dart';
import '../../features/customer/profile/edit_profile_screen.dart';
import '../../features/customer/wallet/wallet_add_money_screen.dart';
import '../../features/customer/wallet/wallet_screen.dart';
import '../../features/customer/referral/referral_screen.dart';
import '../../features/customer/payment/payment_screen.dart';
import '../../features/customer/rating/rating_screen.dart';
import '../../features/customer/rating/app_review_screen.dart';
import '../../features/assistant/dashboard/assistant_dashboard_screen.dart';
import '../../features/assistant/jobs/assistant_jobs_screen.dart';
import '../../features/assistant/requests/requests_screen.dart';
import '../../features/assistant/active_job/active_job_screen.dart';
import '../../features/assistant/earnings/earnings_screen.dart';
import '../../features/assistant/profile/assistant_profile_screen.dart';
import '../../features/assistant/profile/assistant_verification_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/customer/addresses/addresses_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/legal/legal_policies_screen.dart';
import 'page_transitions.dart';
import 'root_navigator.dart';
import 'shell_scaffold.dart';

/// Rebuild GoRouter only when login/role changes — not on wallet balance updates.
String _authRouteKey(AuthState auth) =>
    '${auth.user?.id}|${auth.user?.activeRole}|${auth.user?.profileComplete}';

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authProvider.select(_authRouteKey));
  final authState = ref.read(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: resolveInitialLocation(authState),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final user = authState.user;

      if (loc.startsWith('/review/')) return null;

      final isAuth = loc.startsWith('/auth');
      final isPreAuthFlow = loc == '/auth/otp' ||
          loc == '/auth/forgot-password' ||
          loc.startsWith('/auth/reset-password');

      if (user == null && !isAuth) return '/auth/login';

      if (user != null && !user.profileComplete && loc != '/auth/setup-profile') {
        return '/auth/setup-profile';
      }

      if (user != null && isAuth && loc != '/auth/setup-profile' && !isPreAuthFlow) {
        if (user.activeRole == null) return '/role-selection';
        return user.activeRole == 'assistant' ? '/assistant' : '/customer';
      }
      if (user != null &&
          user.profileComplete &&
          user.activeRole == null &&
          !isAuth &&
          loc != '/role-selection') {
        return '/role-selection';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/login',
        pageBuilder: (_, state) => appSlidePage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/auth/otp',
        pageBuilder: (_, state) => appSlidePage(
          key: state.pageKey,
          child: OtpScreen(args: state.extra as OtpLoginArgs?),
        ),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        pageBuilder: (_, state) => appSlidePage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/reset-password',
        pageBuilder: (_, state) => appSlidePage(
          key: state.pageKey,
          child: ResetPasswordScreen(email: state.extra as String),
        ),
      ),
      GoRoute(
        path: '/auth/setup-profile',
        pageBuilder: (_, state) => appSlidePage(
          key: state.pageKey,
          child: SetupProfileScreen(
            args: state.extra as SetupProfileArgs? ?? const SetupProfileArgs(),
          ),
        ),
      ),
      GoRoute(
        path: '/role-selection',
        pageBuilder: (_, state) => appSlidePage(key: state.pageKey, child: const RoleSelectionScreen()),
      ),
      GoRoute(
        path: '/customer/search',
        pageBuilder: (_, state) => appSlidePage(key: state.pageKey, child: const ServiceSearchScreen()),
      ),
      GoRoute(
        path: '/customer/booking',
        pageBuilder: (_, state) => appSlidePage(
          key: state.pageKey,
          child: BookingWizardScreen(draft: state.extra as QuickBookDraft?),
        ),
      ),
      GoRoute(
        path: '/customer/booking/:id',
        pageBuilder: (_, state) => appSlidePage(
          key: state.pageKey,
          child: LiveBookingScreen(bookingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/customer/payment/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, state) => appSlidePage(
          key: state.pageKey,
          child: PaymentScreen(bookingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/review/service/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, state) => appSlidePage(
          key: state.pageKey,
          child: RatingScreen(bookingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/review/app/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, state) => appSlidePage(
          key: state.pageKey,
          child: AppReviewScreen(bookingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/referral',
        pageBuilder: (_, state) => appFadePage(key: state.pageKey, child: const ReferralScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (_, state) => appSlidePage(key: state.pageKey, child: const NotificationsScreen()),
      ),
      GoRoute(
        path: '/support',
        pageBuilder: (_, state) => appSlidePage(key: state.pageKey, child: const SupportScreen()),
      ),
      GoRoute(
        path: '/legal',
        pageBuilder: (_, state) => appSlidePage(key: state.pageKey, child: const LegalPoliciesScreen()),
      ),
      GoRoute(
        path: '/customer/addresses',
        pageBuilder: (_, state) => appSlidePage(key: state.pageKey, child: const AddressesScreen()),
      ),
      GoRoute(
        path: '/customer/profile/edit',
        pageBuilder: (_, state) => appSlidePage(key: state.pageKey, child: const EditProfileScreen()),
      ),
      GoRoute(
        path: '/customer/wallet/add',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, state) {
          final balance = (state.extra as num?)?.toDouble() ?? 0;
          return appSlidePage(
            key: state.pageKey,
            child: WalletAddMoneyScreen(currentBalance: balance),
          );
        },
      ),
      GoRoute(
        path: '/chat/:bookingId',
        pageBuilder: (_, state) => appSlidePage(
          key: state.pageKey,
          child: ChatScreen(bookingId: state.pathParameters['bookingId']!),
        ),
      ),
      GoRoute(
        path: '/assistant/active/:id',
        pageBuilder: (_, state) => appSlidePage(
          key: state.pageKey,
          child: ActiveJobScreen(bookingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/assistant/nearby-requests',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, state) => appSlidePage(key: state.pageKey, child: const RequestsScreen()),
      ),
      GoRoute(
        path: '/assistant/verification',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, state) => appSlidePage(
          key: state.pageKey,
          child: const AssistantVerificationScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final user = ref.read(authProvider).user;
          final isAssistant = user?.activeRole == 'assistant';
          return ShellScaffold(
            navigationShell: navigationShell,
            isAssistant: isAssistant,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer',
                builder: (_, __) => const CustomerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/bookings',
                builder: (_, __) => const MyBookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/wallet',
                builder: (_, __) => const WalletScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/profile',
                builder: (_, __) => const CustomerProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assistant',
                builder: (_, __) => const AssistantDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assistant/requests',
                builder: (_, __) => const AssistantJobsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assistant/earnings',
                builder: (_, __) => const EarningsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assistant/profile',
                builder: (_, __) => const AssistantProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
