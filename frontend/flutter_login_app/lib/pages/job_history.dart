import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class JobHistoryPage extends StatefulWidget {
  final String authToken;
  final String userId;
  const JobHistoryPage({
    super.key,
    required this.authToken,
    required this.userId,
  });

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
      _fetchArtisanJobHistory();
    }
  }

  Future<void> _fetchArtisanJobHistory() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://16.171.145.59:8000/api/jobs/my-jobs/artisan/'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );
      print('Job History: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Job History: $data");
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
          throw Exception('Invalid format: Map or List Expected');
        }
      } else {
        throw Exception(
          'Failed to load job history: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching jon history: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error Fetching Job History: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.authToken.isEmpty || widget.userId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
          ? const Center(child: Text('Found No Job'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(job['description'] ?? 'No Description'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${job['status'] ?? 'Unknown Job'}'),
                        Text('Created ${job['created-at'] ?? 'Not Available'}'),
                        Text('Customer: ${job['created_by'] ?? ['full_name'] ?? 'Not Available'}'),
                      ]
                    ),
                  ),
                );
              },
            ),
    );
  }
}
