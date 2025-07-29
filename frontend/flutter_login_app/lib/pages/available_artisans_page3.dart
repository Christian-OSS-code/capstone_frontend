// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:convert';

// class UserArtisan {
//   final String id;
//   final String name;
//   final List<String> specialities;
//   final double distanceKm;
//   final double rating;
//   final int reviews;
//   final int yearsOfExperience;
//   final String workShopAddress;
//   final String photoUrl;
//   final String phoneNumber;

//   UserArtisan({
//     required this.id,
//     required this.name,
//     required this.specialities,
//     required this.distanceKm,
//     required this.rating,
//     required this.reviews,
//     required this.yearsOfExperience,
//     required this.workShopAddress,
//     required this.photoUrl,
//     required this.phoneNumber,
//   });

//   factory UserArtisan.fromJson(Map<String, dynamic> json) {
//     return UserArtisan(
//       id: json['id'].toString(),
//       name: json['user']['full_name'] ?? 'Artisan Not Known',
//       specialities: List<String>.from(json['skills'] ?? []),
//       distanceKm: (json['distance'] as num?)?.toDouble() ?? 0.0,
//       rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
//       reviews: json['rating_count'] ?? 0,
//       yearsOfExperience: json['experience_years'] ?? 0,
//       workShopAddress: json['work_shop_address'] ?? 'Not Provided',
//       photoUrl: json['photo_url'] ?? 'https://via.placeholder.com/150',
//       phoneNumber: json['user']['phone_number'] ?? 'Not Available',
//     );
//   }
// }

// class AvailableArtisansPage extends StatefulWidget {
//   const AvailableArtisansPage({super.key});

//   @override
//   State<AvailableArtisansPage> createState() => _AvailableArtisansPageState();
// }

// class _AvailableArtisansPageState extends State<AvailableArtisansPage> {
//   bool _isLoading = false;
//   String? _jobId;
//   String? _problemDescription;
//   String? _driverAddress;
//   String? _authToken;
//   String? _userId;
//   List<UserArtisan> _artisans = [];
//   String jobStatus = 'pending';
//   Map<String, dynamic>? jobDetails;
//   Timer? _pollingTimer;
//   bool _isTimedOut = false;
//   String? _selectedArtisanId;

//   final String _baseUrl = "http://16.171.145.59:8000";

//   @override
//   void initState() {
//     super.initState();
//     _checkSaveJob();
//   }

//   void _startPolling() {
//     if (_jobId == null || _authToken == null) return;
//     const pollingInterval = Duration(seconds: 10);
//     const timeoutDuration = Duration(minutes: 10);
//     int elapsedSeconds = 0;

//     _pollingTimer = Timer.periodic(pollingInterval, (timer) async {
//       if (elapsedSeconds >= timeoutDuration.inSeconds || !mounted) {
//         timer.cancel();
//         setState(() {
//           _isTimedOut = false;
//           _isLoading = false;
//         });
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("No Response From Artisan: Select Another Artisan"),
//               backgroundColor: Colors.red,
//             ),
//           );
//           await Future.delayed(const Duration(seconds: 2));
//           if (mounted) {
//             Navigator.pushReplacementNamed(context, '/available_artisans_page');
//           }
//         }
//       }
//     });
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args =
//         ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
//     if (args != null) {
//       _jobId = args['job_id']?.toString();
//       _problemDescription = args['problem'];
//       _driverAddress = args['address'];
//       _userId = args['userId']?.toString();
//       _authToken = args['authToken']?.toString();
//       _fetchArtisansDetails();
//     }
//   }

