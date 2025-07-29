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
  final TextEditingController _problemDescriptionController =
      TextEditingController();
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
          SnackBar(
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
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };
      final response = await http.get(
        Uri.parse('http://16.171.145.59:8000/api/artisans/categories/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> categories = jsonDecode(response.body);
        setState(() {
          _categories = categories.cast<Map<String, dynamic>>();
          _selectedCategoryId = categories.isNotEmpty
              ? categories.first['id']
              : null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to Fetch Categories: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error Occured in Fetching Categories")),
      );
    }
  }

  Future<String?> _refreshToken() async {
    final preference = await SharedPreferences.getInstance();
    final refreshToken = preference.getString('refresh_token');
    if (refreshToken == null) {
      return null;
    }
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
      debugPrint("Error in Refreshing token $e");
      return null;
    }
  }

  Future<void> _readLocationPermission() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
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
      return;
    }
    final bool? allowLocation = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Access to Location is required"),
          content: const Text(
            'Titabi needs acces to your current location to find nearby artisan'
            'Please allow location access.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("No Thanks"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to Find Nearby Mechanics Beacuse Location Access Was Denied",
          ),
        ),
      );
    }
  }

  Future<void> _getCurrentLocationAndHandlePermission() async {
    setState(() {
      _isLoadingLocation = true;
    });
    try {
      var permissionStatus = await Permission.locationWhenInUse.status;
      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        var newPermissionStatus = await Permission.locationWhenInUse.request();
        permissionStatus = newPermissionStatus;
      }
      if (permissionStatus.isGranted) {
        Position readPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );
        setState(() {
          _currentPosition = readPosition;
        });
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            readPosition.latitude,
            readPosition.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark firstPlaceMarker = placemarks[0];
            _currentAddress =
                "${firstPlaceMarker.street}, ${firstPlaceMarker.subLocality}, ${firstPlaceMarker.locality}, ${firstPlaceMarker.country}";
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Location: $_currentAddress")),
            );
          } else {
            _currentAddress = "Address Not Found";
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Location found, but address not converted to Human Readable Form",
                ),
              ),
            );
          }
        } catch (e) {
          _currentAddress = "Error Attempting to Find Address";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error Occured in Finding Location")),
          );
        }
        if (_currentPosition != null && _authToken != null && _userId != null) {
          try {
            String? token = _authToken;
            var requestBody = {
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
            var response = await http
                .post(
                  Uri.parse('http://16.171.145.59:8000/api/jobs/create/'),
                  headers: headers,
                  body: jsonEncode(requestBody),
                )
                .timeout(
                  const Duration(seconds: 30),
                  onTimeout: () {
                    throw TimeoutException('Request Time Out');
                  },
                );

            String responseBody = response.body;
            bool isJson = true;

            try {
              jsonDecode(responseBody);
            } catch (e) {
              isJson = false;
            }
            if (!isJson) {
              responseBody = responseBody.length > 1000
                  ? '${responseBody.substring(0, 1000)}...'
                  : responseBody;
            }

            if (response.statusCode == 401) {
              token = await _refreshToken();
              if (token != null) {
                headers['Authorization'] = 'Bearer $token';
                response = await http
                    .post(
                      Uri.parse('http://16.171.145.59:8000/api/jobs/create/'),
                      headers: headers,
                      body: jsonEncode(requestBody),
                    )
                    .timeout(
                      const Duration(seconds: 30),
                      onTimeout: () {
                        throw TimeoutException(
                          'Request Time Out. You can Try Again Later',
                        );
                      },
                    );
                responseBody = response.body;
                isJson = true;
                try {
                  jsonDecode(responseBody);
                } catch (e) {
                  isJson = false;
                }
                if (!isJson) {
                  responseBody = responseBody.length > 1000
                      ? '${responseBody.substring(0, 1000)}...'
                      : responseBody;
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Session has expired. Try again"),
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
                await Future.delayed(const Duration(seconds: 2));
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
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to create job"),
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
        } else {
          String errorMessage = '';
          if (_currentPosition == null) errorMessage += 'Location is missing.';
          if (_authToken == null) {
            errorMessage += 'Authentication token missing';
          }
          if (_userId == null) errorMessage += 'User Id is missing';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage.isEmpty ? "Error" : errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else if (permissionStatus.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Permission to location is denied. Grant Permission to view artisans",
            ),
            action: SnackBarAction(
              label: 'settings',
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location Time Out. On Your GPS and try again"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error in finding location: $e")));
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Request Mechanic Service",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          children: [
            TextField(
              controller: _problemDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Problem Description',
              ),
            ),
            const SizedBox(height: 20),
            if (_categories.isNotEmpty)
              DropdownButton<int>(
                value: _selectedCategoryId,
                hint: const Text("Select Category"),
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
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _readLocationPermission,
                    child: const Text("Get Location and Request Job"),
                  ),
          ],
        ),
      ),
    );
  }
}
