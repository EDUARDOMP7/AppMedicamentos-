import 'package:flutter/material.dart';
import 'package:untitled1/database/database_helper.dart'; // Asegúrate de importar tu helper de base de datos

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  _ReminderListScreenState createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  Future<List<Map<String, dynamic>>> _fetchMedications() async {
    // Obtén los medicamentos de la base de datos
    final db = DatabaseHelper.instance;
    return await db.getAllMedications(); // Asegúrate de que el método se llama correctamente
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Recordatorios'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMedications(),
        builder: (context, snapshot) {
          // Muestra un indicador de carga mientras se obtienen los datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Muestra un mensaje de error si ocurre un problema al obtener los datos
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Muestra un mensaje si no hay datos disponibles
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay recordatorios guardados.'));
          }

          // Muestra los datos en una tabla
          final medications = snapshot.data!;
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const <DataColumn>[
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Días')),
                  DataColumn(label: Text('Hora')),
                  DataColumn(label: Text('Latitud')),
                  DataColumn(label: Text('Longitud')),
                ],
                rows: medications.map<DataRow>((medication) {
                  return DataRow(
                    cells: <DataCell>[
                      DataCell(Text(medication['name'] ?? '')),
                      DataCell(Text(medication['days'] ?? '')),
                      DataCell(Text(medication['time'] ?? '')),
                      DataCell(Text((medication['latitude'] ?? 0).toStringAsFixed(6))),
                      DataCell(Text((medication['longitude'] ?? 0).toStringAsFixed(6))),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
