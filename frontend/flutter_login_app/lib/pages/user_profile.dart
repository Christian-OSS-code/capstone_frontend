import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

class UserProfileCreation extends StatefulWidget {
  const UserProfileCreation({super.key});

  @override
  State<UserProfileCreation> createState() => _UserProfileCreationState();
}

class _UserProfileCreationState extends State<UserProfileCreation> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final RegExp _validPhoneNumber = RegExp(r'^\+?[1-9]\d{5,14}$');

  bool _isArtisan = false;
  bool _isUserCredentialLoading = true;

  String? _userId;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _retrieveArgumentsAndLoadProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _retrieveArgumentsAndLoadProfile() {
    final credential =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
    if (credential != null &&
        credential.containsKey('userId') &&
        credential.containsKey('authToken')) {
      setState(() {
        _userId = credential['userId'];
        _authToken = credential['authToken'];
      });
      debugPrint("User Id: $_userId, authToken: $_authToken");
      _loadUserProfile();
    } else {
      debugPrint("UserId or authToken not provided");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Missing auth details"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isUserCredentialLoading = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    if (_userId == null || _authToken == null) {
      debugPrint("Cannot load profile");
      setState(() {
        _isUserCredentialLoading = false;
      });
      return;
    }
    setState(() {
      _isUserCredentialLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));
      if (_userId == 'freshUser') {
        setState(() {
          _nameController.text = "Christian Ikwu";
          _emailController.text = "christianmary2020@gmail.com";
          _phoneNumberController.text = "09023456781";
          _locationController.text = "Yaba, Lagos, Nigeria";
          _isArtisan = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Loading failed")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUserCredentialLoading = false;
        });
      }
    }
  }

  Future<Map<String, double>> _reverseGeocodingFromHumanAddressToCoordinate(
    String address,
  ) async {
    List<Location> locations = await locationFromAddress(address);

    Location initialLocation = locations.first;

    return {
      "latitude": initialLocation.latitude,
      "longitude": initialLocation.longitude,
    };
  }

  Future<void> _saveUserProfile() async {
    if (_userId == null || _authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save profile"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _isUserCredentialLoading = true;
    });
    try {
      final String name = _nameController.text.trim();
      final String email = _emailController.text.trim();
      final String phoneNumber = _phoneNumberController.text.trim();
      final String location = _locationController.text.trim();

      final Map<String, double> geoLocationCoordinates =
          await _reverseGeocodingFromHumanAddressToCoordinate(location);

     
      final Map<String, dynamic> profileInfo = {
        'userId': _userId,
        'name': name,
        'email': email,
        'phone': phoneNumber,
        'locationHumanReadable': location,
        'locationLongitude': geoLocationCoordinates['longitude'],
        'locationLatitude': geoLocationCoordinates['latitude'],
      };
      await Future.delayed(const Duration(seconds: 5));

      if (name.isEmpty ||
          email.isEmpty ||
          phoneNumber.isEmpty ||
          location.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields are required")),
        );
        setState(() {
          _isUserCredentialLoading = false;
        });
        return;
      }
      if (!_validPhoneNumber.hasMatch(
        phoneNumber.replaceAll(RegExp(r'(?!^\+)[^\d]'), ''),
      )) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Provide a valid phone number")));
        setState(() {
          _isUserCredentialLoading = false;
        });
        return;
      }
      await Future.delayed(const Duration(seconds: 5));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile created successfully"),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) {
        if (_isArtisan) {
          debugPrint(
            "longitude: ${geoLocationCoordinates['longitude']}, latitude: ${geoLocationCoordinates['latitude']}",
          );
          Navigator.pushReplacementNamed(context, '/artisans_dashboard');
        } else {
          Navigator.pushNamed(context, '/mechanic_service_request');
        }
      }
    } catch (e) {
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(

            content: Text("Profile couldn't save"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUserCredentialLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Your Profile"),
        backgroundColor: Colors.blueAccent,
        elevation: 6,
      ),
      body: _isUserCredentialLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Profile Loading..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "User ID: ${_userId ?? "N/A"}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Provide Your Information",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(
                      labelText: "Enter your full names",
                      hintText: "e.g John Kongo",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Enter last email",
                      hintText: "e.g Kongo@example.com",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Enter your phone number",
                      hintText: "e.g +2348135417002",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "phone number cannot be empty";
                      }
                      final cleanedValue = value.replaceAll(
                        RegExp(r'(?!^\+)[^\d]'),
                        '',
                      );
                      if (!_validPhoneNumber.hasMatch(cleanedValue)) {
                        return "Enter a valid phone number";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _locationController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Enter your workshop address",
                      hintText: "e.g 314 Albert Macauly, Way Yaba, Lagos",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Register as an Artisan",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: _isArtisan,
                        onChanged: (bool value) {
                          setState(() {
                            _isArtisan = value;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? "You are registering as an Artisan"
                                    : "You are registering as a driver",
                              ),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        },
                        activeColor: Colors.green.shade600,
                        inactiveThumbColor: Colors.grey.shade600,
                        inactiveTrackColor: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUserCredentialLoading
                          ? null
                          : _saveUserProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),

                      child: _isUserCredentialLoading
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator(
                                color: Colors.green,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              "Saved profile",
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
