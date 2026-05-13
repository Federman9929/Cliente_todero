import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestServiceScreen extends StatefulWidget {
  final String servicioNombre; // Recibe el nombre del servicio (ej. Plomería)

  const RequestServiceScreen({super.key, required this.servicioNombre});

  @override
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  final _descripcionController = TextEditingController();
  final _direccionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _enviarSolicitud() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;

        // Guardamos la solicitud en una nueva colección 'solicitudes'
        await FirebaseFirestore.instance.collection('solicitudes').add({
          'clienteId': user?.uid,
          'clienteEmail': user?.email,
          'servicio': widget.servicioNombre,
          'descripcion': _descripcionController.text.trim(),
          'direccion': _direccionController.text.trim(),
          'estado': 'pendiente', // Estado inicial
          'fecha': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Solicitud enviada. ¡Pronto un todero te contactará!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Regresamos al Home
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al enviar la solicitud"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Solicitar ${widget.servicioNombre}"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Cuéntanos el problema:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Ej: Mi grifo gotea mucho y no cierra, necesito cambiar un enchufe...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) => value!.isEmpty ? "Por favor describe el problema" : null,
                ),
                const SizedBox(height: 20),
                const Text("Dirección del servicio:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _direccionController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on),
                    hintText: "Ej: Calle 100 # 15-20, Bogotá",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) => value!.isEmpty ? "La dirección es obligatoria" : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _enviarSolicitud,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Enviar Solicitud", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}