import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MechanicServiceRequest extends StatefulWidget {
  const MechanicServiceRequest({super.key});

  @override
  State<MechanicServiceRequest> createState() => _MechanicServiceRequestState();
}

class _MechanicServiceRequestState extends State<MechanicServiceRequest> {
  final TextEditingController _problemDescriptionController =
      TextEditingController();
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _problemDescriptionController.dispose();
    super.dispose();
  }

  Widget buildFeatureAboutUs(
    IconData iconData,
    String title,
    String serviceDescription,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(iconData, color: Colors.blue.shade900, size: 20),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              serviceDescription,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _readLocationPermission() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enable location service on your device"),
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
          title: const Text('Location Access Required'),
          content: const Text(
            'FiXam needs access to your current location to find nearby mechanics. '
            'Please allow location access.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false); 
              },
              child: const Text('No, Thanks'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true); 
              },
              child: const Text('Allow Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, 
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
    if (allowLocation == true) {
      _getCurrentLocationAndHandlePermission();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location access denied. Cannot find nearby mechanics"),
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
          desiredAccuracy: LocationAccuracy.high,
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
            debugPrint("Human readable address $_currentAddress");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Location: $_currentAddress")),
            );
          } else {
            _currentAddress = "Address not found";
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Location found, but address ${readPosition.latitude} and ${readPosition.longitude}",
                ),
              ),
            );
          }
        } catch (e) {
          _currentAddress = "Error when attempting to find address";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error in finding address, but location found"),
            ),
          );
        }
        if (_currentPosition != null &&
            _currentPosition!.latitude != null &&
            _currentPosition!.longitude != null) {
          Navigator.pushNamed(
            context,
            "/mechanic_service_request",
            arguments: {
              'latitiude': _currentPosition!.latitude,
              'longitude': _currentPosition!.longitude,
              'problem': _problemDescriptionController.text,
              'address': _currentAddress,
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Location search failed. Please, try again"),
            ),
          );
        }
      } else if (permissionStatus.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Location permission is denied. Please grant permission",
            ),
          ),
        );
      } else if (permissionStatus.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Location permission is denied. Please grant permission",
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
    } on TimeoutException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Location permission is denied. Please grant permission",
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext content) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Driver DashBoard"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: const Offset(0, 8),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/connect_to_nearest_mechanic");
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                child: Column(
                  children: [
                    Text(
                      "Ready to Get Help?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Your RoadSide Mechanic, just a Tap Away.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5,
                    spreadRadius: 3,
                    color: Colors.grey.withOpacity(0.3),
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _problemDescriptionController,
                decoration: InputDecoration(
                  hintText:
                      "Describe your problem(e.g., flat tyre, battery issue)",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 20,
                  ),
                  prefixIcon: Icon(
                    Icons.car_repair,
                    color: Colors.blue.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: const Offset(0, 8),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [Colors.orange.shade700, Colors.orange.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: TextButton(
                onPressed: _isLoadingLocation ? null : _readLocationPermission,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                child: _isLoadingLocation
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const <Widget>[
                          FaIcon(
                            FontAwesomeIcons.mapMarkerAlt,
                            color: Colors.white,
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Get My Location",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),    
            Text(
              "Our Services",
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Column(
              children: <Widget>[
                buildFeatureAboutUs(
                  Icons.location_on,
                  "Detect Instance Location",
                  "We find your exact location automatically so you don't need to type it in",
                ),
                buildFeatureAboutUs(
                  Icons.directions_car,
                  "Fast Mechanic Dispatch",
                  "Connects you to the nearest available and verified mechanic",
                ),
                buildFeatureAboutUs(
                  Icons.chat,
                  "Direct Communication",
                  "Chat with your assigned mechanic in real-time for updates and coordination",
                ),
                buildFeatureAboutUs(
                  Icons.security,
                  "Secure and Reliable Service",
                  "Enjoy a peace of mind and a quality serivice with trusted mechanic and transparent pricing",
                ),
              ],
            ),
            const SizedBox(height: 40),

            Text(
              "What do we Owe You?",
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                children: <Widget>[
                  buildFeatureAboutUs(
                    Icons.access_time_filled,
                    "24/7 Availability",
                    "Roadside assitance is available round the clock",
                  ),
                  buildFeatureAboutUs(
                    Icons.star_rate,
                    "Highly Rated Professionals",
                    "Connects with other mechanics who have been highly vetted, verified and reviewed",
                  ),
                  buildFeatureAboutUs(
                    Icons.price_check,
                    "Transparent Pricing",
                    "No hidden fees, know the cost upfront before service begins",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
