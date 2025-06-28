import 'package:flutter/material.dart';
import 'Bitcoinpage.dart';

class DateOfBirthScreen extends StatefulWidget {
  const DateOfBirthScreen({super.key});

  @override
  _DateOfBirthScreenState createState() => _DateOfBirthScreenState();
}

class _DateOfBirthScreenState extends State<DateOfBirthScreen> {
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDate;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Step 2/2",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: 1.0,
                backgroundColor: Colors.black12,
                color: Colors.black,
              ),
              SizedBox(height: 40),
              Text(
                "Enter your date of birth",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "You must be at least 18 years old",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF4F7F6),
                    borderRadius: BorderRadius.circular(8),
                    border: _errorMessage != null
                        ? Border.all(color: Colors.red, width: 1)
                        : null,
                  ),
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}"
                              : "Select your date of birth",
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
              Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedDate != null && _errorMessage == null
                        ? Color(0xFFDFF59D)
                        : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _selectedDate != null && _errorMessage == null
                      ? _handleNext
                      : null,
                  child: Text(
                    "Next",
                    style: TextStyle(
                      color: _selectedDate != null && _errorMessage == null
                          ? Colors.black
                          : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final DateTime hundredYearsAgo = DateTime(now.year - 100, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: eighteenYearsAgo,
      firstDate: hundredYearsAgo,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _validateAge();
      });
    }
  }

  void _validateAge() {
    if (_selectedDate == null) return;

    final DateTime now = DateTime.now();
    final DateTime eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);

    if (_selectedDate!.isAfter(eighteenYearsAgo)) {
      setState(() {
        _errorMessage = "You must be at least 18 years old to continue.";
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _handleNext() {
    if (_selectedDate != null && _errorMessage == null) {
      // Navigate to InvestmentsScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvestmentsScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    super.dispose();
  }
}
