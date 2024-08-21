import 'package:flutter/material.dart';
import 'package:untitled1/screens/home_screen.dart';
import 'package:untitled1/screens/check_location_screen.dart';
import 'package:untitled1/screens/medication_screen.dart';
import 'package:untitled1/screens/reminder_list_screen.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled1/screens/notification_helper.dart'; // Ajusta la ruta según la ubicación del archivo
import 'package:untitled1/screens/medication_info_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeNotifications();

  // Inicializar zona horaria
  tz.initializeTimeZones();

  // Solicitar permisos
  await _requestPermissions();

  // Inicializar bases de datos según la plataforma
  if (kIsWeb) {
    await _initializeHive();
  } else {
    await _initializeSqfliteDatabase();
  }

  await sendNotificationsForMedications() ;
  await showImmediateNotification;

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  if (!kIsWeb) {
    // Solicitar permisos para enviar notificaciones
    final status = await Permission.notification.request();
    if (status.isDenied) {
      print('Permiso de notificación denegado');
      // Maneja la negación del permiso, podrías mostrar un diálogo al usuario aquí
    } else if (status.isPermanentlyDenied) {
      print('Permiso de notificación permanentemente denegado');
      // Puedes redirigir al usuario a la configuración del sistema para habilitar el permiso
    } else {
      print('Permiso de notificación concedido');
    }

    // Solicitar permisos de alarma exacta
    final alarmStatus = await Permission.scheduleExactAlarm.request();
    if (alarmStatus.isDenied) {
      print('Permiso de alarma exacta denegado');
      // Maneja la negación del permiso
    } else if (alarmStatus.isPermanentlyDenied) {
      print('Permiso de alarma exacta permanentemente denegado');
      // Puedes redirigir al usuario a la configuración del sistema
    } else {
      print('Permiso de alarma exacta concedido');
    }
  }
}

Future<void> _initializeHive() async {
  try {
    await Hive.initFlutter();
    await Hive.openBox('medications');
    print('Hive inicializado correctamente para la web.');
  } catch (e) {
    print('Error al inicializar Hive: $e');
  }
}

Future<void> _initializeSqfliteDatabase() async {
  try {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'medications.db');

    await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE medications(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            days TEXT,
            schedule_date TEXT
          )
          ''',
        );
      },
    );
    print('Base de datos Sqflite inicializada correctamente.');
  } catch (e) {
    print('Error al inicializar la base de datos Sqflite: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recordatorio de Medicamentos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/checkLocation': (context) => const CheckLocationScreen(),
        '/medication': (context) => const MedicationScreen(),
        '/reminder': (context) => const ReminderListScreen(),
        '/medic': (context) => const MedicationInfoScreen()
      },
    );
  }
}
