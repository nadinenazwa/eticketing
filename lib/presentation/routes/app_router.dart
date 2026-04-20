import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/ticket_list_screen.dart';
import '../screens/ticket_detail_screen.dart';
import '../screens/create_ticket_screen.dart';
import '../screens/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Halaman tidak ditemukan: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/splash'),
              child: const Text('Kembali ke Home'),
            ),
          ],
        ),
      ),
    ),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoading = authState.isLoading;
      if (isLoading) return '/splash';

      final isLoggedIn = authState.value != null;
      final loc = state.matchedLocation;

      final publicRoutes = ['/splash', '/login', '/register', '/reset-password'];
      final isPublicRoute = publicRoutes.contains(loc);

      if (!isLoggedIn && !isPublicRoute) return '/login';
      if (isLoggedIn && (loc == '/login' || loc == '/register')) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/tickets',
        builder: (context, state) => const TicketListScreen(),
      ),
      GoRoute(
        path: '/tickets/create',
        builder: (context, state) => const CreateTicketScreen(),
      ),
      GoRoute(
        path: '/tickets/:id',
        builder: (context, state) =>
            TicketDetailScreen(ticketId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});