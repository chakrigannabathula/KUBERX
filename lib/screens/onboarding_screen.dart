import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../Home.dart';

class OnboardingScreen extends StatefulWidget {
  final String language;
  final String userEmail;
  final String userName;
  final String firebaseToken;

  const OnboardingScreen({
    super.key,
    required this.language,
    required this.userEmail,
    required this.userName,
    required this.firebaseToken,
  });

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
  }

  Map<String, Map<String, String>> translations = {
    'English': {
      'title': 'Complete Your Profile',
      'subtitle': 'We need a few more details to get started',
      'nameLabel': 'Full Name',
      'nameHint': 'Enter your full name',
      'usernameLabel': 'Username',
      'usernameHint': 'Choose a unique username',
      'dobLabel': 'Date of Birth',
      'dobHint': 'Select your date of birth',
      'continueButton': 'Continue',
      'completing': 'Setting up your profile...',
      'errorTitle': 'Profile Setup Error',
      'errorMessage': 'Failed to complete profile setup. Please try again.',
      'usernameError': 'Username must be 3-30 characters long and contain only letters, numbers, and underscores',
      'nameError': 'Please enter your full name',
      'dobError': 'Please select your date of birth',
      'ageError': 'You must be at least 13 years old to use this app',
      'usernameExists': 'Username already taken. Please choose another one.',
    },
    'Telugu': {
      'title': 'మీ ప్రొఫైల్ పూర్తి చేయండి',
      'subtitle': 'మేము ప్రారంభించడానికి కొన్ని మరిన్ని వివరాలు అవసరం',
      'nameLabel': 'పూర్తి పేరు',
      'nameHint': 'మీ పూర్తి పేరు నమోదు చేయండి',
      'usernameLabel': 'వినియోగదారు పేరు',
      'usernameHint': 'ఒక ప్రత్యేక వినియోగదారు పేరు ఎంచుకోండి',
      'dobLabel': 'పుట్టిన తేదీ',
      'dobHint': 'మీ పుట్టిన తేదీ ఎంచుకోండి',
      'continueButton': 'కొనసాగించు',
      'completing': 'మీ ప్రొఫైల్ సెటప్ చేస్తోంది...',
      'errorTitle': 'ప్రొఫైల్ సెటప్ లోపం',
      'errorMessage': 'ప్రొఫైల్ సెటప్ పూర్తి చేయడంలో విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      'usernameError': 'వినియోగదారు పేరు 3-30 అక్షరాలు మరియు అక్షరాలు, సంఖ్యలు మరియు అండర్‌స్కోర్‌లను మాత్రమే కలిగి ఉండాలి',
      'nameError': 'దయచేసి మీ పూర్తి పేరు నమోదు చేయండి',
      'dobError': 'దయచేసి మీ పుట్టిన తేదీ ఎంచుకోండి',
      'ageError': 'ఈ యాప్‌ని ఉపయోగించడానికి మీకు కనీసం 13 సంవత్సరాలు ఉండాలి',
      'usernameExists': 'వినియోగదారు పేరు ఇప్పటికే తీసుకోబడింది. దయచేసి మరొకటి ఎంచుకోండి.',
    }
  };

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
      lastDate: DateTime.now().subtract(const Duration(days: 4745)), // 13 years ago
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.lime,
              onPrimary: Colors.black,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return translations[widget.language]!['usernameError']!;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(value)) {
      return translations[widget.language]!['usernameError']!;
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return translations[widget.language]!['nameError']!;
    }
    return null;
  }

  bool _validateAge() {
    if (_selectedDate == null) return false;
    final age = DateTime.now().difference(_selectedDate!).inDays / 365.25;
    return age >= 13;
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      _showErrorDialog(translations[widget.language]!['dobError']!);
      return;
    }

    if (!_validateAge()) {
      _showErrorDialog(translations[widget.language]!['ageError']!);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.completeOnboarding(
        firebaseToken: widget.firebaseToken,
        username: _usernameController.text.trim(),
        dateOfBirth: _selectedDate!,
        name: _nameController.text.trim(),
      );

      // Successfully completed onboarding - update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_complete', true);
      await prefs.setString('custom_user_name', _nameController.text.trim());

      // Clear pending onboarding data
      await prefs.remove('pending_user_email');
      await prefs.remove('pending_user_name');

      // Force a navigation to home screen by popping back to root and letting AuthWrapper handle it
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => InvestmentsScreen()),
          (route) => false,
        );
      }

    } catch (e) {
      String errorMessage = translations[widget.language]!['errorMessage']!;

      // Handle specific error cases
      if (e.toString().contains('Username already taken')) {
        errorMessage = translations[widget.language]!['usernameExists']!;
      }

      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translations[widget.language]!['errorTitle']!),
          content: Text(message),
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
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  translations[widget.language]!['title']!,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  translations[widget.language]!['subtitle']!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),

                // Form fields
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name Field
                        TextFormField(
                          controller: _nameController,
                          validator: _validateName,
                          decoration: InputDecoration(
                            labelText: translations[widget.language]!['nameLabel']!,
                            hintText: translations[widget.language]!['nameHint']!,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.lime),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Username Field
                        TextFormField(
                          controller: _usernameController,
                          validator: _validateUsername,
                          decoration: InputDecoration(
                            labelText: translations[widget.language]!['usernameLabel']!,
                            hintText: translations[widget.language]!['usernameHint']!,
                            prefixText: '@',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.lime),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Date of Birth Field
                        GestureDetector(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: translations[widget.language]!['dobLabel']!,
                                hintText: _selectedDate == null
                                    ? translations[widget.language]!['dobHint']!
                                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                suffixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.lime),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lime,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SpinKitCircle(
                                color: Colors.black,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                translations[widget.language]!['completing']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            translations[widget.language]!['continueButton']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
