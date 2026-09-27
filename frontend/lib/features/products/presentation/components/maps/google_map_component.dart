import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapComponent extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const GoogleMapComponent({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.markers,
    required this.polylines,
  });

  @override
  State<GoogleMapComponent> createState() => GoogleMapComponentState();
}

class GoogleMapComponentState extends State<GoogleMapComponent> {
  GoogleMapController? _controller;

  // هذه الدالة ستستخدمها لاحقاً لتحريك الكاميرا عند وصول إحداثيات جديدة للكابتن
  Future<void> updateCameraPosition(double lat, double lng) async {
    if (_controller != null) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLng(LatLng(lat, lng)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.initialLat, widget.initialLng),
        zoom: 15.0,
      ),
      markers: widget.markers,
      polylines: widget.polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
      onMapCreated: (GoogleMapController controller) {
        _controller =
            controller; // تم استخدام الـ controller هنا، وسيختفي التحذير
      },
    );
  }
}
