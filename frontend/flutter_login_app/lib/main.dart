import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_login_app/pages/artisans_dashboard.dart';
import 'package:flutter_login_app/pages/available_artisans_page.dart';

import 'package:flutter_login_app/pages/my_home_page.dart';
import 'package:flutter_login_app/pages/signup_page.dart';
import 'package:flutter_login_app/pages/user_login_page.dart';
import 'package:flutter_login_app/pages/user_profile.dart';
import 'package:flutter_login_app/pages/emergency_login_page.dart';
// import 'package:flutter_login_app/pages/artisan_service_request.dart';

void main() {
  runApp(const RouterPage());
}

class RouterPage extends StatelessWidget {
  const RouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Roadside Connect",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(76, 175, 80, 1),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 4,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      routes: {
        '/': (context) => const MyHomePage(),
        '/signup_page': (context) => const SignUpPage(),
        '/user_login_page': (context) => const UserLoginPage(),
        '/emergency_login_page': (context) => const EmergencyLoginPage(),
        '/available_mechanics_page': (context) => const AvailableArtisanPage(),
        '/artisans_dashboard': (context) => const ArtisanDashboardPage(),
        // '/artisan_service_request': (context) => const MechanicServiceRequest(),
      },
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/user_profile') {
          final credential = settings.arguments as Map<String, String>?;
          if (credential != null &&
              credential.containsKey('userId') &&
              credential.containsKey('authToken')) {
            return MaterialPageRoute(
              builder: (context) => UserProfileCreation(),
              settings: settings,
            );
          }
          return MaterialPageRoute(
            builder: (context) {
              return const Scaffold(
                body: Center(child: Text("Error: profile data missing")),
              );
            },
          );
        }
        return MaterialPageRoute(
          builder: (context) {
            return const Scaffold(
              body: Center(child: Text("Erro: Unknown route")),
            );
          },
        );
      },
    );
  }
}
