import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naturaai/features/scenes/forest/view/sound_forest_page.dart';
import '../features/splash/view/splash_page.dart';
import '../features/home/view/home_page.dart';
import '../features/auth/view/login_page.dart';
import '../features/auth/view/signup_page.dart';
import '../shared/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      GoRoute(
        path: '/forest',
        builder: (context, state) => const SoundForestPage(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider);
      final location = state.uri.toString();
      final isOnAuthPage = location == '/login' || location == '/signup';

      if (!isLoggedIn && location == '/home') {
        return '/login';
      }

      if (isLoggedIn && isOnAuthPage) {
        return '/home';
      }

      return null;
    },
  );
});
