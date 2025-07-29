import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ArtisanProfileCreation extends StatefulWidget {
  final String authToken;
  final String userId;
  const ArtisanProfileCreation({
    super.key,
    required this.authToken,
    required this.userId,
  });

  @override
  State<ArtisanProfileCreation> createState() => _ArtisanProfileCreationState();
}

class _ArtisanProfileCreationState extends State<ArtisanProfileCreation> {
  final GlobalKey<FormState> _artiansProfileKey = GlobalKey();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _experienceYearsController =
      TextEditingController();
  final TextEditingController _newSpecializationController =
      TextEditingController();

  final RegExp _validEmail = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final RegExp _validPhoneNumber = RegExp(r'^\+?[1-9]\d{5,14}$');

  bool _isSavingProfile = false;
  bool _isInitialDataLoading = true;
  bool _isArtisan = false;

  String? _userId;
  String? _authToken;

  List<String> _selectedSpecializations = [];
  ArtisanCategory? _selectedCategory;
  List<ArtisanCategory> _artisanCategories = [];

  final String _baseUrl = 'http://16.171.145.59:8000';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _retrieverArgumentsAndLoadProfile();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _locationController.dispose();
    _experienceYearsController.dispose();
    _newSpecializationController.dispose();
    super.dispose();
  }

  void _retrieverArgumentsAndLoadProfile() async {
    final credential =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
    if (credential != null &&
        credential.containsKey('userId') &&
        credential.containsKey('authToken')) {
      setState(() {
        _userId = credential['userId'];
        _authToken = credential['authToken'];
      });

      await _fetchArtisanCategories();
      await _loadUserProfileFromBackend();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Authentication details missing"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isInitialDataLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/user_login_page');
      }
    }
  }

  Future<void> _fetchArtisanCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/artisans/categories/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _artisanCategories = data
              .map((json) => ArtisanCategory.fromJson(json))
              .toList();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to load categories: ${response.body}"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading categories: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _reverseGeoCodingCoordinates(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);

      if (placemarks.isNotEmpty) {
        Placemark initialLocation = placemarks.first;
        setState(() {
          _locationController.text =
              "${initialLocation.street}, ${initialLocation.subLocality}, ${initialLocation.locality}, ${initialLocation.country}";
        });
      }
    } catch (e) {
      debugPrint("Error in geocoding: $e");
      setState(() {
        _locationController.text = "Cannot find address";
      });
    }
  }

  Future<Map<String, double>?> _geocodingAddress(
    String geocodingAddress,
  ) async {
    try {
      List<Location> address = await locationFromAddress(geocodingAddress);

      if (address.isNotEmpty) {
        Location firstLocation = address.first;
        return {
          "latitude": firstLocation.latitude,
          "longitude": firstLocation.longitude,
        };
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Geocoding location failed: ${e.toString()}")),
        );
      }
      return null;
    }
  }

  Future<void> _loadUserProfileFromBackend() async {
    if (_userId == null || _authToken == null) {
      setState(() {
        _isInitialDataLoading = false;
      });
      Navigator.pushReplacementNamed(context, '/user_login_page');
      return;
    }
    try {
      final userResponse = await http.get(
        Uri.parse('$_baseUrl/api/accounts/me/'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );
      if (userResponse.statusCode == 200) {
        final Map<String, dynamic> userData = jsonDecode(userResponse.body);
        setState(() {
          _firstNameController.text = userData['first_name'] ?? '';
          _lastNameController.text = userData['last_name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneNumberController.text = userData['phone_number'] ?? '';
          _isArtisan = userData['is_artisan'] ?? false;
          _isInitialDataLoading = false;
        });

        if (!_isArtisan) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Redirecting to job history...")),
            );
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/artisan_service_request',
                arguments: {'authToken': _authToken, 'userId': _userId},
              );
            }
            return;
          }
        }
        final profileResponse = await http.get(
          Uri.parse('$_baseUrl/api/artisans/profile/'),
          headers: {'Authorization': 'Bearer $_authToken'},
        );

        if (profileResponse.statusCode == 200) {
          final Map<String, dynamic> artisanData = jsonDecode(
            profileResponse.body,
          );
          setState(() {
            _experienceYearsController.text =
                (artisanData['experience_years'] ?? 0).toString();
            if (artisanData['location'] != null &&
                artisanData['location']['coordinates'] != null) {
              final List<dynamic> points =
                  artisanData['location']['coordinates'];
              _reverseGeoCodingCoordinates(points[1], points[0]);
            } else {
              _locationController.text = '';
            }
            final int? categoryId = artisanData['category'];
            if (categoryId != null) {
              _selectedCategory = _artisanCategories.firstWhere(
                (section) => section.id == categoryId,
                orElse: () => _artisanCategories.isNotEmpty
                    ? _artisanCategories.first
                    : ArtisanCategory(id: -1, name: "unknown", specialties: []),
              );
            }
            _selectedSpecializations = List<String>.from(
              artisanData['skill_names'] ?? [],
            );
          });
        } else if (profileResponse.statusCode != 404) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Profile failed to load: ${profileResponse.body}",
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Profile failed to load: ${userResponse.body}"),
            ),
          );
          Navigator.pushReplacementNamed(context, '/user_login_page');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile loading error: ${e.toString()}")),
        );
        Navigator.pushReplacementNamed(context, '/user_login_page');
      }
    }
  }

  void _addArtisanSpecialties() {
    final String newSkill = _newSpecializationController.text.trim();
    if (newSkill.isNotEmpty && !_selectedSpecializations.contains(newSkill)) {
      setState(() {
        _selectedSpecializations.add(newSkill);
        _newSpecializationController.clear();
      });
    } else if (newSkill.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have already added this specialty")),
      );
    }
  }

  void _removeArtisanSpecialty(String specialty) {
    setState(() {
      _selectedSpecializations.remove(specialty);
    });
  }

  Future<void> _saveArtisanProfile() async {
    if (_isArtisan) {
      if (_locationController.text.trim().isEmpty ||
          _selectedSpecializations.isEmpty ||
          _selectedCategory == null ||
          _experienceYearsController.text.trim().isEmpty ||
          int.tryParse(_experienceYearsController.text.trim()) == null) {
        _artiansProfileKey.currentState?.validate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "specialties, years of experience and location must be filled",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
    if (!(_artiansProfileKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_userId == null || _authToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No authentication token"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    setState(() {
      _isSavingProfile = true;
    });
    try {
      final Map<String, dynamic> updateData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneNumberController.text.trim(),
      };
      final userResponse = await http.patch(
        Uri.parse('$_baseUrl/api/accounts/me/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(updateData),
      );
      if (userResponse.statusCode != 200) {
        throw Exception(
          jsonDecode(userResponse.body)['detail'] ?? "Profile update failed",
        );
      }

      if (_isArtisan) {
        final String workShopAddress = _locationController.text.trim();
        final int experienceYears = int.parse(
          _experienceYearsController.text.trim(),
        );
        Map<String, dynamic>? geoLocationCoordinates = await _geocodingAddress(
          workShopAddress,
        );
        if (geoLocationCoordinates == null) {
          throw Exception("coordinates of workshop failed");
        }
        final Map<String, dynamic> artisanProfileUpdateInfo = {
          'category': _selectedCategory!.id,
          'skills': _selectedSpecializations,
          'experience_years': experienceYears,
          'latitude': geoLocationCoordinates['latitude'],
          'longitude': geoLocationCoordinates['longitude'],
        };
        final artisanResponse = await http.patch(
          Uri.parse('$_baseUrl/api/artisans/profile/'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $_authToken',
          },
          body: jsonEncode(artisanProfileUpdateInfo),
        );
        if (artisanResponse.statusCode != 200) {
          throw Exception(
            jsonDecode(artisanResponse.body)['detial'] ??
                "Profile update failed",
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArtisan ? "Artisan Profile Saved" : "profile saved",
            ),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            _isArtisan ? '/artisan_dashboard' : '/artisan_service_request',

            arguments: {'userId': _userId!, 'authToken': _authToken!},
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("An error occured"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          _isArtisan
              ? "Complete Your Artisan Profile"
              : "Complete Your Profile",
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 5,

        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (value) {
            if (value == 'dashboard') {
              Navigator.pushReplacementNamed(
                context,
                '/artisan_dashboard',
                arguments: {
                  'authToken': widget.authToken,
                  'userId': widget.userId,
                },
              );
            } else if (value == 'home') {
              Navigator.pushReplacementNamed(
                context,
                '/my_home_page',
                arguments: {
                  'authToken': widget.authToken,
                  'userId': widget.userId,
                },
              );
            }
          },
          itemBuilder: (BuildContext context) =>[
            const PopupMenuItem(
              value: 'dashboard',
              child: Text('Artisan Dashboard')),
              const PopupMenuItem<String>(
                value: 'home',

                child: Text('Home Page')),
          ],
        ),
      ),
      body: _isInitialDataLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 25),
                  CircularProgressIndicator(),
                  Text("Profile loading..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _artiansProfileKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "User ID: ${_userId ?? "N/A"}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isArtisan
                          ? "You are logged in as an Artisan"
                          : "You are logged in as a Driver",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _firstNameController,
                      labelText: "First Name",
                      hintText: "e.g., christian",
                      icon: Icons.person,

                      validator: (value) => value == null || value.isEmpty
                          ? "First name cannot be empty"
                          : null,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _lastNameController,
                      labelText: "Last Name",
                      hintText: "e.g., Ikwu",
                      icon: Icons.person_outline,

                      validator: (value) => value == null || value.isEmpty
                          ? "Last name cannot be empty"
                          : null,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _emailController,
                      labelText: "Email",
                      hintText: "e.g., chris@example.com",
                      icon: Icons.email,

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "First name cannot be empty";
                        }
                        if (!_validEmail.hasMatch(value)) {
                          return "Incorrect Email. Enter a valid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _phoneNumberController,
                      labelText: "Phone Number",
                      hintText: "e.g., +234...",
                      icon: Icons.phone,

                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d+()]')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Phone number cannot be empty";
                        }
                        final cleanedValue = value.replaceAll(
                          RegExp(r'(?!^\+)[^\d]'),
                          '',
                        );
                        if (!_validPhoneNumber.hasMatch(cleanedValue)) {
                          return "Incorrect Phone Number. Enter a valid Phone Number";
                        }
                        return null;
                      },
                    ),
                    if (_isArtisan) ...[
                      const SizedBox(height: 30),
                      const Text(
                        "Provide Your Details",
                        style: TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildSpecializationCard(
                        title: "Required Field",
                        children: [
                          DropdownButtonFormField<ArtisanCategory>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: "Select Category",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: _artisanCategories.map((category) {
                              return DropdownMenuItem<ArtisanCategory>(
                                value: category,
                                child: Text(category.name),
                              );
                            }).toList(),
                            onChanged: (ArtisanCategory? newValue) {
                              setState(() {
                                _selectedCategory = newValue;
                                _selectedSpecializations = [];
                              });
                            },
                            validator: (value) => value == null
                                ? "required details are empty"
                                : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _locationController,
                        labelText: "Workshop Address",
                        hintText: "e.g., 314 Herbert Macaulay Way, Yaba, Lagos",
                        icon: Icons.location_on,
                        validator: (value) => value == null || value.isEmpty
                            ? "workshop address is required"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _experienceYearsController,
                        labelText: "Years of Experience",
                        hintText: "e.g., 3",
                        icon: Icons.numbers,

                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Years of Experience is Required";
                          }
                          if (int.tryParse(value) == null) {
                            return "Enter a number";
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildSpecializationCard(
                        title: "Specialties/Skills",
                        children: [
                          const Text(
                            "Add at least one skill",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _newSpecializationController,
                                  labelText: "Add Specialization",
                                  hintText: "e.g., Engine Diagnostics",
                                  icon: Icons.build,
                                  onSubmitted: (value) =>
                                      _addArtisanSpecialties(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: _addArtisanSpecialties,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0XFFFF7F11),
                                  padding: const EdgeInsets.all(15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_selectedSpecializations.isNotEmpty)
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: _selectedSpecializations
                                  .map(
                                    (skill) => Chip(
                                      label: Text(skill),
                                      deleteIcon: const Icon(Icons.close),
                                      onDeleted: () =>
                                          _removeArtisanSpecialty(skill),
                                      backgroundColor: Color(0xFFE3F2FD),
                                      labelStyle: TextStyle(
                                        color: Color(0xFF1976D2),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),

                                        side: BorderSide(
                                          color: Color(0xFFBBDEFB),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          if (_selectedSpecializations.isEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                "Add at least one specialization.",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSavingProfile
                            ? null
                            : _saveArtisanProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 124, 143, 124),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isSavingProfile
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                "Save Profile",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    required IconData icon,
    String? Function(String?)? validator,
    ValueChanged<String>? onSubmitted,
    List<TextInputFormatter>? inputFormatters,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    bool isOptional = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            labelText: labelText + (isOptional ? "(optional)" : ""),
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.grey.shade600),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildSpecializationCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20, thickness: 1, color: Color(0XFFE0E0E0)),
            ...children,
          ],
        ),
      ),
    );
  }
}

class ArtisanCategory {
  final int id;
  final String name;
  final List<ArtisanSkill> specialties;

  ArtisanCategory({
    required this.id,
    required this.name,
    required this.specialties,
  });

  factory ArtisanCategory.fromJson(Map<String, dynamic> json) {
    var listOfSkills = json['skills'] as List;
    List<ArtisanSkill> skills = listOfSkills
        .map((i) => ArtisanSkill.fromJson(i))
        .toList();

    return ArtisanCategory(
      id: json['id'],
      name: json['name'],
      specialties: skills,
    );
  }
}

class ArtisanSkill {
  final int id;
  final String name;

  ArtisanSkill({required this.id, required this.name});
  factory ArtisanSkill.fromJson(Map<String, dynamic> json) {
    return ArtisanSkill(id: json['id'], name: json['name']);
  }
}
