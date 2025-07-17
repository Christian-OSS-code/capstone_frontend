import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UserLoginPage extends StatefulWidget {
  const UserLoginPage({super.key});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final GlobalKey<FormState> _loginKey = GlobalKey();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final RegExp _validEmail = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  bool isArtisan = false;
  bool _isUserCredentialsLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _handleDummyLoginApi(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 2));

    if (email == 'christianmary2020@gmail.com' && password == 'password12345') {
      return {
        'userId': 'id_001',
        'auth_token': 'jwt_020',
        'profileCompleted': false,
        'isArtisan': false,
      };
    } else if (email == 'as@example.com' && password == 'asexample123') {
      return {
        'userId': 'driv_002',
        'auth_token': 'jwt_909',
        'profileCompleted': true,
        'isArtisan': false,
      };
    } else if (email == 'div@example.com' && password == 'password1010') {
      return {
        'userId': 'div_023',
        'auth_token': 'div_mok_12',
        'profileCompleted': true,
        'isArtisan': false,
      };
    } else {
      throw Exception("Invalid credentials");
    }
  }

  Future<void> _handleUserLogin() async {
    if (!_loginKey.currentState!.validate()) {
      return;
    }
    if (mounted) {
      setState(() {
        _isUserCredentialsLoading = true;
      });
    }
    try {
      final String email = _emailController.text;
      final String password = _passwordController.text;
      final Map<String, dynamic> loginResponse = await _handleDummyLoginApi(
        email,
        password,
      );

      final String userId = loginResponse['userId'];
      final String authToken = loginResponse['auth_token'];
      final bool profileCompleted = loginResponse['profileCompleted'];
      final bool isArtisanFromBackend = loginResponse['isArtisan'];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Successful! Redirecting...")),
        );
        await Future.delayed(const Duration(milliseconds: 500));

        if (!profileCompleted) {
          Navigator.pushReplacementNamed(
            context,
            '/user_profile',
            arguments: {'userId': userId, 'authToken': authToken},
          );
        } else {
          if (isArtisanFromBackend) {
            Navigator.pushReplacementNamed(context, '/artisans_dashboard');
          } else {
            Navigator.pushReplacementNamed(
              context,
              '/mechanic_service_request',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login was not successful"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUserCredentialsLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: Text("Login"), elevation: 0),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14.0),
          child: Form(
            key: _loginKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const FaIcon(
                  FontAwesomeIcons.userCircle,
                  color: Colors.blueAccent,
                  size: 60,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: "Enter your email",
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.email, color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Email cannot be empty";
                        } else if (!_validEmail.hasMatch(value)) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: "Enter your password",
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.lock, color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Password cannot be empty";
                        } else if (value.length < 8) {
                          return "Password must be at least 8 characters of length";
                        }
                        return null;
                      },
                    ),
                  ),
                ),

                
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                
                ),
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  // const SizedBox(height: 15)
                  child: ElevatedButton(
                    onPressed: _isUserCredentialsLoading
                        ? null
                        : _handleUserLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),

                    child: _isUserCredentialsLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup_page');
                  },
                  child: const Text(
                    "Don't have an account? Sign Up",
                    style: TextStyle(color: Colors.blueAccent),
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
