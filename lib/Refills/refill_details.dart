import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// صفحة تفاصيل إعادة التعبئة (تفاصيل الدواء)
class RefillDetailsPage extends StatefulWidget {
  final Map<String, dynamic> medData; // بيانات الدواء
  final String userId; // UID of the original user (patient)
  final bool isEmergencyContact; // ← NEW: role flag

  const RefillDetailsPage({
    Key? key,
    required this.medData,
    required this.userId,
    this.isEmergencyContact = false,
  }) : super(key: key);

  @override
  _RefillDetailsPageState createState() => _RefillDetailsPageState();
}

class _RefillDetailsPageState extends State<RefillDetailsPage> {
  LatLng _userSavedLocation = const LatLng(0.0, 0.0);
  LatLng? _currentDeviceLocation;
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _loadUserSavedLocation();
    if (!widget.isEmergencyContact) {
      _getCurrentDeviceLocation(); // Only for regular users
    }
  }

  // 📍 Load user location from Firestore
  Future<void> _loadUserSavedLocation() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      var location = userDoc['location'];
      double lat = location['latitude'];
      double lng = location['longitude'];

      setState(() {
        _userSavedLocation = LatLng(lat, lng);
      });

      print("User location loaded: $lat, $lng");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user location: $e')),
        );
      }
    }
  }

  // 📍 Get current device location
  Future<void> _getCurrentDeviceLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentDeviceLocation = LatLng(position.latitude, position.longitude);
      });

      print("Device location: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get device location: $e')),
        );
      }
    }
  }

  // 🔎 Open Google Maps near user (saved) location
  Future<void> _openUserLocationInMaps() async {
    String url =
        "https://www.google.com/maps/search/pharmacy/@${_userSavedLocation.latitude},${_userSavedLocation.longitude},14z";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not open Google Maps');
    }
  }

  // 🔎 Open Google Maps near current device location
  Future<void> _openCurrentLocationInMaps() async {
    if (_currentDeviceLocation == null) {
      _showError("Device location not available");
      return;
    }

    String url =
        "https://www.google.com/maps/search/pharmacy/@${_currentDeviceLocation!.latitude},${_currentDeviceLocation!.longitude},14z";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not open Google Maps');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng mapCenter = widget.isEmergencyContact
        ? _userSavedLocation
        : (_currentDeviceLocation ?? _userSavedLocation);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medData["name"] ?? "Medication Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset("images/drugs.png", width: 100, height: 100),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(Icons.medical_services, "Medication",
                        widget.medData["name"] ?? "Unknown"),
                    _buildDetailRow(Icons.format_list_numbered, "Dosage",
                        widget.medData["dosage"] ?? "Not specified"),
                    _buildDetailRow(Icons.inventory, "Current Inventory",
                        "${widget.medData["currentInventory"] ?? "0"} ${widget.medData["unit"] ?? ""}"),
                    _buildDetailRow(Icons.access_time, "Reminder Time",
                        widget.medData["reminderTimes"] ?? "Not set"),
                    _buildDetailRow(Icons.date_range, "Refill When Inventory <= ",
                        "${widget.medData["remindMeWhen"] ?? "0"} ${widget.medData["unit"] ?? ""}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Find a Nearby Pharmacy",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: mapCenter,
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId("mainLocation"),
                      position: mapCenter,
                      infoWindow: InfoWindow(
                        title: widget.isEmergencyContact
                            ? "User Location"
                            : "Your Location",
                      ),
                    ),
                  },
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),

            if (!widget.isEmergencyContact)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _openCurrentLocationInMaps,
                  icon: const Icon(Icons.my_location),
                  label: const Text("Search Near My Location"),
                ),
              ),

            if (widget.isEmergencyContact)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _openUserLocationInMaps,
                  icon: const Icon(Icons.person_pin_circle),
                  label: const Text("Search Near Patient Location"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
