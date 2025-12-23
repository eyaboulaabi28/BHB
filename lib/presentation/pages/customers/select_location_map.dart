import 'dart:convert';
import 'package:app_bhb/common/color_extension.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class SelectLocationMap extends StatefulWidget {
  const SelectLocationMap({super.key});
  @override

  State<SelectLocationMap> createState() => _SelectLocationMapState();
}

class _SelectLocationMapState extends State<SelectLocationMap> {
  LatLng? selectedPosition;
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

  Future<String?> getAddressFromLatLng(LatLng position) async {
    const apiKey = 'AIzaSyCwrHbo-Su0la8PW46zDxofouVpMDMgnHI';

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&language=ar&key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['results'] as List).isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
    } catch (e) {
      print("Erreur reverse geocoding: $e");
    }
    return null;
  }


  // 🔹 Fonction pour récupérer les coordonnées depuis l'adresse
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    const apiKey = 'AIzaSyCwrHbo-Su0la8PW46zDxofouVpMDMgnHI';
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['results'] as List).isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      print("Erreur Geocoding: $e");
    }
    return null;
  }


  Future<void> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status != PermissionStatus.granted) {
      // tu peux afficher un message à l'utilisateur
      print("Permission localisation refusée");
    }
  }
  @override
  void initState() {
    super.initState();
    requestLocationPermission();
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF2F4F3),
        appBar: AppBar(
          backgroundColor: TColor.primary,
          elevation: 0,
          title: const SizedBox(),
        ),
        body: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 25, top: 20),
              decoration: BoxDecoration(
                color: TColor.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: const Center(
                child: Text(
                  "اختيار الموقع",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Google Map + Boutons Zoom
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(24.7136, 46.6753),
                      zoom: 10,
                    ),
                    zoomControlsEnabled: false,   // ⚠️ On désactive les contrôles natifs
                    onTap: (pos) {
                      setState(() {
                        selectedPosition = pos;
                      });
                    },
                    markers: selectedPosition == null
                        ? {}
                        : {
                      Marker(
                        markerId: const MarkerId("selected"),
                        position: selectedPosition!,
                      )
                    },
                  ),

                  // 🔥 Boutons Zoom personnalisés
                  Positioned(
                    bottom: 20,
                    right: 10,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          mini: true,
                          heroTag: "zoom_in",
                          onPressed: () {
                            _mapController?.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          mini: true,
                          heroTag: "zoom_out",
                          onPressed: () {
                            _mapController?.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                          child: const Icon(Icons.remove),

                        ),
                        const SizedBox(height: 30),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Bouton valider (check)
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (selectedPosition != null) {

              // 🔥 Récupérer adresse lisible
              String? address = await getAddressFromLatLng(selectedPosition!);

              Navigator.pop(context, {
                "lat": selectedPosition!.latitude,
                "lng": selectedPosition!.longitude,
                "address": address ?? "العنوان غير متوفر"
              });
            }
          },
          child: const Icon(Icons.check),
        ),

      ),
    );
  }

}
