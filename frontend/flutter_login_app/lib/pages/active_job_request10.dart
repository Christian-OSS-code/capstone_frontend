import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ActiveJobPage extends StatefulWidget {
  final String authToken;
  final String userId;

  const ActiveJobPage({
    super.key,
    required this.authToken,
    required this.userId,
  });

  @override
  State<ActiveJobPage> createState() => _ActiveJobPageState();
}

class _ActiveJobPageState extends State<ActiveJobPage> {
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
        Uri.parse('http://16.171.145.59:8000/api/jobs/my-jobs/artisan'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Active Job Response: $data");
        List<dynamic> allJobs;
        if (data is List) {
          allJobs = data;
        } else if (data is Map<String, dynamic> && data.containsKey('jobs')) {
          allJobs = data['jobs'] is List ? data['jobs'] : [];
        } else {
          throw Exception('invalid response format: Expected a list or a Map');
        }
        setState(() {
          jobs = allJobs
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
          'Failed to Load Active Jobs: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print("Error in Fetching Active Jobs: $e");
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
        title: const Text("Active Jobs"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 5,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        Text(
                          'Status: ${job['created_by']?['full_name'] ?? 'N/A'}',
                        ),
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
