import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _userSignUpKey = GlobalKey();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _password1Controller = TextEditingController();
  final TextEditingController _password2Controller = TextEditingController();

  final RegExp _validEmail = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final RegExp _validPhoneNumber = RegExp(r'^\+?[1-9]\d{5,14}$');

  bool _isUserArtisan = false;
  bool _isUserDataLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _password1Controller.dispose();
    _password2Controller.dispose();
    super.dispose();
  }

  Future<void> _handleUserSignUp() async {
    if (!(_userSignUpKey.currentState?.validate() ?? false)) {
      return;
    }

    String password1 = _password1Controller.text.trim();
    String password2 = _password2Controller.text.trim();
    if (password1 != password2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password does not match.Try again")),
      );
      return;
    }
    setState(() {
      _isUserDataLoading = true;
    });
    try {
      final String firstName = _firstNameController.text.trim();
      final String lastName = _lastNameController.text.trim();
      final String emailAddress = _emailController.text.trim();
      final String phoneNumber = _phoneNumberController.text.trim();
      final String password1 = _password1Controller.text.trim();
      final String password2 = _password2Controller.text.trim();

      final Map<String, dynamic> signUpRequestBody = {
        'first_name': firstName,
        'last_name': lastName,
        'email': emailAddress,
        'phone_number': phoneNumber,
        'password1': password1,
        'password2': password2,
        'is_artisan': _isUserArtisan,
      };
      final String signUpRequestUrl =
          'http://16.171.145.59:8000/api/accounts/auth/register/';
      debugPrint("Request Body: $signUpRequestBody");
      debugPrint("Request Body: $signUpRequestBody");

      final signUpResponse = await http.post(
        Uri.parse(signUpRequestUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(signUpRequestBody),
      );
      debugPrint("Response Status Code: ${signUpResponse.statusCode}");
      debugPrint("Response: ${signUpResponse.body}");

      if (signUpResponse.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration successful! Please login."),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/user_login_page');
        }
      } else {
        Map<String, dynamic> errorUserData = {};
        String errorSignUpMessage = "Registration failed. Please, try again";
        try {
          if (signUpResponse.body.isNotEmpty) {
            errorUserData = jsonDecode(signUpResponse.body);
          }
          if (errorUserData.containsKey('phone_number') &&
              errorUserData['phone_number'] is List) {
            errorSignUpMessage =
                'phone_number: ${errorUserData['phone_number'][0]}';
          } else if (errorUserData.containsKey('email') &&
              errorUserData['email'] is List) {
            errorSignUpMessage = "Email: ${errorUserData['email'][0]}";
          } else if (errorUserData.containsKey('password') &&
              errorUserData['password'] is List) {
            errorSignUpMessage = "password: ${errorUserData['password'][0]}";
          } else if (errorUserData.containsKey('non_field_errors') &&
              errorUserData['non_field_errors'] is List) {
            errorSignUpMessage = errorUserData['non_field_errors'][0];
          } else if (errorUserData.containsKey('detail')) {
            errorSignUpMessage = errorUserData['detail'];
          } else if (errorUserData.isNotEmpty) {
            errorSignUpMessage = errorUserData.values.first.toString();
          } else {
            errorSignUpMessage =
                "Server error (Status: ${signUpResponse.statusCode})";
          }
        } on FormatException {
          debugPrint("Format exception error");
        } catch (e) {
          debugPrint("Error processing response");
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error message"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred:}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUserDataLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Sign Up Page"),
        elevation: 0,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22.0),
          child: Form(
            key: _userSignUpKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const FaIcon(
                  FontAwesomeIcons.userPlus,
                  color: Colors.grey,
                  size: 40,
                ),
                const SizedBox(height: 30),
                const Text(
                  "Create Your Account",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person, color: Colors.grey),
                        hintText: "Christian",
                        labelText: "First Name",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "First name cannot be empty";
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person, color: Colors.grey),
                        hintText: "Ikwu",
                        labelText: "Last Name",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "First name cannot be empty";
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person, color: Colors.grey),
                        hintText: "chris@example.com",
                        labelText: "Email Address",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Email cannot be empty";
                        } else if (!_validEmail.hasMatch(value)) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person, color: Colors.grey),
                        hintText: "+2348135417002",
                        labelText: "PhoneNumber",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Phone number cannot be empty";
                        }
                        final correctDigitsValue = value.replaceAll(
                          RegExp(r'(?!^\+)[^\d]'),
                          '',
                        );
                        if (!_validPhoneNumber.hasMatch(correctDigitsValue)) {
                          return "Enter a valid phone number (e.g., +234...)";
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextFormField(
                      controller: _password1Controller,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person, color: Colors.grey),
                        labelText: "Password",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "password cannot be empty";
                        } else if (value.length < 8) {
                          return "Password must be at least 8 characters";
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextFormField(
                      controller: _password2Controller,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person, color: Colors.grey),
                        labelText: "Confirm Password",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "password cannot be empty";
                        } else if (value.length < 8) {
                          return "Confirm password must be at least 8 characters";
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Register as an Artisan?",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: _isUserArtisan,
                      onChanged: (bool value) {
                        setState(() {
                          _isUserArtisan = value;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? "You're registering as an Artisan"
                                  : "You're registering as a regular user",
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      activeColor: Colors.green.shade400,
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: Colors.grey.shade200,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.orangeAccent, Colors.orange.shade600],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isUserDataLoading ? null : _handleUserSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: _isUserDataLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/user_login_page');
                  },
                  child: Text(
                    "Already have an account? Login",
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
