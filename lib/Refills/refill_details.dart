import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class RefillDetailsPage extends StatefulWidget {
  final Map<String, dynamic> medData;

  const RefillDetailsPage({Key? key, required this.medData}) : super(key: key);

  @override
  _RefillDetailsPageState createState() => _RefillDetailsPageState();
}

class _RefillDetailsPageState extends State<RefillDetailsPage> {
  late LatLng _medLocation;
  Position? _currentPosition;
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();


    final lat = widget.medData['latitude'] ?? 0.0;
    final lng = widget.medData['longitude'] ?? 0.0;
    _medLocation = LatLng(lat, lng);


    _getCurrentLocation();
  }


  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = position;
      });


      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          }
        });
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }


  Future<void> _openGoogleMaps() async {
    String url =
        "https://www.google.com/maps/search/pharmacy/@${_medLocation.latitude},${_medLocation.longitude},14z";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(Icons.medical_services, "Medication",
                        widget.medData["name"] ?? "Unknown"),
                    _buildDetailRow(Icons.format_list_numbered, "Dosage",
                        widget.medData["dosage"] ?? "Not specified"),
                    _buildDetailRow(
                        Icons.inventory,
                        "Current Inventory",
                        "${widget.medData["currentInventory"] ?? "0"} ${widget.medData["unit"] ?? ""}"),
                    _buildDetailRow(Icons.access_time, "Reminder Time",
                        widget.medData["reminderTimes"] ?? "Not set"),
                    _buildDetailRow(
                        Icons.date_range,
                        "Refill When Inventory <= ",
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
                    target: _medLocation,
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId("medLocation"),
                      position: _medLocation,
                      infoWindow: InfoWindow(
                          title: widget.medData["name"] ?? "Medication"),
                    ),
                    if (_currentPosition != null)
                      Marker(
                        markerId: const MarkerId("currentLocation"),
                        position: LatLng(
                            _currentPosition!.latitude, _currentPosition!.longitude),
                        infoWindow: const InfoWindow(title: "Your Location"),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue),
                      ),
                  },
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),


            Center(
              child: ElevatedButton.icon(
                onPressed: _openGoogleMaps,
                icon: const Icon(Icons.map),
                label: const Text("Search Pharmacies Nearby"),
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
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
