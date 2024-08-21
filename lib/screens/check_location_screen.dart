import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CheckLocationScreen extends StatefulWidget {
  const CheckLocationScreen({super.key});

  @override
  _CheckLocationScreenState createState() => _CheckLocationScreenState();
}

class _CheckLocationScreenState extends State<CheckLocationScreen> {
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  LatLng? _location;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (kIsWeb) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _updateLocationUI(position);
      } else {
        final status = await Geolocator.checkPermission();
        if (status == LocationPermission.denied) {
          final requestedStatus = await Geolocator.requestPermission();
          if (requestedStatus != LocationPermission.whileInUse && requestedStatus != LocationPermission.always) {
            throw Exception('Permiso de ubicación no concedido.');
          }
        }
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _updateLocationUI(position);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la ubicación actual.')),
      );
    }
  }

  void _updateLocationUI(Position position) {
    setState(() {
      _location = LatLng(position.latitude, position.longitude);
      _latitudeController.text = position.latitude.toString();
      _longitudeController.text = position.longitude.toString();
      _mapController.move(_location!, 13.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprobar Ubicación'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _location ?? LatLng(0.0, 0.0),
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                if (_location != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _location!,
                        width: 40.0,
                        height: 40.0,
                        // Replace `builder` with `child`
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40.0),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Latitud',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Longitud',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _updateLocation,
                  child: const Text('Actualizar Ubicación'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateLocation() {
    final double? latitude = double.tryParse(_latitudeController.text);
    final double? longitude = double.tryParse(_longitudeController.text);

    if (latitude != null && longitude != null) {
      setState(() {
        _location = LatLng(latitude, longitude);
        _mapController.move(_location!, 13.0);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa valores válidos para latitud y longitud.')),
      );
    }
  }
}
