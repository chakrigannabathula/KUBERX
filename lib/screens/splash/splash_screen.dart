import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(), // Empty space on top
              const Center(
                child: Text(
                  'KuberX',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('English'),
                        selected: selectedLanguage == 'English',
                        selectedColor: Colors.lightGreen[200],
                        onSelected: (_) {
                          setState(() => selectedLanguage = 'English');
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Telugu'),
                        selected: selectedLanguage == 'Telugu',
                        selectedColor: Colors.lightGreen[200],
                        onSelected: (_) {
                          setState(() => selectedLanguage = 'Telugu');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected: $selectedLanguage'),
                          ),
                        );
                        // Later: Navigate to onboarding
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen[200],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue with Google',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
