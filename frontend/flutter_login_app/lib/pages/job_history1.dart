// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class JobHistoryPage extends StatefulWidget {
//   final String authToken;
//   final String userId;

//   const JobHistoryPage({super.key, required this.authToken, required this.userId});

//   @override
//   State<JobHistoryPage> createState() => _JobHistoryPageState();
// }

// class _JobHistoryPageState extends State<JobHistoryPage> {
//   List<dynamic> jobs = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchJobHistory();
//   }

//   // Future<void> _fetchJobHistory() async {
//   //   setState(() { isLoading = true; });
//   //   final response = await http.get(
//   //     Uri.parse('http://16.171.145.59:8000/api/jobs/my-jobs/artisan/'),
//   //     headers: {'Authorization': 'Bearer ${widget.authToken}'},
//   //   );
//   //   if (response.statusCode == 200) {
//   //     setState(() {
//   //       jobs = jsonDecode(response.body)['jobs'];
//   //       isLoading = false;
//   //     });
//   //   } else {
//   //     setState(() { isLoading = false; });
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Failed to load job history: ${response.statusCode}')),
//   //     );
//   //   }
//   // }




// Future<void> _fetchJobHistory() async {
//   setState(() { isLoading = true; });
//   try {
//     final response = await http.get(
//       Uri.parse('http://16.171.145.59:8000/api/jobs/my-jobs/artisan/'),
//       headers: {'Authorization': 'Bearer ${widget.authToken}'},
//     );
//     print('Job History Response: ${response.statusCode} - ${response.body}');

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       setState(() {
//         jobs = (data['jobs'] as List?) ?? []; // Fallback to empty list if null
//         isLoading = false;
//       });
//     } else {
//       setState(() { isLoading = false; });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load job history: ${response.statusCode} - ${response.body}')),
//       );
//     }
//   } catch (e) {
//     print('Error fetching job history: $e');
//     setState(() { isLoading = false; });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error loading job history: $e')),
//     );
//   }
// }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Job History'),
//         backgroundColor: Colors.blueAccent,
//         foregroundColor: Colors.white,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : jobs.isEmpty
//               ? const Center(child: Text('No job history'))
//               : ListView.builder(
//                   padding: const EdgeInsets.all(15.0),
//                   itemCount: jobs.length,
//                   itemBuilder: (context, index) {
//                     final job = jobs[index];
//                     return Card(
//                       elevation: 5,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//                       child: Padding(
//                         padding: const EdgeInsets.all(15.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Client: ${job['created_by']['full_name'] ?? 'Unknown'}',
//                               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                             ),
//                             const SizedBox(height: 10),
//                             Text('Email: ${job['created_by']['email'] ?? 'N/A'}'),
//                             Text('Phone: ${job['created_by']['phone_number'] ?? 'N/A'}'),
//                             Text('Location: (${job['latitude']}, ${job['longitude']})'),
//                             Text('Distance: ${job['distance'] ?? 'N/A'} km'),
//                             const SizedBox(height: 10),
//                             Text('Problem: ${job['description']}'),
//                             const SizedBox(height: 10),
//                             Text('Status: ${job['status'].toUpperCase()}'),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class JobHistoryPage extends StatefulWidget {
  final String authToken;
  final String userId;

  const JobHistoryPage({super.key, required this.authToken, required this.userId});

  @override
  State<JobHistoryPage> createState() => _JobHistoryPageState();
}

class _JobHistoryPageState extends State<JobHistoryPage> {
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
      _fetchJobHistory();
    }
  }

  Future<void> _fetchJobHistory() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://16.171.145.59:8000/api/jobs/my-jobs/artisan/'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );
      print('Raw Job History Response: ${response.body}'); // Debug logging
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed Job History Response: $data'); // Debug logging
        print('Data Type: ${data.runtimeType}'); // Debug logging
        if (data is List) {
          setState(() {
            jobs = data;
            isLoading = false;
          });
        } else if (data is Map<String, dynamic> && data.containsKey('jobs')) {
          setState(() {
            jobs = data['jobs'] is List ? data['jobs'] : [];
            isLoading = false;
          });
        } else {
          throw Exception('Invalid response format: Expected a list or map with "jobs" key');
        }
      } else {
        throw Exception('Failed to load job history: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching job history: $e'); // Debug logging
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching job history: $e')),
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
        title: const Text('Job History'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 5,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : jobs.isEmpty
              ? const Center(child: Text('No jobs found'))
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
                            Text('Created: ${job['created_at'] ?? 'N/A'}'),
                            Text('Customer: ${job['created_by']?['full_name'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
