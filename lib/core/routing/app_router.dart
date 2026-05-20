import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/create_pin_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/login_pin_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/performance_screen.dart';
import '../../features/notes/presentation/notes_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/stocks/presentation/stocks_screen.dart';
import '../../features/transactions/domain/transaction_type.dart';
import '../../features/transactions/presentation/confirmation_screen.dart';
import '../../features/transactions/presentation/history_screen.dart';
import '../../features/transactions/presentation/mode_rapide_screen.dart';
import '../../features/transactions/presentation/transaction_entry_screen.dart';
import '../../features/transactions/presentation/ticket_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final rawPath = state.uri.path;
      if (rawPath.startsWith('//')) {
        return rawPath.replaceFirst(RegExp(r'^/+'), '/');
      }

      final auth = ref.watch(authControllerProvider);
      final location = state.matchedLocation;
      final publicRoutes = {
        '/',
        '/welcome',
        '/register',
        '/identify',
        '/login',
        '/login-pin',
        '/forgot-pin',
        '/create-pin',
      };

      if (!auth.isLoggedIn && !publicRoutes.contains(location)) {
        return auth.hasUser ? '/login' : '/welcome';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
          path: '/create-pin',
          builder: (context, state) => const CreatePinScreen()),
      GoRoute(
          path: '/identify',
          builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/login-pin',
          builder: (context, state) => const LoginPinScreen()),
      GoRoute(
          path: '/forgot-pin',
          builder: (context, state) => const _ForgotPinScreen()),
      GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen()),
      GoRoute(
          path: '/mode-rapide',
          builder: (context, state) => const ModeRapideScreen()),
      GoRoute(
        path: '/saisie-vente',
        builder: (context, state) => const TransactionEntryScreen(
          type: TransactionType.sale,
        ),
      ),
      GoRoute(
        path: '/saisie-depense',
        builder: (context, state) => const TransactionEntryScreen(
          type: TransactionType.expense,
        ),
      ),
      GoRoute(
        path: '/confirmation',
        builder: (context, state) => const ConfirmationScreen(),
      ),
      GoRoute(
          path: '/historique',
          builder: (context, state) => const HistoryScreen()),
      GoRoute(
          path: '/performance',
          builder: (context, state) => const PerformanceScreen()),
      GoRoute(
          path: '/stocks', builder: (context, state) => const StocksScreen()),
      GoRoute(
          path: '/profil', builder: (context, state) => const ProfileScreen()),
      GoRoute(
          path: '/carnet', builder: (context, state) => const NotesScreen()),
      GoRoute(
          path: '/ticket', builder: (context, state) => const TicketScreen()),
    ],
  );
});

class _ForgotPinScreen extends StatelessWidget {
  const _ForgotPinScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PIN oublié')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.sms_outlined, size: 72),
            const SizedBox(height: 18),
            const Text(
              'La récupération par SMS n\'est pas encore active.\n\n'
              'Tu peux revenir à la connexion ou retrouver ton PIN plus tard depuis le profil.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/identify'),
              child: const Text('Retour à la connexion'),
            ),
          ],
        ),
      ),
    );
  }
}
