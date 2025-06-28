import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/UserLocationHolder.dart';
import '../services/PhoneValidator.dart';

class EmergencyContactHelper {
  static Future<void> EmergencyContactDialog(
      BuildContext context,
      Function(Map<String, String>) onContactAdded,
      ) {
    TextEditingController nameController = TextEditingController();
    TextEditingController phoneController = TextEditingController();

    final _formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Emergency Contact"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                  keyboardType: TextInputType.phone,
                  validator: PhoneValidator.validatePhoneNumber,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                if (!serviceEnabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enable location services")),
                  );
                  return;
                }

                LocationPermission permission = await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                  if (permission == LocationPermission.denied) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Location permission denied")),
                    );
                    return;
                  }
                }

                if (permission == LocationPermission.deniedForever) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Location permission permanently denied")),
                  );
                  return;
                }

                try {
                  Position position = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high,
                  );

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
                    const SnackBar(content: Text("Failed to get location")),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }
}
