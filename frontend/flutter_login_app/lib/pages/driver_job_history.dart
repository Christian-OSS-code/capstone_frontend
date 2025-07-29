import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DriverJobHistoryPage extends StatefulWidget {
  final String authToken;
  final String userId;
  const  DriverJobHistoryPage({super.key, required this.authToken, required this.userId});

  @override
  State<DriverJobHistoryPage> createState() => _DriverJobHistoryPageState();
}

class _DriverJobHistoryPageState extends State<DriverJobHistoryPage> {
  bool _isLoading = false;
  String? _authToken;
  String? _userId;
  List<dynamic> _jobs = [];
  final String _baseUrl = "http://16.171.145.59:8000";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('access_token');
      _userId = prefs.getString('user_id');
    });
    print("Loaded user data: userId=$_userId, authToken=$_authToken");
    if (_authToken == null || _userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session expired. Please log in again."),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, '/user_login_page');
      }
      return;
    }
    await _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    if (_authToken == null || _userId == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/jobs/my-jobs/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_authToken',
        },
      );
      print("Fetch jobs response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        final List<dynamic> jobData = jsonDecode(response.body);
        setState(() {
          _jobs = jobData;
        });
        if (jobData.isEmpty) {
          print("No jobs found for user $_userId");
        }
      } else if (response.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          setState(() {
            _authToken = newToken;
          });
          await _fetchJobs();
        } else {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/user_login_page');
          }
        }
      } else {
        print(
          "Failed to fetch jobs: ${response.statusCode} - ${response.body}",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to fetch jobs: ${response.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error fetching jobs: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error fetching jobs: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) return null;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/account/auth/refresh/'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      print(
        "Refresh token response: ${response.statusCode} - ${response.body}",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];
        await prefs.setString('access_token', newAccessToken);
        return newAccessToken;
      }
      return null;
    } catch (e) {
      print('Error refreshing token: $e');
      return null;
    }
  }

  void _navigateToServiceRequest() {
    if (_userId != null && _authToken != null) {
      Navigator.pushNamed(
        context,
        '/artisan_service_request',
        arguments: {'userId': _userId, 'authToken': _authToken},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session expired. Please log in again."),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushReplacementNamed(context, '/user_login_page');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Job History"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToServiceRequest,
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Job", style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
          ? const Center(child: Text("No jobs found"))
          : ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];
                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 5.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text("Job #${job['id']} - ${job['description']}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Status: ${job['status']}",
                          style: TextStyle(
                            color: job['status'] == 'accepted'
                                ? Colors.green
                                : job['status'] == 'declined'
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ),
                        if (job['artisan'] != null)
                          Text(
                            "Artisan: ${job['artisan']['full_name'] ?? 'N/A'}",
                          ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/available_artisans_page',
                          arguments: {
                            'job_id': job['id'].toString(),
                            'latitude': job['latitude'],
                            'longitude': job['longitude'],
                            'problem': job['description'],
                            'address': job['address'] ?? 'N/A',
                            'userId': _userId,
                            'authToken': _authToken,
                          },
                        );
                      },
                      child: const Text("View Details"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
