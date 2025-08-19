import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Home.dart';
import 'screens/onboarding_screen.dart';

class KuberXApp extends StatelessWidget {
  const KuberXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: KuberXWelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class KuberXWelcomeScreen extends StatefulWidget {
  const KuberXWelcomeScreen({super.key});

  @override
  _KuberXWelcomeScreenState createState() => _KuberXWelcomeScreenState();
}

class _KuberXWelcomeScreenState extends State<KuberXWelcomeScreen> {
  String selectedLanguage = 'English';
  bool _isSigningIn = false;
  final AuthService _authService = AuthService();

  Map<String, Map<String, String>> translations = {
    'English': {
      'title': 'KuberX',
      'continueWithGoogle': 'Continue with Google',
      'signingIn': 'Signing in...',
      'checkingProfile': 'Checking profile...',
      'errorTitle': 'Sign In Error',
      'errorMessage': 'Failed to sign in. Please try again.',
    },
    'Telugu': {
      'title': 'కుబర్X',
      'continueWithGoogle': 'గూగుల్‌తో కొనసాగించండి',
      'signingIn': 'సైన్ ఇన్ అవుతోంది...',
      'checkingProfile': 'ప్రొఫైల్ తనిఖీ చేస్తోంది...',
      'errorTitle': 'సైన్ ఇన్ లోపం',
      'errorMessage': 'సైన్ ఇన్ చేయడంలో విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
    }
  };

  Future<void> _handleGoogleSignIn() async {
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    try {
      // Use the new authentication method that calls the correct backend endpoint
      final authResponse = await _authService.authenticateWithGoogle();

      // Authentication successful! The JWT token is already stored securely
      print('Authentication successful: ${authResponse.user.name}');

      // Force immediate navigation based on profile completion status
      if (mounted) {
        if (authResponse.user.isProfileCompleted) {
          // User profile is complete - navigate directly to home
          print('Profile complete, navigating to home');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => InvestmentsScreen()),
            (route) => false,
          );
        } else {
          // User needs onboarding - navigate to onboarding screen
          print('Profile incomplete, navigating to onboarding');
          final firebaseToken = await _authService.getFirebaseToken();
          if (firebaseToken != null) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => OnboardingScreen(
                  language: selectedLanguage,
                  userEmail: authResponse.user.email,
                  userName: authResponse.user.name,
                  firebaseToken: firebaseToken,
                ),
              ),
              (route) => false,
            );
          }
        }
      }

    } catch (e) {
      print('Authentication failed: $e');
      _showErrorDialog();
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translations[selectedLanguage]!['errorTitle']!),
          content: Text(translations[selectedLanguage]!['errorMessage']!),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Centered App Title
            Center(
              child: Text(
                translations[selectedLanguage]!['title']!,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Bottom Section: Language selector + Google Sign In
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30.0, left: 20, right: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Language Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['English', 'Telugu'].map((lang) {
                        final isSelected = selectedLanguage == lang;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedLanguage = lang;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.lime[100] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                lang,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.grey, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSigningIn
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SpinKitCircle(
                                    color: Colors.lime,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    translations[selectedLanguage]!['signingIn']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/google_logo.png',
                                    height: 24,
                                    width: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    translations[selectedLanguage]!['continueWithGoogle']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
