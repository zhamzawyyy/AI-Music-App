import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/theme.dart';
import 'app/router.dart';
import 'shared/services/token_storage.dart';
import 'shared/services/api_client.dart';

/// Point this at your backend. Use 10.0.2.2 for the Android emulator to
/// reach a backend running on your host machine's localhost.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

void main() {
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(baseUrl: kApiBaseUrl, tokenStorage: tokenStorage);

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: apiClient),
      ],
      child: MyApp(tokenStorage: tokenStorage),
    ),
  );
}

class MyApp extends StatelessWidget {
  final TokenStorage tokenStorage;
  const MyApp({super.key, required this.tokenStorage});

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(tokenStorage);
    return MaterialApp.router(
      title: 'AI Music App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
