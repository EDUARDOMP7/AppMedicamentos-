import 'package:flutter/material.dart';
import 'package:untitled1/database/database_helper.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:untitled1/screens/notification_helper.dart'; // Importa el archivo de notificaciones
import 'package:geolocator/geolocator.dart'; // Importa para obtener la ubicación
import 'package:untitled1/screens/location_service.dart'; // Importa el servicio de ubicación

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  MedicationScreenState createState() => MedicationScreenState();
}

class MedicationScreenState extends State<MedicationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  final List<String> _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  final Map<String, bool> _selectedDays = {
    'Lunes': false,
    'Martes': false,
    'Miércoles': false,
    'Jueves': false,
    'Viernes': false,
    'Sábado': false,
    'Domingo': false,
  };

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final LocationService _locationService = LocationService(); // Instancia del servicio de ubicación

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context); // Muestra la hora seleccionada en formato de 12 horas
      });
    }
  }

  Future<void> _saveMedication() async {
    final String name = _nameController.text.trim();
    final String date = _selectedDate != null ? _selectedDate!.toLocal().toString().split(' ')[0] : '';
    final String days = _selectedDays.entries.where((entry) => entry.value).map((entry) => entry.key).join(', ');
    final String time = _timeController.text.trim();
    final double? latitude = double.tryParse(_latitudeController.text);
    final double? longitude = double.tryParse(_longitudeController.text);

    if (name.isNotEmpty && date.isNotEmpty && days.isNotEmpty && time.isNotEmpty && latitude != null && longitude != null) {
      _showSnackbar('Guardando medicamento...');

      final medication = {
        'name': name,
        'date': date,
        'days': days,
        'time': time,
        'latitude': latitude,
        'longitude': longitude,
      };

      try {
        // Guardar en la base de datos
        await DatabaseHelper.instance.insertMedication(medication);

        _showSnackbar('Medicamento guardado exitosamente.');

        // Iniciar el seguimiento de ubicación después de guardar el medicamento
        _locationService.startLocationTracking(latitude, longitude);

        final TimeOfDay? parsedTime = _parseTimeOfDay(time);

        if (parsedTime != null && _selectedDate != null) {
          // Programar la notificación para cada día seleccionado


          print('Notificación programada para la hora seleccionada en los días: $days');
        }
      } catch (e) {
        _showSnackbar('Error al guardar el medicamento: $e');
      }
    } else {
      _showSnackbar('Por favor completa todos los campos.');
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeString) {
    final RegExp timeRegExp = RegExp(r'(\d{1,2}):(\d{2})\s?(AM|PM)?', caseSensitive: false);
    final match = timeRegExp.firstMatch(timeString);

    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final amPm = match.group(3)?.toUpperCase();

    if (amPm == 'PM' && hour != 12) hour += 12;
    if (amPm == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.toLocal()}'.split(' ')[0]; // Formatear la fecha como YYYY-MM-DD
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
    } catch (e) {
      _showSnackbar('No se pudo obtener la ubicación actual.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Medicamento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre del Medicamento'),
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Fecha'),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(labelText: 'Hora (HH:MM AM/PM)'),
                ),
              ),
            ),
            TextField(
              controller: _latitudeController,
              decoration: const InputDecoration(labelText: 'Latitud'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _longitudeController,
              decoration: const InputDecoration(labelText: 'Longitud'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text('Obtener Ubicación Actual'),
            ),
            const SizedBox(height: 16),
            const Text('Días de la Semana'),
            ..._days.map((day) => CheckboxListTile(
              title: Text(day),
              value: _selectedDays[day],
              onChanged: (bool? value) {
                setState(() {
                  _selectedDays[day] = value ?? false;
                });
              },
            )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveMedication,
              child: const Text('Guardar Medicamento'),
            ),
          ],
        ),
      ),
    );
  }
}
