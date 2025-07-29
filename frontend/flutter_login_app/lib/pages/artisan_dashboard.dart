





// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class ArtisanDashboardPage extends StatefulWidget {
//   final String authToken;
//   final String userId;

//   const ArtisanDashboardPage({
//     super.key,
//     required this.authToken,
//     required this.userId,
//   });

//   @override
//   State<ArtisanDashboardPage> createState() => _ArtisanDashboardPageState();
// }

// class _ArtisanDashboardPageState extends State<ArtisanDashboardPage> {
//   String artisanName = '';
//   bool _isAvailable = true;
//   double overallRating = 0.0;
//   int jobCompleted = 0;
//   int newJobRequest = 0;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchArtisanData();
//   }



//   Future<void> _fetchArtisanData() async {
//   setState(() {
//     isLoading = true;
//   });

//   try {
//     final response = await http.get(
//       Uri.parse('http://16.171.145.59:8000/api/jobs/my-jobs/artisan/'),
//       headers: {'Authorization': 'Bearer ${widget.authToken}'},
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       print('Response Data: $data');

//       // Safely parse the response data
//       setState(() {
//         // Handle artisan name
//         if (data is Map && data.containsKey('jobs') && data['jobs'] is List) {
//           final jobs = data['jobs'] as List;
//           if (jobs.isNotEmpty && jobs[0] is Map) {
//             final firstJob = jobs[0] as Map;
//             if (firstJob.containsKey('artisan') && 
//                 firstJob['artisan'] is Map &&
//                 firstJob['artisan'].containsKey('full_name')) {
//               artisanName = firstJob['artisan']['full_name'] ?? 'John';
//             }
//           }
//         }

//         // Handle numeric values with type safety
//         overallRating = (data is Map && data.containsKey('overall_rating'))
//             ? (data['overall_rating'] is num 
//                 ? data['overall_rating'].toDouble() 
//                 : 0.0)
//             : 0.0;

//         jobCompleted = (data is Map && data.containsKey('job_completed'))
//             ? (data['job_completed'] is int 
//                 ? data['job_completed'] 
//                 : 0)
//             : 0;

//         newJobRequest = (data is Map && data.containsKey('new_job_requests'))
//             ? (data['new_job_requests'] is int 
//                 ? data['new_job_requests'] 
//                 : 0)
//             : 0;

//         isLoading = false;
//       });
//     } else {
//       throw Exception('Failed to load artisan data: ${response.statusCode}');
//     }
//   } catch (e) {
//     debugPrint('Error fetching artisan data: $e');
//     setState(() {
//       isLoading = false;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Error loading data: ${e.toString()}'),
//       ),
//     );
//   }
// }

//   Future<void> _updateAvailability(bool value) async {
//     final response = await http.patch(
//       Uri.parse('http://16.171.145.59:8000/api/artisans/profile/'),
//       headers: {
//         'Authorization': 'Bearer ${widget.authToken}',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({'available': value}),
//     );

