import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/reset_password_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/ticket_list_screen.dart';
import 'presentation/screens/ticket_detail_screen.dart';
import 'presentation/screens/create_ticket_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash',    builder: (ctx, _) => const SplashScreen()),
      GoRoute(path: '/login',     builder: (ctx, _) => const LoginScreen()),
      GoRoute(path: '/register',  builder: (ctx, _) => const RegisterScreen()),
      GoRoute(path: '/reset-password', builder: (ctx, _) => const ResetPasswordScreen()),
      GoRoute(path: '/dashboard', builder: (ctx, _) => const DashboardScreen()),
      GoRoute(path: '/tickets',   builder: (ctx, _) => const TicketListScreen()),
      GoRoute(path: '/tickets/create', builder: (ctx, _) => const CreateTicketScreen()),
      GoRoute(
        path: '/tickets/:id',
        builder: (ctx, state) => TicketDetailScreen(ticketId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/profile',        builder: (ctx, _) => const ProfileScreen()),
    ],
  );
});

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'E-Ticketing Helpdesk',
      debugShowCheckedModeBanner: false,
      theme:  AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
