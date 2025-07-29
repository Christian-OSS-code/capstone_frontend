

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class UserArtisan {
  final String id;
  final String name;
  final List<String> specialities;
  final double distanceKm;
  final double rating;
  final int reviews;
  final int yearsOfExperience;
  final String workShopAddress;
  final String photoUrl;
  final String phoneNumber;

  UserArtisan({
    required this.id,
    required this.name,
    required this.specialities,
    required this.distanceKm,
    required this.rating,
    required this.reviews,
    required this.yearsOfExperience,
    required this.workShopAddress,
    required this.photoUrl,
    required this.phoneNumber,
  });

  factory UserArtisan.fromJson(Map<String, dynamic> json) {
    return UserArtisan(
      id: json['id'].toString(),
      name: json['user']['full_name'] ?? 'Artisan Not Known',
      specialities: List<String>.from(json['skills'] ?? []),
      distanceKm: (json['distance'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: json['rating_count'] ?? 0,
      yearsOfExperience: json['experience_years'] ?? 0,
      workShopAddress: json['work_shop_address'] ?? 'Not Provided',
      photoUrl: json['photo_url'] ?? 'https://via.placeholder.com/150',
      phoneNumber: json['user']['phone_number'] ?? 'Not Available',
    );
  }
}

class AvailableArtisansPage extends StatefulWidget {
  const AvailableArtisansPage({super.key});

  @override
  State<AvailableArtisansPage> createState() => _AvailableArtisansPageState();
}

class _AvailableArtisansPageState extends State<AvailableArtisansPage> {
  bool _isLoading = false;
  String? _jobId;
  String? _problemDescription;
  String? _driverAddress;
  String? _authToken;
  String? _userId;
  double? _latitude;
  double? _longitude;
  List<UserArtisan> _artisans = [];
  String jobStatus = 'pending';
  Map<String, dynamic>? jobDetails;
  Timer? _pollingTimer;
  bool _isTimedOut = false;
  String? _selectedArtisanId;
  final String _baseUrl = "http://16.171.145.59:8000";

  @override
  void initState() {
    super.initState();
    _checkSavedJob();
  }

  Future<void> _checkSavedJob() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJobId = prefs.getString('last_job_id');
    final savedUserId = prefs.getString('user_id');
    final savedAuthToken = prefs.getString('access_token');
    if (savedJobId != null && savedUserId != null && savedAuthToken != null) {
      setState(() {
        _jobId = savedJobId;
        _userId = savedUserId;
        _authToken = savedAuthToken;
      });
      await _fetchJobStatus();
      if (jobStatus == 'pending' ||
          jobStatus == 'accepted' ||
          jobStatus == 'in_progress') {
        await _fetchArtisansDetails();
        if (jobStatus == 'pending') _startPolling();
      } else {
        await prefs.remove('last_job_id');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/driver_job_history_page');
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null &&
        args.containsKey('job_id') &&
        args.containsKey('latitude') &&
        args.containsKey('longitude') &&
        args.containsKey('problem') &&
        args.containsKey('address') &&
        args.containsKey('userId') &&
        args.containsKey('authToken')) {
      setState(() {
        _jobId = args['job_id']?.toString();
        _problemDescription = args['problem'];
        _driverAddress = args['address'];
        _userId = args['userId']?.toString();
        _authToken = args['authToken']?.toString();
        _latitude = args['latitude'] as double?;
        _longitude = args['longitude'] as double?;
      });
      _saveJobId();
      _fetchArtisansDetails();
      if (jobStatus == 'pending') _startPolling();
    } else if (_jobId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid navigation arguments"),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, '/driver_job_history_page');
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

  Future<void> _saveJobId() async {
    if (_jobId != null && _userId != null && _authToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_job_id', _jobId!);
      await prefs.setString('user_id', _userId!);
      await prefs.setString('access_token', _authToken!);
    }
  }

  Future<void> _fetchArtisansDetails() async {
    if (_jobId == null || _authToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Job data is missing"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final artisansResponse = await http.get(
        Uri.parse('$_baseUrl/api/jobs/$_jobId/match/?radius=10'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_authToken',
        },
      );
      if (artisansResponse.statusCode == 200) {
        final List<dynamic> artisanData = jsonDecode(artisansResponse.body);
        setState(() {
          _artisans = artisanData
              .map((json) => UserArtisan.fromJson(json))
              .toList();
        });
      } else if (artisansResponse.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          setState(() {
            _authToken = newToken;
          });
          await _saveJobId();
          await _fetchArtisansDetails();
        } else {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/user_login_page');
          }
        }
      } else {
        print(
          "Failed to fetch artisans: ${artisansResponse.statusCode} - ${artisansResponse.body}",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Failed to fetch artisans: ${artisansResponse.statusCode}",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error fetching artisans: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error fetching artisans: $e"),
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

  Future<void> _suggestArtisans(String artisanId) async {
    if (_jobId == null || _authToken == null) return;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/jobs/$_jobId/suggest/$artisanId/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_authToken',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _selectedArtisanId = artisanId;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Artisan assigned. Waiting for response..."),
              backgroundColor: Colors.green,
            ),
          );
        }
        _startPolling();
      } else if (response.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          setState(() {
            _authToken = newToken;
          });
          await _saveJobId();
          await _suggestArtisans(artisanId);
        } else {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/user_login_page');
          }
        }
      } else {
        print(
          "Failed to suggest artisan: ${response.statusCode} - ${response.body}",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "You have Successfully Requested. Wait For a Response`",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print("Error assigning artisan: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error assigning artisan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearTargetArtisan() async {
    if (_jobId == null || _authToken == null) return;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/jobs/$_jobId/clear-target/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_authToken',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _selectedArtisanId = null;
          _isTimedOut = false;
        });
        await _fetchArtisansDetails();
      } else if (response.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          setState(() {
            _authToken = newToken;
          });
          await _saveJobId();
          await _clearTargetArtisan();
        } else {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/user_login_page');
          }
        }
      } else {
        print(
          "Failed to clear target artisan: ${response.statusCode} - ${response.body}",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to clear target artisan: ${response.body}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error clearing target artisan: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error clearing target artisan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeJob() async {
    if (_jobId == null || _authToken == null) return;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/jobs/$_jobId/update-status/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({'status': 'completed'}),
      );
      if (response.statusCode == 200) {
        setState(() {
          jobStatus = 'completed';
          jobDetails?['status'] = 'completed';
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_job_id');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Job marked as completed"),
              backgroundColor: Colors.green,
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pushReplacementNamed(context, '/driver_job_history_page');
        }
      } else if (response.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          setState(() {
            _authToken = newToken;
          });
          await _saveJobId();
          await _completeJob();
        } else {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/user_login_page');
          }
        }
      } else {
        print(
          "Failed to complete job: ${response.statusCode} - ${response.body}",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to complete job: ${response.body}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error completing job: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error completing job: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchJobStatus() async {
    if (_jobId == null || _authToken == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/jobs/$_jobId/'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Job Status Response: $data');
        setState(() {
          jobStatus = data['status'] ?? 'pending';
          jobDetails = data;
          _selectedArtisanId = data['target_artisan']?['id']?.toString();
        });
        if (jobStatus == 'accepted') {
          _pollingTimer?.cancel();
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('last_job_id');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Your request has been accepted by ${data['artisan']?['full_name'] ?? 'the artisan'}",
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (jobStatus == 'declined') {
          _pollingTimer?.cancel();
          await _clearTargetArtisan();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "The artisan declined your request. Please select another artisan",
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (jobStatus == 'completed' || jobStatus == 'cancelled') {
          _pollingTimer?.cancel();
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('last_job_id');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/driver_job_history_page');
          }
        }
      } else if (response.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          setState(() {
            _authToken = newToken;
          });
          await _saveJobId();
          await _fetchJobStatus();
        } else {
          _pollingTimer?.cancel();
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('last_job_id');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/user_login_page');
          }
        }
      } else {
        print(
          'Failed to fetch job status: ${response.statusCode} - ${response.body}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Failed to fetch job status: ${response.statusCode}",
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching job status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error checking job status: $e")),
        );
      }
    }
  }

  void _startPolling() {
    if (_jobId == null || _authToken == null) return;
    const pollingInterval = Duration(seconds: 10);
    const timeoutDuration = Duration(minutes: 10);
    int elapsedSeconds = 0;

    _pollingTimer = Timer.periodic(pollingInterval, (timer) async {
      if (elapsedSeconds >= timeoutDuration.inSeconds || !mounted) {
        timer.cancel();
        await _clearTargetArtisan();
        setState(() {
          _isTimedOut = true;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "The artisan did not respond to your request. Please select another artisan",
              ),
              backgroundColor: Colors.red,
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          setState(() {
            _isTimedOut = false;
          });
          await _fetchArtisansDetails();
        }
        return;
      }
      await _fetchJobStatus();
      elapsedSeconds += pollingInterval.inSeconds;
    });
  }

  Future<void> _handlePhoneCalls(String phoneNumber) async {
    if (phoneNumber == 'Not Available') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Artisan phone number not available"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final Uri launchUriCall = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUriCall)) {
      await launchUrl(launchUriCall);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Call Failed")));
      }
    }
  }

  void _handleChats(UserArtisan artisan) {
    if (mounted) {
      Navigator.pushNamed(
        context,
        "/user_chat_page",
        arguments: {
          'artisanId': artisan.id,
          'artisanName': artisan.name,
          'userId': _userId,
          'authToken': _authToken,
        },
      );
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Available Artisans"),
        backgroundColor: Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/driver_job_history_page');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18.0),
            color: Colors.orangeAccent,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Problem Details:",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Location: ${_driverAddress ?? 'N/A'}",
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                ),
                Text(
                  "Problem Description: ${_problemDescription ?? 'N/A'}",
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                ),
                Text(
                  "Status: $jobStatus",
                  style: TextStyle(
                    color: jobStatus == 'accepted'
                        ? Colors.green
                        : jobStatus == 'declined'
                        ? Colors.red
                        : Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (jobDetails?['artisan'] != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    "Assigned Artisan: ${jobDetails!['artisan']['full_name'] ?? 'N/A'}",
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                ],
                if (jobStatus == 'accepted') ...[
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _completeJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Mark Job as Completed"),
                  ),
                ],
                const SizedBox(height: 10),
                const Text(
                  "Nearby Mechanics",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isTimedOut
                ? const Center(
                    child: Text(
                      "Request timed out. Please select another artisan...",
                    ),
                  )
                : _artisans.isEmpty
                ? const Center(child: Text("No nearby artisans"))
                : ListView.builder(
                    padding: const EdgeInsets.all(10.0),
                    itemCount: _artisans.length,
                    itemBuilder: (context, index) {
                      final artisan = _artisans[index];
                      final isSelected = _selectedArtisanId == artisan.id;
                      final isAssigned =
                          jobDetails?['artisan']?['id']?.toString() ==
                          artisan.id;
                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 5.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Color(0xFFD4AF37), width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.grey.shade300,
                                    backgroundImage: CachedNetworkImageProvider(
                                      artisan.photoUrl,
                                    ),
                                    onBackgroundImageError:
                                        (exception, stackTrace) {
                                          print(
                                            "Error loading image: $exception",
                                          );
                                        },
                                    child: artisan.photoUrl.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 40,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          artisan.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              color: Colors.amber.shade700,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              "${artisan.rating.toStringAsFixed(1)} (${artisan.reviews} reviews)",
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Text(
                                              "${artisan.distanceKm.toStringAsFixed(1)} km away",
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 25, thickness: 1),
                              const Text(
                                "Specialties",
                                style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: artisan.specialities.map((skill) {
                                  return Chip(
                                    label: Text(skill),
                                    backgroundColor: Colors.blue.shade100,
                                    labelStyle: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontSize: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: Colors.blue.shade200,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Icon(
                                    Icons.work,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "${artisan.yearsOfExperience} Years Experience",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Workshop: ${artisan.workShopAddress}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              // Row(
                              //   crossAxisAlignment: CrossAxisAlignment.start,
                              //   children: [
                              //     Expanded(
                              //       child: ElevatedButton.icon(
                              //         onPressed:
                              //             jobStatus == 'accepted' && isAssigned
                              //             ? () => _handlePhoneCalls(
                              //                 artisan.phoneNumber,
                              //               )
                              //             : null,
                              //         icon: const Icon(
                              //           Icons.phone,
                              //           color: Colors.white,
                              //         ),
                              //         label: const Text(
                              //           "Call",
                              //           style: TextStyle(
                              //             color: Colors.white,
                              //             fontSize: 16,
                              //           ),
                              //         ),
                              //         style: ElevatedButton.styleFrom(
                              //           padding: const EdgeInsets.symmetric(
                              //             vertical: 15,
                              //           ),
                              //           backgroundColor: Colors.green.shade600,
                              //           shape: RoundedRectangleBorder(
                              //             borderRadius: BorderRadius.circular(
                              //               15,
                              //             ),
                              //           ),
                              //         ),
                              //       ),
                              //     ),
                              //     const SizedBox(width: 10),
                              //     Expanded(
                              //       child: ElevatedButton.icon(
                              //         onPressed:
                              //             jobStatus == 'accepted' && isAssigned
                              //             ? () => _handleChats(artisan)
                              //             : null,
                              //         icon: const Icon(
                              //           Icons.chat,
                              //           color: Colors.white,
                              //         ),
                              //         label: const Text(
                              //           "Chat",
                              //           style: TextStyle(
                              //             color: Colors.white,
                              //             fontSize: 16,
                              //           ),
                              //         ),
                              //         style: ElevatedButton.styleFrom(
                              //           padding: const EdgeInsets.symmetric(
                              //             vertical: 15,
                              //           ),
                              //           backgroundColor: Colors.blue.shade600,
                              //           shape: RoundedRectangleBorder(
                              //             borderRadius: BorderRadius.circular(
                              //               15,
                              //             ),
                              //           ),
                              //         ),
                              //       ),
                              //     ),
                              //     const SizedBox(width: 10),
                              //     Expanded(
                              //       child: ElevatedButton.icon(
                              //         onPressed:
                              //             (jobStatus == 'pending' &&
                              //                 !isAssigned)
                              //             ? () => _suggestArtisans(artisan.id)
                              //             : null,
                              //         icon: const Icon(
                              //           Icons.check,
                              //           color: Colors.white,
                              //         ),
                              //         label: Text(
                              //           isAssigned ? "Assigned" : "Request",
                              //           style: const TextStyle(
                              //             color: Colors.white,
                              //             fontSize: 16,
                              //           ),
                              //         ),
                              //         style: ElevatedButton.styleFrom(
                              //           padding: const EdgeInsets.symmetric(
                              //             vertical: 15,
                              //           ),
                              //           backgroundColor: isAssigned
                              //               ? Colors.grey
                              //               : Colors.orange.shade600,
                              //           shape: RoundedRectangleBorder(
                              //             borderRadius: BorderRadius.circular(
                              //               15,
                              //             ),
                              //           ),
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Call Button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _handlePhoneCalls(
                                        artisan.phoneNumber,
                                      ),
                                      icon: const Icon(
                                        Icons.phone,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        "Call",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        backgroundColor: Colors.green.shade600,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Chat Button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _handleChats(artisan),
                                      icon: const Icon(
                                        Icons.chat,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        "Chat",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        backgroundColor: Colors.blue.shade600,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Request/Assigned Button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          (jobStatus == 'pending' &&
                                              !isAssigned)
                                          ? () => _suggestArtisans(artisan.id)
                                          : null,
                                      icon: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        isAssigned ? "Assigned" : "Request",
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        backgroundColor: isAssigned
                                            ? Colors.grey
                                            : Colors.orange.shade600,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (jobStatus == 'pending' && _selectedArtisanId != null)
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                "Waiting for artisan to respond... (10-minute timeout)",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
