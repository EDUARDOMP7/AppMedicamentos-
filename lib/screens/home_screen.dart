import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla Principal'),
        centerTitle: true, // Centra el título del AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildButton(
              context: context,
              routeName: '/checkLocation',
              label: 'Comprobar Ubicación',
            ),
            const SizedBox(height: 16),
            _buildButton(
              context: context,
              routeName: '/medication',
              label: 'Agregar Medicamento',
            ),
            const SizedBox(height: 16),
            _buildButton(
              context: context,
              routeName: '/reminder',
              label: 'Lista de Recordatorios',
            ),
            const SizedBox(height: 16),
            _buildButton(
              context: context,
              routeName: '/medic',
              label: 'Informacion de los medicamentos',
            ),
          ],
        ),
      ),
    );
  }

  // Método auxiliar para construir los botones
  ElevatedButton _buildButton({
    required BuildContext context,
    required String routeName,
    required String label,
  }) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, routeName);
      },
      child: Text(label),
    );
  }
}
