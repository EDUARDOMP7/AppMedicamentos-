import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:untitled1/database/database_helper.dart';
import 'package:flutter/services.dart';

// Inicializa el plugin de notificaciones
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  // Solicita permisos antes de inicializar las notificaciones
  await _requestPermissions();

  // Inicializa las zonas horarias
  tz.initializeTimeZones();

  // Configura el canal de notificaciones para Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'medication_channel_id', // ID del canal
    'Recordatorio de Medicamentos', // Nombre del canal
    description: 'Canal para recordatorio de medicamentos',
    importance: Importance.high,
  );

  final AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Crear el canal de notificación
  final platformSpecificImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (platformSpecificImplementation != null) {
    await platformSpecificImplementation.createNotificationChannel(channel);
    print('Canal de notificación creado exitosamente.');
  } else {
    print('Error al crear el canal de notificación.');
  }

  print('Notificaciones inicializadas correctamente.');
}

Future<void> sendNotificationsForMedications() async {
  print('Obteniendo medicamentos de la base de datos...');
  final medications = await DatabaseHelper.instance.getAllMedications();

  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  print('Hora actual del dispositivo: ${now.toLocal()}');

  for (var medication in medications) {
    try {
      // Obtener la fecha y hora del medicamento desde la base de datos
      String name = medication['name'];
      DateTime scheduleDate = DateTime.parse(medication['schedule_date']); // Asegúrate de que esta columna exista en la base de datos

      // Convertirla a TZDateTime
      final tz.TZDateTime medicationTime = tz.TZDateTime.from(scheduleDate, tz.local);
      print('Hora programada del medicamento: ${medicationTime.toLocal()}');

      // Verifica si la hora programada coincide con la hora actual
      if (medicationTime.year == now.year &&
          medicationTime.month == now.month &&
          medicationTime.day == now.day &&
          medicationTime.hour == now.hour &&
          medicationTime.minute == now.minute) {
        // Envía una notificación inmediata
        print('Enviando notificación para el medicamento: $name');
        await showImmediateNotification(
          title: 'Es hora de tu medicamento',
          body: 'Es momento de tomar $name',
        );
      } else {
        print('No es el momento para el medicamento $name. La hora programada es ${medicationTime.toLocal()} y la hora actual es ${now.toLocal()}');
      }
    } catch (e) {
      print('Error al procesar medicamento $medication: $e');
    }
  }
}

Future<void> showImmediateNotification({required String title, required String body}) async {
  final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'medication_channel_id',
    'Recordatorio de Medicamentos',
    channelDescription: 'Canal para recordatorio de medicamentos',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 1000, 500, 2000]),
  );
  final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  try {
    await flutterLocalNotificationsPlugin.show(
      generateNotificationId(),
      title,
      body,
      platformChannelSpecifics,
      payload: 'medication_reminder',
    );

    print('Notificación inmediata enviada correctamente.');
  } catch (e) {
    print('Error al enviar notificación inmediata: $e');
  }
}

Future<void> _requestPermissions() async {
  // Solicitar permisos de notificación
  if (await Permission.notification.isDenied) {
    print('Permiso de notificación denegado, solicitando...');
    await Permission.notification.request();
  } else {
    print('Permiso de notificación ya concedido.');
  }

  // Solicitar permisos de alarma exacta
  if (await Permission.scheduleExactAlarm.isDenied || await Permission.scheduleExactAlarm.isPermanentlyDenied) {
    print('Permiso de alarma exacta denegado, solicitando...');
    await _requestExactAlarmPermission();
  } else {
    print('Permiso de alarma exacta ya concedido.');
  }
}

Future<void> _requestExactAlarmPermission() async {
  const MethodChannel platform = MethodChannel('com.example.untitled1/permissions');

  try {
    final bool permissionGranted = await platform.invokeMethod('requestExactAlarmPermission');
    print('Permiso de alarma exacta solicitado, concedido: $permissionGranted');
  } catch (e) {
    print('Error al solicitar permiso de alarma exacta: $e');
  }
}

int generateNotificationId() {
  return DateTime.now().millisecondsSinceEpoch.remainder(100000);
}