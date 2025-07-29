// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class ActiveJobsPage extends StatefulWidget {
//   final String authToken;
//   final String userId;

//   const ActiveJobsPage({
//     super.key,
//     required this.authToken,
//     required this.userId,
//   });

//   @override
//   State<ActiveJobsPage> createState() => _ActiveJobsPageState();
// }

// class _ActiveJobsPageState extends State<ActiveJobsPage> {
//   List<dynamic> jobs = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchActiveJobs();
//   }

//   // Future<void> _fetchActiveJobs() async {
//   //   setState(() {
//   //     isLoading = true;
//   //   });
//   //   final response = await http.get(
//   //     Uri.parse(
//   //       'http://16.171.145.59:8000/api/jobs/my-jobs/artisan/?status=accepted&status=in_progress',
//   //     ),
//   //     headers: {'Authorization': 'Bearer ${widget.authToken}'},
//   //   );
//   //   if (response.statusCode == 200) {
//   //     setState(() {
//   //       jobs = jsonDecode(response.body)['jobs'];
       
//   //       isLoading = false;
//   //     });
//   //   } else {
//   //     setState(() {
//   //       isLoading = false;
//   //     });
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(
//   //         content: Text('Failed to load active jobs: ${response.statusCode}'),
//   //       ),
//   //     );
//   //   }
//   // }


//   Future<void> _fetchActiveJobs() async {
//   setState(() { isLoading = true; });
//   try {
//     final response = await http.get(
//       Uri.parse('http://16.171.145.59:8000/api/jobs/my-jobs/artisan/?status=accepted,in_progress'),
//       headers: {'Authorization': 'Bearer ${widget.authToken}'},
//     );
//     print('Active Jobs Response: ${response.statusCode} - ${response.body}');

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       setState(() {
//         jobs = (data['jobs'] as List?) ?? []; // Fallback to empty list if null
//         isLoading = false;
//       });
//     } else {
//       setState(() { isLoading = false; });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load active jobs: ${response.statusCode} - ${response.body}')),
//       );
//     }
//   } catch (e) {
//     print('Error fetching active jobs: $e');
//     setState(() { isLoading = false; });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error loading active jobs: $e')),
//     );
//   }
// }

//   Future<void> _updateJobStatus(int jobId, String status) async {
//     final response = await http.patch(
//       Uri.parse('http://16.171.145.59:8000/api/jobs/$jobId/update-status/'),
//       headers: {
//         'Authorization': 'Bearer ${widget.authToken}',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({'status': status}),
//     );
//     if (response.statusCode == 200) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Job status updated to $status')));
//       _fetchActiveJobs();
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Failed to update job: ${jsonDecode(response.body)['detail']}',
//           ),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Active Jobs'),
//         backgroundColor: Colors.blueAccent,
//         foregroundColor: Colors.white,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : jobs.isEmpty
//           ? const Center(child: Text('No active jobs'))
//           : ListView.builder(
//               padding: const EdgeInsets.all(15.0),
//               itemCount: jobs.length,
//               itemBuilder: (context, index) {
//                 final job = jobs[index];
//                 return Card(
//                   elevation: 5,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(15.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Client: ${job['created_by']['full_name'] ?? 'Unknown'}',
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Text('Email: ${job['created_by']['email'] ?? 'N/A'}'),
//                         Text(
//                           'Phone: ${job['created_by']['phone_number'] ?? 'N/A'}',
//                         ),
//                         Text(
//                           'Location: (${job['latitude']}, ${job['longitude']})',
//                         ),
//                         Text('Distance: ${job['distance'] ?? 'N/A'} km'),
//                         const SizedBox(height: 10),
//                         Text('Problem: ${job['description']}'),
//                         const SizedBox(height: 15),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             if (job['status'] == 'accepted')
//                               ElevatedButton(
//                                 onPressed: () =>
//                                     _updateJobStatus(job['id'], 'in_progress'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blue,
//                                   foregroundColor: Colors.white,
//                                 ),
//                                 child: const Text('Start Job'),
//                               ),
//                             if (job['status'] == 'in_progress')
//                               ElevatedButton(
//                                 onPressed: () =>
//                                     _updateJobStatus(job['id'], 'completed'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.green,
//                                   foregroundColor: Colors.white,
//                                 ),
//                                 child: const Text('Complete Job'),
//                               ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ActiveJobsPage extends StatefulWidget {
  final String authToken;
  final String userId;

  const ActiveJobsPage({super.key, required this.authToken, required this.userId});

  @override
  State<ActiveJobsPage> createState() => _ActiveJobsPageState();
}

class _ActiveJobsPageState extends State<ActiveJobsPage> {
  List<dynamic> jobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.authToken.isEmpty || widget.userId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/user_login_page');
      });
    } else {
      _fetchActiveJobs();
    }
  }

  Future<void> _fetchActiveJobs() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://16.171.145.59:8000/api/jobs/my-jobs/artisan/'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );
      print('Raw Active Jobs Response: ${response.body}'); 
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed Active Jobs Response: $data'); 
        print('Data Type: ${data.runtimeType}'); 
        List<dynamic> allJobs;
        if (data is List) {
          allJobs = data;
        } else if (data is Map<String, dynamic> && data.containsKey('jobs')) {
          allJobs = data['jobs'] is List ? data['jobs'] : [];
        } else {
          throw Exception('Invalid response format: Expected a list or map with "jobs" key');
        }
        setState(() {
          jobs = allJobs.where((job) => job['status'] == 'accepted' || job['status'] == 'in_progress').toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load active jobs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching active jobs: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching active jobs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.authToken.isEmpty || widget.userId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Jobs'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 5,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : jobs.isEmpty
              ? const Center(child: Text('No active jobs found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(job['description'] ?? 'No description'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${job['status'] ?? 'Unknown'}'),
                            Text('Customer: ${job['created_by']?['full_name'] ?? 'N/A'}'),
                            Text('Created: ${job['created_at'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
