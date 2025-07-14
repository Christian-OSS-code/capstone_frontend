import 'package:flutter/material.dart';
import 'package:flutter_login_app/pages/signup_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_login_app/pages/emergency_login_page.dart';
import 'package:flutter_login_app/pages/my_home_page.dart';
import 'package:flutter_login_app/pages/user_login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roadside Assistance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(76, 175, 80, 1),
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          elevation: 4,
          backgroundColor: Colors.blue,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      routes: {
        '/': (context) => const MyHomePage(),
        '/emergency_login_page': (context) => const EmergencyLoginPage(),
        '/signup_page': (context) => const SignUpPage(),
        '/user_login_page': (context) => const UserLoginPage(),
      },
    );
  }
}

class RouterPage extends StatelessWidget {
  const RouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Row(
          children: [
            Image.network(
              'https://res.cloudinary.com/dizbx1i1w/image/upload/v1752209937/fixam_logo_tkheom.png',
              width: 20,
              height: 15,
              fit: BoxFit.cover,
              loadingBuilder:
                  (
                    BuildContext context,
                    Widget child,
                    ImageChunkEvent? loadingProgress,
                  ) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, color: Colors.red);
              },
            ),
            Text(
              "Welcome to FiXam",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 320,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade700, Colors.orange.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/emergency_login_page");
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      FaIcon(
                        FontAwesomeIcons.truck,
                        color: Colors.white,
                        size: 50,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Connect to Your Road Hero",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 120),
              Image.network(
                'https://res.cloudinary.com/dizbx1i1w/image/upload/v1752266083/spanner_adjust_iubaen.png',
                width: 70,
                height: 40,
                fit: BoxFit.cover,
                loadingBuilder:
                    (
                      BuildContext context,
                      Widget child,
                      ImageChunkEvent? loadingProgress,
                    ) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, color: Colors.red);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
