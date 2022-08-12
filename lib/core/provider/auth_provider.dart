import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../model/truckdriver_model.dart';
import '../../view/screens/shipments_screen.dart';
import '../services/truckdriverdata_firebase.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  String? name;
  String? phone;

  onChangeName(val) {
    name = val;
    log('name: $name');
    notifyListeners();
  }

  onChangePhone(val) {
    phone = val;
    log('phone: $phone');
    notifyListeners();
  }

  bool _isPushData = false;

  bool get isPushData => _isPushData;

  /// Authenticate with Firebase anonymously
  Future<User?>? authAnonymously(context) async {
    try {
      log("Signed in with temporary account.");
      if (currentUser == null) {
        log("---------------- 1 -----------------");
        final UserCredential userCredential = await _auth.signInAnonymously();
        await addTruckDriverToFirebase(userCredential.user!);
        log("---------------- 2 -----------------");
      } else {
        log("---------------- 3 -----------------");
      }
      log("---------------- 4 -----------------");
      _isPushData = true;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => ShipmentsScreen(),
      ));
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "operation-not-allowed":
          debugPrint("Anonymous auth hasn't been enabled for this project.");
          break;
        default:
          debugPrint("Unknown error.");
      }
      _isPushData = false;
    }
    notifyListeners();
    return currentUser;
  }

  addTruckDriverToFirebase(User user) async {
    var dbTimeKey = DateTime.now();
    var formatDate = DateFormat(' MMM d, yyyy');
    var formatTime = DateFormat('  EEEE, hh:mm:aa  ');

    String date = formatDate.format(dbTimeKey);
    String time = formatTime.format(dbTimeKey);
    String createAt = '$date' '$time';

    await FireStoreTruckDriverUser().addUserDataToFireStore(TruckDriverModel(
      uid: user.uid,
      name: name!,
      phone: phone!,
      createAt: createAt,
    ));
  }

  late Position _position;

  Position get position => _position;

  /// Determine the current position of the device.
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> determinePosition() async {
    debugPrint('---------------------------------');
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }
    debugPrint('----------------- 1 ----------------');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }
    debugPrint('----------------- 2 ----------------');

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    debugPrint('----------------- 3 ----------------');
    _position = await Geolocator.getCurrentPosition();
    debugPrint('----------------- 4 ----------------');

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return _position;
  }
}
