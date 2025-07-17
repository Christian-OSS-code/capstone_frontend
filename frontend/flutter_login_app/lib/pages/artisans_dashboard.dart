import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ArtisanDashboardPage extends StatefulWidget {
  const ArtisanDashboardPage({super.key});

  @override
  State<ArtisanDashboardPage> createState() => _ArtisanDashboardPageState();
}

class _ArtisanDashboardPageState extends State<ArtisanDashboardPage> {
  String artisanName = 'John';
  bool _isAvailable = true;
  double overallRating = 3.7;
  int jobCompleted = 289;
  int newJobRequest = 9;

  @override
  void initState() {
    super.initState();
    _processArtisanData();
  }

  Future<void> _processArtisanData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      debugPrint("Data from data base backend");
    });
  }

  void _availabilityStatus(bool? value) {
    setState(() {
      _isAvailable = value ?? false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isAvailable ? "You are now open for jobs" : "You are now offline",
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mechanic DashBoard"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Hi",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Hub for Managing Jobs and your Profile",
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Availability Status",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isAvailable
                              ? "Online and Ready for job"
                              : "Offline. Try again later",
                          style: TextStyle(
                            color: _isAvailable
                                ? Colors.green.shade500
                                : Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isAvailable,
                      onChanged: _availabilityStatus,
                      activeColor: Colors.green.shade400,
                      inactiveThumbColor: Colors.green.shade400,
                      inactiveTrackColor: Colors.green.shade100,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Your Performance at a glance",
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    icon: FontAwesomeIcons.star,
                    color: Colors.purple.shade600,
                    label: "your overall rating",
                    value: overallRating.toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildMetricCard(
                    icon: FontAwesomeIcons.checkCircle,
                    color: Colors.orange.shade600,
                    label: "job completed",
                    value: jobCompleted.toStringAsFixed(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            Text(
              "Quick Actions",
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
                  label: "Manage Profile",
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pushNamed(context, '/user_profile');
                  },
                ),
                _actionButtonCard(
                  context,
                  icon: FontAwesomeIcons.bell,
                  label: "New Job Request",
                  color: Colors.tealAccent,
                  badgeCount: newJobRequest,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Route to a new job")),
                    );
                  },
                ),

                _actionButtonCard(
                  context,
                  icon: FontAwesomeIcons.tasks,
                  label: "My Active Job",
                  color: Colors.blue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Route to a my active jobs"),
                      ),
                    );
                  },
                ),
                _actionButtonCard(
                  context,
                  icon: FontAwesomeIcons.history,
                  label: "Job History",
                  color: Colors.blue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Route to my job history")),
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
              style: TextStyle(color: Colors.blue, fontSize: 14),
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
          padding: EdgeInsets.all(15.0),
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
                        padding: EdgeInsets.all(15.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        constraints: BoxConstraints(
                          minHeight: 20,
                          minWidth: 20,
                        ),
                        child: Text(
                          "$badgeCount",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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
