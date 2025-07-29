import 'package:flutter/material.dart';
import 'package:flutter_login_app/pages/active_job_request.dart';
import 'package:flutter_login_app/pages/available_artisans_page.dart';
import 'package:flutter_login_app/pages/driver_job_history.dart';
import 'package:flutter_login_app/pages/job_history.dart';
import 'package:flutter_login_app/pages/job_request.dart';
import 'package:flutter_login_app/pages/my_home_page.dart';
import 'package:flutter_login_app/pages/signup_page.dart';
import 'package:flutter_login_app/pages/user_login_page.dart';
import 'package:flutter_login_app/pages/emergency_login_page.dart';
import 'package:flutter_login_app/pages/artisan_service_request.dart';
import 'package:flutter_login_app/pages/artisan_profile.dart';
import 'package:flutter_login_app/pages/artisan_dashboard.dart';

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
        '/artisan_service_request': (context) => const ArtisanServiceRequest(),
        '/available_artisans_page': (context) => const AvailableArtisansPage(),

        '/job_requests': (contex) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, String>?;
          if (args != null &&
              args.containsKey('authToken') &&
              args.containsKey('userId')) {
            return JobRequestsPage(
              authToken: args['authToken']!,
              userId: args['userId']!,
            );
          }
          return const Scaffold(
            body: Center(child: Text("Token or Id Not Found")),
          );
        },

        '/active_job_request': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, String>?;

          if (args != null &&
              args.containsKey('authToken') &&
              args.containsKey('userId')) {
            return ActiveJobsPage(
              authToken: args['authToken']!,
              userId: args['userId']!,
            );
          }
          return const Scaffold(
            body: Center(child: Text("Token or Id Not Found")),
          );
        },
        '/job_history': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, String>?;
          if (args != null &&
              args.containsKey('authToken') &&
              args.containsKey('userId')) {
            return JobHistoryPage(
              authToken: args['authToken']!,
              userId: args['userId']!,
            );
          }
          return Scaffold(body: Center(child: Text("Missing Token or Id")));
        },
        '/artisan_profile': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, String>?;
          if (args != null &&
              args.containsKey('authToken') &&
              args.containsKey('userId')) {
            return ArtisanProfileCreation(
              authToken: args['authToken']!,
              userId: args['userId']!,
            );
          }
          return Scaffold(
            body: Center(child: Text('Missing Token or Id'))

          );
        },
        '/artisan_dashboard': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, String>?;

          if (args != null &&
              args.containsKey('authToken') &&
              args.containsKey('userId')) {
            return ArtisanDashboardPage(
              authToken: args['authToken']!,
              userId: args['userId']!,
            );
          }
          return const Scaffold(
            body: Center(child: Text("Token or Id Not Found")),
          );
        },
        '/driver_job_history': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, String>?;

          if (args != null &&
              args.containsKey('authToken') &&
              args.containsKey('userId')) {
            return DriverJobHistoryPage(
              authToken: args['authToken']!,
              userId: args['userId']!,
            );
          }
          return const Scaffold(
            body: Center(child: Text("Token or Id Not Found")),
          );
        },
      },
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/user_profile') {
          final credential = settings.arguments as Map<String, String>?;
          if (credential != null &&
              credential.containsKey('userId') &&
              credential.containsKey('authToken')) {
            return MaterialPageRoute(
              builder: (context) => ArtisanProfileCreation(
                authToken: credential['authToken']!,
                userId: credential['userId']!,
              ),
              settings: settings,
            );
          }
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
                body: Center(child: Text("Error: profile data missing")),
              ),
            
          );
        }
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
              body: Center(child: Text("Erro: Unknown route")),
            ),
          
        );
      },
    );
  }
}
