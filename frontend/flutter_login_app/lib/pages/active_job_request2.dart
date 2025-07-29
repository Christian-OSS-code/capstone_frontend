import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ActiveJobsPage extends StatefulWidget {
  final String authToken;
  final String userId;

  const ActiveJobsPage({
    super.key,
    required this.authToken,
    required this.userId,
  });
  @override
  State<ActiveJobsPage> createState() => _ActiveJobsPageState();
}

class _ActiveJobsPageState extends State<ActiveJobsPage> {
  List<dynamic> activeJobs = [];
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
        Uri.parse('http://16.171.145.59:8000/api/jobs/artisan/'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );
      print("Active Jobs: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Parsed Active Jobs Response: $data");
        List<dynamic> allJobs;

        if (data is List) {
          allJobs = data;
        } else if (data is Map<String, dynamic> && data.containsKey('jobs')) {
          allJobs = data['jobs'] is List ? data['jobs'] : [];
        } else {
          throw Exception('invalid response format');
        }
        setState(() {
          activeJobs = allJobs
              .where(
                (job) =>
                    job['status'] == 'accepted' ||
                    job['status'] == 'in_progress',
              )
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception(
          "Failed to Load Active Jobs: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print("Error fetching active jobs: $e");
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error Fetching Active Jobs: $e")),
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
        title: const Text('Active Jobs'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 5,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeJobs.isEmpty
          ? const Center(child: Text("No Active Jobs"))
          : ListView.builder(
              itemCount: activeJobs.length,
              itemBuilder: (context, index) {
                final job = activeJobs[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(job['description'] ?? 'No description',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${job['status'] ?? 'Unknown Job'}'),
                        Text('Driver: ${job['created_by']?['full_name']??"Not Available"}'),
                        
                      ],
                    )
                  )
                );
              },
            ),
    );
  }
}
