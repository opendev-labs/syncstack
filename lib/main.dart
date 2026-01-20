import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const GHSyncApp());
}

class GHSyncApp extends StatelessWidget {
  const GHSyncApp({super.key});

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
              home: Scaffold(
                backgroundColor: AppTheme.deepBlack,
                body: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.cyanAccent,
                  ),
                ),
              ),
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
