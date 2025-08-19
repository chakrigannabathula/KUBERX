import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'Login.dart';
import 'Home.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService()..initialize(),
        ),
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
      ],
      child: MaterialApp(
        title: 'KuberX',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return FutureBuilder<bool>(
      future: authService.isLoggedIn(),
      builder: (context, loginSnapshot) {
        if (loginSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (loginSnapshot.data == true) {
          // User has valid JWT token, get their profile data from backend
          return FutureBuilder<UserData?>(
            future: authService.getCurrentUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final userData = userSnapshot.data;
              if (userData != null) {
                if (userData.isProfileCompleted) {
                  // Profile is complete - go directly to home
                  print('Returning user with complete profile, going to home');
                  return InvestmentsScreen();
                } else {
                  // Profile incomplete - go to onboarding
                  print('Returning user needs onboarding');
                  return FutureBuilder<String?>(
                    future: authService.getFirebaseToken(),
                    builder: (context, tokenSnapshot) {
                      if (tokenSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final firebaseToken = tokenSnapshot.data;
                      if (firebaseToken != null) {
                        return OnboardingScreen(
                          language: 'English',
                          userEmail: userData.email,
                          userName: userData.name,
                          firebaseToken: firebaseToken,
                        );
                      } else {
                        // No Firebase token, go to login
                        return const KuberXApp();
                      }
                    },
                  );
                }
              } else {
                // No user data available, go to login
                return const KuberXApp();
              }
            },
          );
        }

        // User not logged in, show login
        return const KuberXApp();
      },
    );
  }
}
