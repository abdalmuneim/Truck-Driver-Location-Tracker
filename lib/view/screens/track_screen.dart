import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import '../../const.dart';
import '../../core/provider/track_location_provider.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen(
      {Key? key, required this.shipmentLocation, required this.driverLocation})
      : super(key: key);
  final LatLng shipmentLocation;
  final LatLng driverLocation;

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {


  @override
  void initState() {
    final provider = Provider.of<TrackLocationProvider>(context, listen: false);
    provider.getCurrentLocation()?.then((value) => provider.getPolylinePoints(
          shipmentLocation: widget.shipmentLocation,
          driverLocation: widget.driverLocation,
        ));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Track order'),
          centerTitle: true,
        ),
        body: Consumer<TrackLocationProvider>(
            builder: (context, trackProvider, child) {
          return widget.driverLocation == null
              ? const Center(
                  child: Text("Loading.."),
                )
              : GoogleMap(
                  mapType: MapType.normal,
                  myLocationButtonEnabled: true,
                  initialCameraPosition: CameraPosition(
                      target: LatLng(trackProvider.currentLocation!.latitude!,
                          trackProvider.currentLocation!.longitude!),
                      zoom: 14.5),
                  myLocationEnabled: true,
                  zoomGesturesEnabled: true,
                  zoomControlsEnabled: true,
                  tiltGesturesEnabled: false,
                  compassEnabled: false,
                  indoorViewEnabled: true,
                  // polylines: trackProvider.polylines.values, // used its when enable Billing
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('rout'),
                      color: Colors.blue,
                      points: trackProvider.polyLineCoordinates,
                      width: 5,
                    )
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('current location'),
                      position: LatLng(trackProvider.currentLocation!.latitude!,
                          trackProvider.currentLocation!.longitude!),
                    ),
                    Marker(
                      markerId: const MarkerId('shipment'),
                      position: widget.shipmentLocation,
                    ),
                  },
                  onMapCreated: (mapController) {
                    trackProvider.controller.complete(mapController);
                  },
                );
        }),
      ),
    );
  }
}
