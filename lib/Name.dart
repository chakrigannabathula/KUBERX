import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Dateofbirth.dart';
import 'services/api_service.dart';

class NameEntryScreen extends StatefulWidget {
  final String? language;
  final String? userEmail;

  const NameEntryScreen({
    super.key,
    this.language = 'English',
    this.userEmail,
  });

  @override
  _NameEntryScreenState createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  void _proceedToNextStep() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Store custom name locally (this is the most important part)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_user_name', _nameController.text.trim());

      // Try to update user profile with API, but don't fail if it doesn't work
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.updateUserProfile({
          'name': _nameController.text.trim(),
          'language': widget.language ?? 'English',
        });
        print('Profile updated successfully via API');
      } catch (apiError) {
        print('API update failed, continuing with local storage: $apiError');
        // Continue anyway since we have local storage
      }

      // Navigate to date of birth screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DateOfBirthScreen(
            userName: _nameController.text.trim(),
            language: widget.language ?? 'English',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save name. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Step 1/2", style: TextStyle(fontSize: 14)),
                  Icon(Icons.help_outline),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 5,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "What We should call you?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: "Username",
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16),
                  enabled: !_isLoading,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _proceedToNextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Next",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
