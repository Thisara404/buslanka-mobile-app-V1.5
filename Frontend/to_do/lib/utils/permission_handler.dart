import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionHandler {
  // Request specific permission
  static Future<bool> requestPermission(Permission permission) async {
    PermissionStatus status = await permission.status;

    if (status.isDenied) {
      status = await permission.request();
      return status.isGranted;
    } else if (status.isPermanentlyDenied) {
      return false;
    }

    return status.isGranted;
  }

  // Request location permissions (both fine and course)
  static Future<bool> requestLocationPermission() async {
    return await requestPermission(Permission.locationWhenInUse);
  }

  // Check if a permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    return await permission.isGranted;
  }

  // Open app settings if permission is permanently denied
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  // Show permission rationale dialog
  static Future<void> showPermissionRationaleDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onRequestAgain,
    VoidCallback onCancel,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                onCancel();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
            TextButton(
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                onRequestAgain();
              },
            ),
          ],
        );
      },
    );
  }
}
