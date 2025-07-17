import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UserArtisan {
  final String id;
  final String name;
  final String photoUrl;
  final List<String> specialties;
  final String phoneNumber;
  final double longitude;
  final double latitude;
  final double rating;
  final int reviews;
  final double distanceKm;
  final int yearsOfExperience;
  final String workShopAddress;

  UserArtisan({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.specialties,
    required this.phoneNumber,
    required this.longitude,
    required this.latitude,
    required this.rating,
    required this.reviews,
    required this.distanceKm,
    required this.yearsOfExperience,
    required this.workShopAddress,
  });
}

List<UserArtisan> availableMechanics = [
  UserArtisan(
    id: 'mech001',
    name: 'Oga John AutoCare',
    photoUrl: 'http://placehold.co/dhjfdhjd',
    specialties: ['Engine Repair', 'Brakes', 'Diagnostics'],
    phoneNumber: '08135417002',
    longitude: 6.5055,
    latitude: 3.3810,
    rating: 4.7,
    reviews: 125,
    distanceKm: 4.5,
    yearsOfExperience: 3,
    workShopAddress: "Opposite the White House",
  ),

  UserArtisan(
    id: 'mech002',
    name: 'Joe White Electricals',
    photoUrl: 'https://placeholder',
    specialties: ['ELectricals', 'AC Repair', 'Towing Service'],
    phoneNumber: '08168292905',
    longitude: 10.3489,
    latitude: 5.812,
    rating: 4.9,
    reviews: 98,
    distanceKm: 45,
    yearsOfExperience: 2,
    workShopAddress: "Opposite Goshen",
  ),
  UserArtisan(
    id: 'mech003',
    name: 'Johnsons Pannel Beater',
    photoUrl: 'https//placeholder',
    specialties: ['pannel beatinfg', 'spraying', 'tyres'],
    phoneNumber: '08135417002',
    longitude: 7.43,
    latitude: 4.901,
    rating: 3.2,
    reviews: 61,
    distanceKm: 9.5,
    yearsOfExperience: 1,
    workShopAddress: "Behind Mobile",
  ),
];

class AvailableArtisanPage extends StatefulWidget {
  const  AvailableArtisanPage ({super.key});

  @override
  State< AvailableArtisanPage> createState() => _AvailableArtisanPageState();
}

class _AvailableArtisanPageState extends State<AvailableArtisanPage> {
  String? problemDescription;
  String? driverAddress;
  double? driverLongitude;
  double? driverLatitude;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map<String, dynamic>? driverMapper =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (driverMapper != null) {
      problemDescription = driverMapper["problem"];
      driverAddress = driverMapper["address"];
      driverLongitude = driverMapper["longitude"];
      driverLatitude = driverMapper["latitude"];
    }
  }

  Future<void> _handlePhoneCalls(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Could not make a call")));
    }
  }

  void _handleChats(UserArtisan userArtisan) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Chat with ${userArtisan.name}")));
    Navigator.pushNamed(context, "/chat_page", arguments: userArtisan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Available Mechanics"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18.0),
            color: Colors.blueAccent.shade200,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Problem Details: ",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Location: ${driverAddress ?? "N/A"}",
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                ),
                Text(
                  "Problem Description: ${problemDescription ?? "N/A"}",
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Meet Mechanic Near You",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: availableMechanics.length,
              itemBuilder: (context, index) {
                final artisan = availableMechanics[index];
                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 5.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
                              onBackgroundImageError: (exception, stackTrace) {
                                debugPrint("Error loading image: $exception");
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    artisan.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            color: Colors.amber.shade700,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            "${artisan.rating.toStringAsFixed(1)}  (${artisan.reviews}) reviews",
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
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
                          "specialties",
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
                          children: artisan.specialties.map((skill) {
                            return Chip(
                              label: Text(skill),
                              backgroundColor: Colors.blue.shade50,
                              labelStyle: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.blue.shade200),
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
                              "${artisan.yearsOfExperience} Years Expereince",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _handlePhoneCalls(artisan.phoneNumber),
                                icon: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Call",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleChats(artisan),
                                icon: const Icon(
                                  Icons.chat,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Chat",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  backgroundColor: Colors.blue.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
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
        ],
      ),
    );
  }
}
