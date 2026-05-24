import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'map_screen.dart';

class RequestServiceScreen extends StatefulWidget {
  final String servicioNombre;
  const RequestServiceScreen({super.key, required this.servicioNombre});

  @override
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  final _descripcionController = TextEditingController();
  final _direccionManualController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  LatLng? _coordenadas;

  Future<void> _enviarSolicitud() async {
    if (_formKey.currentState!.validate()) {
      if (_coordenadas == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona la ubicación en el mapa"), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('solicitudes').add({
            'servicio': widget.servicioNombre,
            'descripcion': _descripcionController.text.trim(),
            'direccion_manual': _direccionManualController.text.trim(),
            'latitud': _coordenadas!.latitude,
            'longitud': _coordenadas!.longitude,
            'estado': 'pendiente',
            'clienteId': user.uid,
            'clienteEmail': user.email,
            'fecha': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        // Manejo de error
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: Text("Solicitar ${widget.servicioNombre}"), backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Descripción del problema:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                validator: (value) => value!.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 20),

              const Text("Ubicación en el Mapa (Obligatorio):", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade300)),
                leading: const Icon(Icons.map, color: Colors.orange),
                title: Text(_coordenadas == null ? "Toca para abrir el mapa" : "Punto marcado correctamente"),
                onTap: () async {
                  final LatLng? resultado = await Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen()));
                  if (resultado != null) setState(() => _coordenadas = resultado);
                },
              ),
              const SizedBox(height: 20),

              const Text("Dirección o detalles adicionales:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _direccionManualController,
                decoration: InputDecoration(
                    hintText: "Ej: Calle 100 #15-20, Apto 502, Torre B",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                ),
                validator: (value) => value!.isEmpty ? "Por favor escribe tu dirección" : null,
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enviarSolicitud,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Confirmar Solicitud", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}