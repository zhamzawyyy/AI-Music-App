import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/library/library_screen.dart';
import '../features/generation/generation_screen.dart';
import '../features/recognition/recognition_screen.dart';
import '../shared/services/token_storage.dart';

GoRouter buildRouter(TokenStorage tokenStorage) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final loggedIn = await tokenStorage.isLoggedIn();
      final onAuthScreen = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!loggedIn && !onAuthScreen) return '/login';
      if (loggedIn && onAuthScreen) return '/library';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/library', builder: (context, state) => const LibraryScreen()),
      GoRoute(path: '/generate', builder: (context, state) => const GenerationScreen()),
      GoRoute(path: '/identify', builder: (context, state) => const RecognitionScreen()),
    ],
  );
}
