import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'widgets/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SyncStackApp());
}

class SyncStackApp extends StatelessWidget {
  const SyncStackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<SyncProvider>(create: (_) => SyncProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isInitialized) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: LoadingScreen(),
            );
          }
          
          return MaterialApp(
            title: 'SyncStack Desktop',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: auth.isLoggedIn ? const DashboardScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
