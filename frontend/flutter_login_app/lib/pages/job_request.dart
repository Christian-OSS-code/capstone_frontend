import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class JobRequestsPage extends StatefulWidget {
  final String authToken;
  final String userId;

  const JobRequestsPage({super.key, required this.authToken, required this.userId});

  @override
  State<JobRequestsPage> createState() => _JobRequestsPageState();
}

class _JobRequestsPageState extends State<JobRequestsPage> {
  List<dynamic> jobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobRequests();
  }

  Future<void> _fetchJobRequests() async {
    setState(() { isLoading = true; });
    final response = await http.get(
      Uri.parse('http://16.171.145.59:8000/api/jobs/nearby/'),
      headers: {'Authorization': 'Bearer ${widget.authToken}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        jobs = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load job requests: ${response.statusCode}')),
      );
    }
  }

  Future<void> _acceptJob(int jobId) async {
    final response = await http.post(
      Uri.parse('http://16.171.145.59:8000/api/jobs/$jobId/accept/'),
      headers: {'Authorization': 'Bearer ${widget.authToken}'},
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job accepted successfully')),
      );
      _fetchJobRequests(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept job: ${jsonDecode(response.body)['detail']}')),
      );
    }
  }

  Future<void> _declineJob(int jobId) async {
    final response = await http.post(
      Uri.parse('http://16.171.145.59:8000/api/jobs/$jobId/decline/'),
      headers: {'Authorization': 'Bearer ${widget.authToken}'},
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job declined successfully')),
      );
      _fetchJobRequests(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline job: ${jsonDecode(response.body)['detail']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Job Requests'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : jobs.isEmpty
              ? const Center(child: Text('No new job requests'))
              : ListView.builder(
                  padding: const EdgeInsets.all(15.0),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.orange)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Client: ${job['created_by']['full_name'] ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text('Email: ${job['created_by']['email'] ?? 'N/A'}'),
                            Text('Phone: ${job['created_by']['phone_number'] ?? 'N/A'}'),
                            Text('Location: (${job['latitude']}, ${job['longitude']})'),
                            Text('Distance: ${job['distance'] ?? 'N/A'} km'),
                            const SizedBox(height: 10),
                            Text('Problem: ${job['description']}'),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _acceptJob(job['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Accept'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => _declineJob(job['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Decline'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}