import 'package:flutter/material.dart';
import 'Home.dart';

class KuberXApp extends StatelessWidget {
  const KuberXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

  // Language translations
  Map<String, Map<String, String>> translations = {
    'English': {
      'title': 'KuberX',
      'continueWithGoogle': 'Continue with Google',
    },
    'Telugu': {
      'title': 'కుబర్X',
      'continueWithGoogle': 'గూగుల్‌తో కొనసాగించండి',
    }
  };

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSigningIn = true;
    });

    // Simulate sign-in process for now
    await Future.delayed(Duration(seconds: 2));

    // Navigate to name entry screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NameEntryScreen()),
    );

    setState(() {
      _isSigningIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Spacer(),
            Center(
              child: Text(
                translations[selectedLanguage]!['title']!,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LanguageButton(
                  language: 'English',
                  isSelected: selectedLanguage == 'English',
                  onTap: () {
                    setState(() {
                      selectedLanguage = 'English';
                    });
                  },
                ),
                SizedBox(width: 10),
                LanguageButton(
                  language: 'Telugu',
                  isSelected: selectedLanguage == 'Telugu',
                  onTap: () {
                    setState(() {
                      selectedLanguage = 'Telugu';
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFDFFFB3), // light green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSigningIn
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                        )
                      : Text(
                          translations[selectedLanguage]!['continueWithGoogle']!,
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class LanguageButton extends StatelessWidget {
  final String language;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageButton({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFDFFFB3) : Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          language,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
