import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'request_service_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controlador de las pestañas
  int _indiceActual = 0;
  final user = FirebaseAuth.instance.currentUser;

  // --- PESTAÑA 0: Catálogo de Servicios (Lo que ya teníamos) ---
  Widget _construirPestanaInicio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(color: Colors.orange);
            }
            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
              return const Text("¡Hola, Bienvenido!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold));
            }
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            String nombre = userData['nombre'] ?? 'Usuario';
            return Text(
              "¡Hola, $nombre!",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            );
          },
        ),
        const SizedBox(height: 10),
        const Text("¿Qué necesitas reparar hoy?", style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 30),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              _buildServiceCard(Icons.water_drop, "Plomería", Colors.blue),
              _buildServiceCard(Icons.electrical_services, "Electricidad", Colors.amber),
              _buildServiceCard(Icons.format_paint, "Pintura", Colors.redAccent),
              _buildServiceCard(Icons.cleaning_services, "Aseo", Colors.teal),
              _buildServiceCard(Icons.carpenter, "Carpintería", Colors.brown),
              _buildServiceCard(Icons.car_repair, "Mecánica", Colors.blueGrey),
            ],
          ),
        ),
      ],
    );
  }

  // --- PESTAÑA 1: Historial de Solicitudes del Cliente ---
  Widget _construirPestanaMisSolicitudes() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('clienteId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Aún no has solicitado ningún servicio.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final misSolicitudes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: misSolicitudes.length,
            itemBuilder: (context, index) {
              var solicitud = misSolicitudes[index].data() as Map<String, dynamic>;
              String idDocumento = misSolicitudes[index].id;

              // Evaluamos el estado exacto
              String estado = solicitud['estado'] ?? 'pendiente';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    // Borde gris si ya se terminó
                    side: BorderSide(color: estado == 'finalizado' ? Colors.grey.shade300 : Colors.transparent)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              solicitud['servicio'] ?? 'Servicio',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: estado == 'finalizado' ? Colors.grey : Colors.orange)
                          ),
                          Chip(
                              label: Text(
                                  estado == 'finalizado' ? "Finalizado" : (estado == 'aceptado' ? "Aceptado" : "Pendiente"),
                                  style: TextStyle(color: estado == 'finalizado' ? Colors.grey : (estado == 'aceptado' ? Colors.green : Colors.orange))
                              ),
                              backgroundColor: estado == 'finalizado' ? Colors.grey[200] : (estado == 'aceptado' ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0)),
                              side: BorderSide.none
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(solicitud['descripcion'] ?? 'Sin descripción', style: TextStyle(color: estado == 'finalizado' ? Colors.grey : Colors.black)),
                      const SizedBox(height: 10),

                      // --- RENDERIZADO CONDICIONAL DE 3 ESTADOS ---
                      if (estado == 'aceptado') ...[
                        // ESTADO 1: ACEPTADO (Muestra al trabajador y el botón de chat)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Icon(Icons.handyman, color: Colors.green, size: 20),
                              const SizedBox(width: 10),
                              Expanded(child: Text("Trabajador asignado:\n${solicitud['trabajadorEmail']}", style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => ChatScreen(solicitudId: idDocumento),
                              ));
                            },
                            icon: const Icon(Icons.chat, color: Colors.white),
                            label: const Text("Hablar con el Trabajador", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                          ),
                        )
                      ] else if (estado == 'finalizado') ...[
                        // ESTADO 2: FINALIZADO (Muestra mensaje de cierre y oculta el chat)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.grey, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text("El trabajador ${solicitud['trabajadorEmail'] ?? ''} ha finalizado este servicio.",
                                      style: const TextStyle(fontSize: 13, color: Colors.grey))
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // ESTADO 3: PENDIENTE (Muestra mensaje de espera)
                        const Text("Buscando un trabajador disponible...", style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        }
    );
  }

  // Fábrica de tarjetas (ahora sin pedir context por parámetro porque al ser StatefulWidget ya lo conoce globalmente)
  Widget _buildServiceCard(IconData icon, String title, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RequestServiceScreen(servicioNombre: title)),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_indiceActual == 0 ? "ToderoExpress" : "Mis Solicitudes", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              }
            },
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          // Cambia el contenido según el botón inferior que se presione
          child: _indiceActual == 0 ? _construirPestanaInicio() : _construirPestanaMisSolicitudes(),
        ),
      ),
      // --- BARRA DE NAVEGACIÓN INFERIOR ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        selectedItemColor: Colors.orange,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: "Mis Solicitudes",
          ),
        ],
      ),
    );
  }
}