//     if (response.statusCode == 200) {
//       setState(() {
//         _isAvailable = value;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             value ? "You are now open for jobs" : "You are now offline",
//           ),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Failed to update availability: ${response.statusCode}',
//           ),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Mechanic Dashboard - $artisanName"),
//         backgroundColor: Colors.orange,
//         foregroundColor: Colors.white,
//         elevation: 5,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(15.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Hi, $artisanName",
//                     style: const TextStyle(
//                       color: Colors.orange,
//                       fontSize: 25,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   const Text(
//                     "Hub for Managing Jobs and your Profile",
//                     style: TextStyle(
//                       color: Colors.orangeAccent,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   Card(
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(20.0),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 "Availability Status",
//                                 style: TextStyle(
//                                   color: Colors.black87,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 10),
//                               Text(
//                                 _isAvailable
//                                     ? "Online and Ready for job"
//                                     : "Offline. Try again later",
//                                 style: TextStyle(
//                                   color: _isAvailable
//                                       ? Color.fromARGB(255, 124, 143, 124)
//                                       : Colors.red,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           Switch(
//                             value: _isAvailable,
//                             onChanged: _updateAvailability,
//                             activeColor: Color.fromARGB(255, 124, 143, 124),
//                             inactiveThumbColor: Color.fromARGB(255, 124, 143, 124),
//                             inactiveTrackColor: Colors.green.shade100,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                   const Text(
//                     "Your Performance at a glance",
//                     style: TextStyle(color: Colors.black87, fontSize: 16),
//                   ),
//                   const SizedBox(height: 15),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildMetricCard(
//                           icon: FontAwesomeIcons.star,
//                           color: Colors.purple.shade600,
//                           label: "Your Overall Rating",
//                           value: overallRating.toStringAsFixed(1),
//                         ),
//                       ),
//                       const SizedBox(width: 15),
//                       Expanded(
//                         child: _buildMetricCard(
//                           icon: FontAwesomeIcons.checkCircle,
//                           color: Colors.orange.shade600,
//                           label: "Jobs Completed",
//                           value: jobCompleted.toString(),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 15),
//                   const Text(
//                     "Quick Actions",
//                     style: TextStyle(color: Colors.black87, fontSize: 20),
//                   ),
//                   const SizedBox(height: 20),
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 2,
//                     crossAxisSpacing: 15,
//                     mainAxisSpacing: 15,
//                     children: [
//                       _actionButtonCard(
//                         context,
//                         icon: FontAwesomeIcons.userCog,
//                         label: "Manage Profile",
//                         color: Colors.teal,
//                         onTap: () {
//                           Navigator.pushNamed(
//                             context,
//                             '/artisan_profile_creation',
//                             arguments: {
//                               'authToken': widget.authToken,
//                               'userId': widget.userId,
//                             },
//                           );
//                         },
//                       ),
//                       _actionButtonCard(
//                         context,
//                         icon: FontAwesomeIcons.bell,
//                         label: "New Job Requests",
//                         color: Colors.tealAccent,
//                         badgeCount: newJobRequest,
//                         onTap: () {
//                           Navigator.pushNamed(
//                             context,
//                             '/job_request',
//                             arguments: {
//                               'authToken': widget.authToken,
//                               'userId': widget.userId,
//                             },
//                           );
//                         },
//                       ),
//                       _actionButtonCard(
//                         context,
//                         icon: FontAwesomeIcons.tasks,
//                         label: "My Active Jobs",
//                         color: Colors.blue,
//                         onTap: () {
//                           Navigator.pushNamed(
//                             context,
//                             '/active_job_request',
//                             arguments: {
//                               'authToken': widget.authToken,
//                               'userId': widget.userId,
//                             },
//                           );
//                         },
//                       ),
//                       _actionButtonCard(
//                         context,
//                         icon: FontAwesomeIcons.history,
//                         label: "Job History",
//                         color: Colors.blue,
//                         onTap: () {
//                           Navigator.pushNamed(
//                             context,
//                             '/job_history',
//                             arguments: {
//                               'authToken': widget.authToken,
//                               'userId': widget.userId,
//                             },
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildMetricCard({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required String value,
//   }) {
//     return Card(
//       elevation: 5,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             FaIcon(icon, color: color, size: 30),
//             const SizedBox(height: 10),
//             Text(
//               value,
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               label,
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.blue, fontSize: 14),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _actionButtonCard(
//     BuildContext context, {
//     required IconData icon,
//     required String label,
//     required Color color,
//     VoidCallback? onTap,
//     int? badgeCount,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(15),
//       child: Card(
//         elevation: 5,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         child: Container(
//           padding: const EdgeInsets.all(15.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   FaIcon(icon, color: color, size: 20),
//                   if (badgeCount != null && badgeCount > 0)
//                     Positioned(
//                       top: -5,
//                       right: -5,
//                       child: Container(
//                         padding: const EdgeInsets.all(5.0),
//                         decoration: BoxDecoration(
//                           color: Colors.red,
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         constraints: const BoxConstraints(
//                           minHeight: 20,
//                           minWidth: 20,
//                         ),
//                         child: Text(
//                           "$badgeCount",
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 label,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey.shade800,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }






import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ArtisanDashboardPage extends StatefulWidget {
  final String authToken;
  final String userId;

  const ArtisanDashboardPage({
    super.key,
    required this.authToken,
    required this.userId,
  });

  @override
  State<ArtisanDashboardPage> createState() => _ArtisanDashboardPageState();
}

class _ArtisanDashboardPageState extends State<ArtisanDashboardPage> {
  String artisanName = 'Artisan';
  bool _isAvailable = true;
  double overallRating = 0.0;
  int jobCompleted = 0;
  int newJobRequest = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArtisanData();
  }

  Future<void> _fetchArtisanData() async {
    setState(() => isLoading = true);

    try {
      // Fetch artisan profile
      final profileResponse = await http.get(
        Uri.parse('http://16.171.145.59:8000/api/accounts/me/'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );

      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to load profile: ${profileResponse.statusCode}');
      }

      final profileData = jsonDecode(profileResponse.body);
      if (profileData['is_artisan'] != true) {
        throw Exception('User is not an artisan');
      }

      // Fetch job metrics
      final jobsResponse = await http.get(
        Uri.parse('http://16.171.145.59:8000/api/jobs/my-jobs/artisan/'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );

      if (jobsResponse.statusCode != 200) {
        throw Exception('Failed to load job data: ${jobsResponse.statusCode}');
      }

      final jobsData = jsonDecode(jobsResponse.body);

      setState(() {
        // Profile data
        artisanName = '${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}'.trim();
        if (artisanName.isEmpty) artisanName = 'Artisan';
        _isAvailable = profileData['is_available'] ?? true;

        // Job metrics
        overallRating = (jobsData['overall_rating'] is num ? jobsData['overall_rating'].toDouble() : 0.0);
        jobCompleted = (jobsData['completed_jobs'] is int ? jobsData['completed_jobs'] : 0);
        newJobRequest = (jobsData['new_job_requests'] is int ? jobsData['new_job_requests'] : 0);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _updateAvailability(bool value) async {
    try {
      final response = await http.patch(
        Uri.parse('http://16.171.145.59:8000/api/artisans/profile/'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'available': value}),
      );

      if (response.statusCode == 200) {
        setState(() => _isAvailable = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? 'Now open for jobs' : 'Now offline')),
        );
      } else {
        throw Exception('Failed to update availability: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating availability: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mechanic Dashboard - $artisanName'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 5,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $artisanName',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Hub for Managing Jobs and Your Profile',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Availability Status',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _isAvailable ? 'Online and Ready' : 'Offline',
                                style: TextStyle(
                                  color: _isAvailable ? Colors.green : Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: _updateAvailability,
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Your Performance',
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: FontAwesomeIcons.star,
                          color: Colors.purple.shade600,
                          label: 'Overall Rating',
                          value: overallRating.toStringAsFixed(1),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildMetricCard(
                          icon: FontAwesomeIcons.checkCircle,
                          color: Colors.orange.shade600,
                          label: 'Jobs Completed',
                          value: jobCompleted.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(color: Colors.black87, fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                  
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _actionButtonCard(
                        context,
                        icon: FontAwesomeIcons.userCog,
                        label: 'Manage Profile',
                        color: Colors.teal,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/artisan_profile_creation',
                            arguments: {'authToken': widget.authToken, 'userId': widget.userId},
                          );
                        },
                      ),
                      _actionButtonCard(
                        context,
                        icon: FontAwesomeIcons.bell,
                        label: 'New Job Requests',
                        color: Colors.tealAccent,
                        badgeCount: newJobRequest,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/job_request',
                            arguments: {'authToken': widget.authToken, 'userId': widget.userId},
                          );
                        },
                      ),
                      _actionButtonCard(
                        context,
                        icon: FontAwesomeIcons.tasks,
                        label: 'Active Jobs',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/active_job_request',
                            arguments: {'authToken': widget.authToken, 'userId': widget.userId},
                          );
                        },
                
                      ),
                      _actionButtonCard(
                        context,
                        icon: FontAwesomeIcons.history,
                        label: 'Job History',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/job_history',
                            arguments: {'authToken': widget.authToken, 'userId': widget.userId},
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButtonCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    int? badgeCount,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FaIcon(icon, color: color, size: 20),
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minHeight: 20, minWidth: 20),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}