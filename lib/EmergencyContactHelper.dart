import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/UserLocationHolder.dart';

class EmergencyContactHelper {
  static Future<void> EmergencyContactDialog(
    BuildContext context,
    Function(Map<String, String>) onContactAdded,
  ) {
    TextEditingController nameController = TextEditingController();
    TextEditingController phoneController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Emergency Contact"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
           TextButton(
  onPressed: () async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enable location services")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location permission permanently denied")),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
print("User location updated: ${position.latitude}, ${position.longitude}");
  print("Contact will be added with location: ${position.latitude}, ${position.longitude}");

      UserLocationHolder.setLocation(position.latitude, position.longitude);

      Map<String, String> newContact = {
        "name": nameController.text,
        "phone": phoneController.text,
        "latitude": position.latitude.toString(),
        "longitude": position.longitude.toString(),
      };

      onContactAdded(newContact);
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get location")),
      );
    }
  },
  child: Text("Add"),
),


          ],
        );
      },
    );
  }
}
