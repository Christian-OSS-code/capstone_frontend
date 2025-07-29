import 'package:flutter/material.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.build, size: 80, color: Colors.orange),
            const Text(
              "Titabi Assist",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Connect With Your Road Hero",
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup_page');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),

                child: const Text(
                  "Get Help",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//             Text(
//               "Home Page",
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Theme.of(context).colorScheme.onPrimary,
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: <Widget>[
//               Image.network(
//                 'https://res.cloudinary.com/dizbx1i1w/image/upload/v1752209937/fixam_logo_tkheom.png',
//                 width: 200,
//                 height: 50,
//                 fit: BoxFit.contain,
//                 loadingBuilder:
//                     (
//                       BuildContext context,
//                       Widget child,
//                       ImageChunkEvent? loadingProgress,
//                     ) {
//                       if (loadingProgress == null) return child;
//                       return Center(
//                         child: CircularProgressIndicator(
//                           value: loadingProgress.expectedTotalBytes != null
//                               ? loadingProgress.cumulativeBytesLoaded /
//                                     loadingProgress.expectedTotalBytes!
//                               : null,
//                         ),
//                       );
//                     },
//                 errorBuilder: (context, error, stackTrace) {
//                   return const Icon(Icons.broken_image, color: Colors.red);
//                 },
//               ),
//               const Text(
//                 "Welcome to Titahbi Assist",
//                 style: TextStyle(
//                   color: Colors.blue,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               Container(
//                 width: 270,
//                 height: 100,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       spreadRadius: 3,
//                       blurRadius: 10,
//                       offset: const Offset(0, 8),
//                     ),
//                   ],
//                   gradient: LinearGradient(
//                     colors: [Colors.orange.shade700, Colors.orange.shade900],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                 ),
//                 child: TextButton(
//                   onPressed: () {
//                     Navigator.pushReplacementNamed(context, "/signup_page");
//                   },
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: const <Widget>[
//                       FaIcon(
//                         FontAwesomeIcons.truck,
//                         color: Colors.white,
//                         size: 40,
//                       ),
//                       SizedBox(height: 5),
//                       Text(
//                         "Get Instance Help",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 20,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
