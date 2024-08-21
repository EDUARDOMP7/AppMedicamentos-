import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:untitled1/screens/notification_helper.dart';
import 'package:untitled1/database/database_helper.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _notificationSent = false; // Variable para rastrear si la notificación ya ha sido enviada
  Position? _lastPosition; // Variable para rastrear la última posición conocida

  // Método para iniciar el seguimiento de la ubicación
  void startLocationTracking(double targetLatitude, double targetLongitude) {
    print('Iniciando el seguimiento de la ubicación...');
    _positionStreamSubscription?.cancel(); // Cancela el seguimiento previo si existe
    _notificationSent = false; // Reinicia el estado cuando se inicia el seguimiento

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 30, // Aumenta el filtro de distancia para reducir actualizaciones frecuentes
      ),
    ).listen((Position position) async {
      print('Nueva posición recibida: Latitud ${position.latitude}, Longitud ${position.longitude}');
      await _handlePositionUpdate(position, targetLatitude, targetLongitude);
    }, onError: (error) {
      print('Error en el stream de ubicación: $error');
    });
  }

  Future<void> _handlePositionUpdate(Position position, double targetLatitude, double targetLongitude) async {
    print('Manejando actualización de posición...');

    if (_lastPosition == null || _positionHasSignificantChange(position, _lastPosition!)) {
      print('Ubicación actual: Latitud ${position.latitude}, Longitud ${position.longitude}');

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLatitude,
        targetLongitude,
      );

      print('Distancia a la ubicación objetivo: ${distanceInMeters.toStringAsFixed(2)} metros');

      // Verifica si la distancia es mayor a 30 metros y si la notificación aún no se ha enviado
      if (distanceInMeters > 30 && !_notificationSent) {
        print('La distancia es mayor a 30 metros, enviando notificación...');
        await _sendMedicationReminder();
        _notificationSent = true; // Marca que la notificación ya ha sido enviada
      } else if (distanceInMeters <= 5) {
        print('La distancia es menor o igual a 5 metros, no se envía notificación.');
      }

      _lastPosition = position; // Actualiza la última posición conocida
    }
  }

  bool _positionHasSignificantChange(Position newPosition, Position oldPosition) {
    final double distanceInMeters = Geolocator.distanceBetween(
      newPosition.latitude,
      newPosition.longitude,
      oldPosition.latitude,
      oldPosition.longitude,
    );
    return distanceInMeters > 10; // Cambia el valor según lo que consideres significativo
  }

  Future<void> _sendMedicationReminder() async {
    print('Obteniendo medicamentos de la base de datos...');
    final medications = await DatabaseHelper.instance.getAllMedications();

    if (medications.isNotEmpty) {
      final String medicationNames = medications.map((med) => med['name']).join(', ');

      print('Enviando notificación con los medicamentos: $medicationNames');

      await showImmediateNotification(
        title: 'No olvides tus medicamentos',
        body: 'Recuerda llevar tus medicamentos: $medicationNames',
      );
    } else {
      print('No hay medicamentos en la base de datos para notificar.');
    }
  }

  void stopLocationTracking() {
    print('Deteniendo el seguimiento de la ubicación...');
    _positionStreamSubscription?.cancel();
  }
}
