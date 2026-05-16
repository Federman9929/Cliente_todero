import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Coordenadas iniciales (Bogotá)
  final LatLng _posicionInicial = const LatLng(4.6097, -74.0817);

  // Variable para guardar el punto donde el usuario haga clic
  LatLng? _ubicacionSeleccionada;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecciona tu ubicación", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _posicionInicial,
          initialZoom: 14.0,
          // Escuchamos los toques en el mapa
          onTap: (tapPosition, point) {
            setState(() {
              _ubicacionSeleccionada = point;
            });
          },
        ),
        children: [
          // 1. La capa visual del mapa (Calles, edificios, etc.)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.toderoexpress.cliente',
          ),
          // 2. La capa de marcadores (El pin rojo)
          if (_ubicacionSeleccionada != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _ubicacionSeleccionada!,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 50,
                  ),
                ),
              ],
            ),
        ],
      ),
      // Botón flotante para confirmar la dirección
      floatingActionButton: _ubicacionSeleccionada != null
          ? FloatingActionButton.extended(
        onPressed: () {
          // Al confirmar, devolvemos la coordenada a la pantalla anterior
          Navigator.pop(context, _ubicacionSeleccionada);
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text("Confirmar", style: TextStyle(color: Colors.white)),
      )
          : null,
    );
  }
}