import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class ArtisanServiceRequest extends StatefulWidget {
  const ArtisanServiceRequest({super.key});

  @override
  State<ArtisanServiceRequest> createState() => _ArtisanServiceRequestState();
}

class _ArtisanServiceRequestState extends State<ArtisanServiceRequest> {
  final TextEditingController _problemDescriptionController = TextEditingController();
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoadingLocation = false;
  String? _userId;
  String? _authToken;
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final preference = await SharedPreferences.getInstance();
    setState(() {
      _userId = preference.getString('user_id');
      _authToken = preference.getString('access_token');
    });
    if (_userId == null || _authToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please login to continue"),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, '/user_login_page');
      }
    } else {
      await _fetchCategories();
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('http://16.171.145.59:8000/api/artisans/categories/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> categories = jsonDecode(response.body);
        setState(() {
          _categories = categories.cast<Map<String, dynamic>>();
          _selectedCategoryId = categories.isNotEmpty ? categories.first['id'] : null;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to fetch categories: ${response.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error fetching categories"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _refreshToken() async {
    final preference = await SharedPreferences.getInstance();
    final refreshToken = preference.getString('refresh_token');
    if (refreshToken == null) return null;
    try {
      final response = await http.post(
        Uri.parse('http://16.171.145.59:8000/api/account/auth/refresh/'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];
        await preference.setString('access_token', newAccessToken);
        setState(() {
          _authToken = newAccessToken;
        });
        return newAccessToken;
      }
      return null;
    } catch (e) {
      print('Error refreshing token: $e');
      return null;
    }
  }

  Future<void> _readLocationPermission() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please enable location services"),
            action: SnackBarAction(
              label: 'Enable',
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
            ),
          ),
        );
      }
      return;
    }
    final bool? allowLocation = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Access to Location is required"),
          content: const Text(
            'Titabi needs access to your current location to find nearby artisans. Please allow location access.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("No Thanks"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Allow Location"),
            ),
          ],
        );
      },
    );
    if (allowLocation == true) {
      _getCurrentLocationAndHandlePermission();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to find nearby artisans because location access was denied"),
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocationAndHandlePermission() async {
    setState(() {
      _isLoadingLocation = true;
    });
    try {
      var permissionStatus = await Permission.locationWhenInUse.status;
      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        permissionStatus = await Permission.locationWhenInUse.request();
      }
      if (permissionStatus.isGranted) {
        Position readPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );
        setState(() {
          _currentPosition = readPosition;
        });
        List<Placemark> placemarks = await placemarkFromCoordinates(
          readPosition.latitude,
          readPosition.longitude,
        );
        setState(() {
          _currentAddress = placemarks.isNotEmpty
              ? "${placemarks[0].street}, ${placemarks[0].subLocality}, ${placemarks[0].locality}, ${placemarks[0].country}"
              : "Address Not Found";
        });
        if (_currentPosition != null && _authToken != null && _userId != null) {
          await _createJobRequest();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _currentPosition == null
                      ? "Location is missing"
                      : "Authentication error",
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Location permission denied. Please grant permission to find artisans"),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching location: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _createJobRequest() async {
    try {
      String? token = _authToken;
      final requestBody = {
        'description': _problemDescriptionController.text.isEmpty
            ? 'Roadside assistance request'
            : _problemDescriptionController.text,
        'lat': _currentPosition!.latitude,
        'lon': _currentPosition!.longitude,
        if (_selectedCategoryId != null) 'category': _selectedCategoryId,
      };
      var headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      var response = await http.post(
        Uri.parse('http://16.171.145.59:8000/api/jobs/create/'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 401) {
        token = await _refreshToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
          response = await http.post(
            Uri.parse('http://16.171.145.59:8000/api/jobs/create/'),
            headers: headers,
            body: jsonEncode(requestBody),
          ).timeout(const Duration(seconds: 30), onTimeout: () {
            throw TimeoutException('Request timed out');
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Session expired. Please log in again"),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pushReplacementNamed(context, '/user_login_page');
          }
          return;
        }
      }
      if (response.statusCode == 201) {
        final job = jsonDecode(response.body);
        if (job['id'] != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Job request created. Waiting for artisan response..."),
                backgroundColor: Colors.green),
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/available_artisans_page',
              arguments: {
                'job_id': job['id'].toString(),
                'latitude': _currentPosition!.latitude,
                'longitude': _currentPosition!.longitude,
                'problem': _problemDescriptionController.text,
                'address': _currentAddress,
                'userId': _userId,
                'authToken': _authToken,
              },
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to create job: ${response.body}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error creating job: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _problemDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Mechanic Service"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _problemDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Problem Description',
                border: OutlineInputBorder(),
                hintText: 'e.g., Flat tire, engine failure',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            if (_categories.isNotEmpty)
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'],
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
            const SizedBox(height: 20),
            _isLoadingLocation
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _readLocationPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      
                    ),
                    child: const Text(
                      "Get Location and Request Job",
                      style: TextStyle(fontSize: 16),
                       
                    ),
                  ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_userId != null && _authToken != null) {
                  Navigator.pushNamed(
                    context,
                    '/driver_job_history',
                    arguments: {
                      'userId': _userId,
                      'authToken': _authToken,
                    },
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                "View Job History",
                style: TextStyle(fontSize: 16),
              ),
            ),
            if (_currentAddress != null) ...[
              const SizedBox(height: 20),
              Text(
                "Current Location: $_currentAddress",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}