//   Future<void> _fetchArtisansDetails() async {
//     if (_jobId == null || _authToken == null) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Job data is missing"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       return;
//     }
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final artisansResponse = await http.get(
//         Uri.parse('$_baseUrl/api/jobs/$_jobId/match/?radius=10'),
//         headers: {
//           'Content-Type': 'application/json; charset=UTF-8',
//           'Authorization': 'Bearer $_authToken',
//         },
//       );
//       if (artisansResponse.statusCode == 200) {
//         final List<dynamic> artisanData = jsonDecode(artisansResponse.body);
//         setState(() {
//           _artisans = artisanData
//               .map((json) => UserArtisan.fromJson(json))
//               .toList();
//         });
//       } else {
//         debugPrint(
//           "Failed to fetch Artisans: ${artisansResponse.statusCode} - ${artisansResponse.body}",
//         );
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 "Failed to Fetch Artisans: ${artisansResponse.body}",
//               ),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("Error fetching artisans: $e");

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("An error occured: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _suggestArtisans(String artisanId) async {
//     if (_jobId == null || _authToken == null) return;
//     try {
//       final response = await http.post(
//         Uri.parse('$_baseUrl/api/jobs/$_jobId/suggest/$artisanId/'),
//         headers: {
//           'Content-Type': 'application/json; charset=UTF-8',
//           'Authorization': 'Bearer $_authToken',
//         },
//       );
//       if (response.statusCode == 200) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text("Nearby Artisan suggested Successfully"),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } else {
//         debugPrint("Failed to successfully suggest Nearby Artisan");
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text("Artisan: ${response.body} already booked"),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("Encountered error suggesting Nearby Artisan: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   Future<void> _handlePhoneCalls(String phoneNumber) async {
//     final Uri launchUriCall = Uri(scheme: 'tel', path: phoneNumber);
//     if (await canLaunchUrl(launchUriCall)) {
//       await launchUrl(launchUriCall);
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Call Failed")));
//       }
//     }
//   }

//   void _handleChats(UserArtisan artisan) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Chat with artisan${artisan.name}")),
//       );
//       Navigator.pushNamed(context, "/user_chat_page", arguments: artisan);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade200,
//       appBar: AppBar(
//         title: const Text("Available Artisans"),
//         backgroundColor: Colors.blueAccent,
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(18.0),
//             color: Colors.blueAccent.shade200,
//             width: double.infinity,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   "Problem Details:",
//                   style: TextStyle(
//                     color: Colors.black87,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   "Location: ${_driverAddress ?? 'N/A'}",
//                   style: const TextStyle(color: Colors.black87, fontSize: 16),
//                 ),
//                 Text(
//                   "Problem Descriptio: ${_problemDescription ?? 'N/A'}",
//                   style: const TextStyle(color: Colors.black87, fontSize: 16),
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   "Nearby Mechanics",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _artisans.isEmpty
//                 ? const Center(child: Text("No nearby artisan"))
//                 : ListView.builder(
//                     padding: const EdgeInsets.all(10.0),
//                     itemCount: _artisans.length,
//                     itemBuilder: (context, index) {
//                       final artisan = _artisans[index];
//                       return Card(
//                         elevation: 5,
//                         margin: const EdgeInsets.symmetric(
//                           vertical: 8.0,
//                           horizontal: 5.0,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(15.0),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   CircleAvatar(
//                                     radius: 40,
//                                     backgroundColor: Colors.grey.shade300,
//                                     backgroundImage: CachedNetworkImageProvider(
//                                       artisan.photoUrl,
//                                     ),
//                                     onBackgroundImageError:
//                                         (exception, stackTrace) {
//                                           debugPrint(
//                                             "Error loading image: $exception",
//                                           );
//                                         },
//                                     child: artisan.photoUrl.isEmpty
//                                         ? const Icon(
//                                             Icons.person,
//                                             color: Colors.white,
//                                             size: 40,
//                                           )
//                                         : null,
//                                   ),
//                                   const SizedBox(width: 15),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           artisan.name,
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 8),
//                                         Row(
//                                           children: [
//                                             Icon(
//                                               Icons.star_rounded,
//                                               color: Colors.amber.shade700,
//                                               size: 20,
//                                             ),
//                                             const SizedBox(width: 5),
//                                             Text(
//                                               "${artisan.rating.toStringAsFixed(1)} (${artisan.reviews} reviews)",
//                                               style: TextStyle(fontSize: 16),
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 10),
//                                         Row(
//                                           children: [
//                                             Text(
//                                               "${artisan.distanceKm.toStringAsFixed(1)} km away",
//                                               style: TextStyle(
//                                                 color: Colors.green.shade700,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const Divider(height: 25, thickness: 1),
//                               const Text(
//                                 "Specialties",
//                                 style: TextStyle(
//                                   color: Colors.blueGrey,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 5),
//                               Wrap(
//                                 spacing: 8.0,
//                                 runSpacing: 4.0,
//                                 children: artisan.specialities.map((skill) {
//                                   return Chip(
//                                     label: Text(skill),
//                                     backgroundColor: Colors.blue.shade800,
//                                     labelStyle: TextStyle(
//                                       color: Colors.blue.shade800,
//                                       fontSize: 13,
//                                     ),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                       side: BorderSide(
//                                         color: Colors.blue.shade200,
//                                       ),
//                                     ),
//                                   );
//                                 }).toList(),
//                               ),
//                               const SizedBox(height: 15),
//                               Row(
//                                 children: [
//                                   Icon(
//                                     Icons.work,
//                                     color: Colors.grey.shade600,
//                                     size: 20,
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Text(
//                                     "${artisan.yearsOfExperience} Years Experience",
//                                     style: const TextStyle(
//                                       fontSize: 16,
//                                       color: Colors.black87,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 15),
//                               Row(
//                                 children: [
//                                   Icon(
//                                     Icons.location_on,
//                                     color: Colors.grey.shade600,
//                                     size: 20,
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: Text(
//                                       "Worskhop: ${artisan.workShopAddress}",
//                                       style: const TextStyle(
//                                         fontSize: 16,
//                                         color: Colors.black87,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 15),
//                               Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Expanded(
//                                     child: ElevatedButton.icon(
//                                       onPressed: () => _handlePhoneCalls(
//                                         artisan.phoneNumber,
//                                       ),
//                                       icon: const Icon(
//                                         Icons.phone,
//                                         color: Colors.white,
//                                       ),
//                                       label: const Text(
//                                         "Call",
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                       style: ElevatedButton.styleFrom(
//                                         padding: const EdgeInsets.symmetric(
//                                           vertical: 15,
//                                         ),
//                                         backgroundColor: Colors.green.shade600,
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             15,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: ElevatedButton.icon(
//                                       onPressed: () {
//                                         _handleChats(artisan);
//                                       },
//                                       icon: const Icon(
//                                         Icons.chat,
//                                         color: Colors.white,
//                                       ),
//                                       label: const Text(
//                                         "Chat",
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                       style: ElevatedButton.styleFrom(
//                                         padding: const EdgeInsets.symmetric(
//                                           vertical: 15,
//                                         ),
//                                         backgroundColor: Colors.blue.shade600,
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             15,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: ElevatedButton.icon(
//                                       onPressed: () {
//                                         _suggestArtisans(artisan.id);
//                                       },

//                                       icon: const Icon(
//                                         Icons.check,
//                                         color: Colors.white,
//                                       ),
//                                       label: const Text(
//                                         "Select",
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                       style: ElevatedButton.styleFrom(
//                                         padding: const EdgeInsets.symmetric(
//                                           vertical: 15,
//                                         ),

//                                         backgroundColor: Colors.orange.shade600,
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             15,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
