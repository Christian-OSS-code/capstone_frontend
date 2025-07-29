import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class JobRequestsPage extends StatefulWidget {
  final String authToken;
  final String userId;

  const JobRequestsPage({
    super.key,
    required this.authToken,
    required this.userId,
  });

  @override
  State<JobRequestsPage> createState() => _JobRequestsPageState();
}

class _JobRequestsPageState extends State<JobRequestsPage> {
  List<dynamic> jobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDriverJobRequests();
  }

  Future<void> _fetchDriverJobRequests() async {
    setState(() {
      isLoading = true;
    });
    final response = await http.get(
      Uri.parse('http://16.171.145.59.8000/api/job/nearby/'),
      headers: {'Authorization': 'Bearer ${widget.authToken}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        jobs = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cannot Load Job Request: ${response.statusCode}"),
        ),
      );
    }
  }

  Future<void> _acceptJob(int jobId) async {
    final response = await http.post(
      Uri.parse('http://16.171.145.59.8000/api/jobs/$jobId/accept/'),
      headers: {'Authorization': 'Bearer ${widget.authToken}'},
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Job Accepted Successfully")));

      _fetchDriverJobRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to accept job: ${jsonDecode(response.body)['detail']}",
          ),
        ),
      );
    }
  }

  Future<void> _declineJobRequest(int jobId) async {
    final response = await http.post(
      Uri.parse('http://16.171.145.59:8000/api/job/$jobId/decline/'),
      headers: {'Authorization': 'Bearer ${widget.authToken}'},
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Cannot Decline Job: ${jsonDecode(response.body)['detail']}",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Job Request"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : jobs.isEmpty
          ? const Center(child: Text("No New Job Request"))
          : ListView.builder(
              padding: const EdgeInsets.all(15.0),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clinet: ${job['created_by']['full_name'] ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text("Email: ${job['created_by']['email'] ?? 'Not Available'}"),
                        Text("Phone: ${job['created_by']['phone_number'] ?? 'Not Available'}"),
                        Text("Location: (${job['latitude']}, ${job['loongitude']})"),
                        Text("Distance: ${job['distance'] ?? 'N/A'} km"),
                        const SizedBox(height: 10),
                        Text("Problem: ${job['description']}"),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed:() => _acceptJob(job['id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Accept"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () =>
                    _declineJobRequest(job['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,

                    ),
                   child: const Text('Decline'),

                   ),
                          ],
                        )
                      ],
                    )
                  )
                );

              },
            ),
    );
    }
  }

