import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MedicationInfoScreen extends StatefulWidget {
  const MedicationInfoScreen({super.key});
  @override
  _MedicationInfoScreenState createState() => _MedicationInfoScreenState();
}

class _MedicationInfoScreenState extends State<MedicationInfoScreen> {
  String _medicationInfo = 'Introduce el nombre del medicamento para buscar';

  // Método para realizar la solicitud a la API de OpenFDA
  Future<void> _fetchMedicationInfo(String medicationName) async {
    final String url =
        'https://api.fda.gov/drug/label.json?search=openfda.brand_name:$medicationName&limit=1';

    print('Realizando solicitud a la API: $url');  // Log para la solicitud

    try {
      // Realizamos la solicitud GET a la API
      final response = await http.get(Uri.parse(url));

      print('Respuesta recibida. Código de estado: ${response.statusCode}');  // Log para el estado de la respuesta

      // Verificamos si la respuesta es exitosa (código de estado 200)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Datos recibidos de la API: $data');  // Log para los datos recibidos

        // Extraemos la información del primer resultado
        final result = data['results']?[0];
        if (result != null) {
          final String activeIngredient = (result['active_ingredient'] as List?)?.join(', ') ?? 'No disponible';
          final String purpose = (result['purpose'] as List?)?.join(', ') ?? 'No disponible';
          final String indications = (result['indications_and_usage'] as List?)?.join('\n') ?? 'No disponible';
          final String warnings = (result['warnings'] as List?)?.join('\n') ?? 'No disponible';

          setState(() {
            _medicationInfo = '''
            Ingrediente Activo: $activeIngredient
            Propósito: $purpose
            Indicaciones y Uso: 
            $indications
            Advertencias: 
            $warnings
            ''';
          });
        } else {
          setState(() {
            _medicationInfo = 'No se encontraron datos para el medicamento especificado.';
          });
          print('No se encontraron resultados en la respuesta de la API.');
        }
      } else {
        // Si la API responde con un error, mostramos un mensaje
        setState(() {
          _medicationInfo = 'Error al obtener la información. Inténtalo de nuevo.';
        });
        print('Error en la solicitud a la API. Código de estado: ${response.statusCode}');  // Log para el error en la respuesta
      }
    } catch (e) {
      // Si hay algún error en la solicitud, lo capturamos aquí
      setState(() {
        _medicationInfo = 'Error: $e';
      });
      print('Error en la solicitud o procesamiento de datos: $e');  // Log para los errores en la solicitud o manejo de datos
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Información del Medicamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                labelText: 'Nombre del Medicamento',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                print('Nombre del medicamento ingresado: $value');  // Log para el valor ingresado
                _fetchMedicationInfo(value);
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _medicationInfo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
