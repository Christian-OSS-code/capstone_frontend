import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

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
      final profileResponse = await http.get(
        Uri.parse('http://16.171.145.59:8000/api/accounts/me/'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );

      if (profileResponse.statusCode != 200) {
        throw Exception(
          "Failed to load profile: ${profileResponse.statusCode}",
        );
      }
      final profileData = jsonDecode(profileResponse.body);
      if (profileData['is_artisan'] != true) {
        throw Exception("User is not an artisan");
      }
      final jobsResponse = await http.get(
        Uri.parse('http://16.171.145.59:8000/api/jobs/my-jobs/artisan/'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );

      if (jobsResponse.statusCode != 200) {
        throw Exception("Failed to load jobs: ${jobsResponse.statusCode}");
      }
      final jobsData = jsonDecode(jobsResponse.body);

      setState(() {
        artisanName =
            '${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}'
                .trim();
        if (artisanName.isEmpty) artisanName = 'Artisan';
        _isAvailable = profileData['is_available'] ?? true;

        overallRating = (jobsData['overall_rating'] is num
            ? jobsData['overall_rating'].toDouble()
            : 0.0);
        jobCompleted = (jobsData['completed_jobs'] is int
            ? jobsData['completed_jobs']
            : 0);
        newJobRequest = (jobsData['new_job_requests'] is int
            ? jobsData['new_job_requests']
            : 0);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error in Fetching Data: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error in Loading data: $e")));
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
          SnackBar(content: Text(value ? "Now Open for Jobs" : "Now Offline")),
        );
      } else {
        throw Exception(
          "Failed to Update Availablity Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error Updating Availablity Status: $e")),
      );

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Artisan Dahsboard - $artisanName"),
      backgroundColor: Colors.orange,
      foregroundColor: Colors.orange,
      elevation: 5,
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment:  CrossAxisAlignment.start,
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
                'Manage Your Jobs',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment:  MainAxisAlignment.spaceBetween,
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
                          )
                        ]
                      ),
                      Switch(
                        value: _isAvailable,
                        onChanged: _updateAvailability,
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.shade300,
                      )
                    ]
                  )
                )
              ),
              const SizedBox(height: 15),
              const Text(
                'Your Performance',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,

                ),
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
                    )
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildMetricCard(
                      icon: FontAwesomeIcons.checkCircle,
                      color: Colors.orange.shade600,
                      label: 'Jobs Completed',
                      value: jobCompleted.toString(),
                    )

                  )

                ]
              ),
              const SizedBox(height: 15),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                ),
               
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
                    label: "Manage Profile",
                    color: Colors.teal,
                    onTap: (){
                      Navigator.pushNamed(
                        context,
                        '/artisan_profile',
                        arguments: {
                          'authToken': widget.authToken,
                          'userId': widget.userId,
                        },
                      );
                    }
                  ),
                  _actionButtonCard(
                    context,
                    icon: FontAwesomeIcons.bell,
                    label: 'New Job Requests',
                    color: Colors.tealAccent,
                    badgeCount: newJobRequest,
                    onTap: (){
                      Navigator.pushNamed(
                        context,
                        'job_request',
                        arguments: {
                          'authToken': widget.authToken,
                          'userId': widget.userId,
                        },

                      );
                    }
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
                        arguments: {
                          'authToken' : widget.authToken,
                          'userId' : widget.userId,
                        },
                        );
                    }
                  ),
                  _actionButtonCard(
                    context,
                    icon: FontAwesomeIcons.history,
                    label: 'Job History',
                    color: Colors.blue,
                    onTap: (){
                      Navigator.pushNamed(
                        context, 
                        '/job_history',
                        arguments: {
                          'authToken' : widget.authToken,
                          'userId': widget.userId
                        },
                        );
                    }
                  )
                ]
               )
            ],
          )
        )
    );
  }
  Widget _buildMetricCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }){
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
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              )
            ),
            const SizedBox(height: 20),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 14,
              ),
            )
          ]
        )
      )
    );
  }
  Widget _actionButtonCard(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    int? badgeCount,
  }){
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
                    child:Container(
                      padding: const EdgeInsets.all(15.0),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),

                      ),
                      constraints: const BoxConstraints(minHeight:  20, minWidth: 20),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      )
                    )
                    )
                ]
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                )
              )
            ],
          )
        )
      )
    );
  }
}
