import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String solicitudId;

  const ChatScreen({super.key, required this.solicitudId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _mensajeController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _enviarMensaje() async {
    String texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    _mensajeController.clear();

    await FirebaseFirestore.instance
        .collection('solicitudes')
        .doc(widget.solicitudId)
        .collection('mensajes')
        .add({
      'texto': texto,
      'emisorId': currentUser?.uid,
      'emisorEmail': currentUser?.email,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat del Servicio", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('solicitudes')
                  .doc(widget.solicitudId)
                  .collection('mensajes')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Aún no hay mensajes. ¡Escribe el primero!", style: TextStyle(color: Colors.grey)));
                }

                var mensajes = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    var mensaje = mensajes[index].data() as Map<String, dynamic>;
                    bool soyYo = mensaje['emisorId'] == currentUser?.uid;

                    return Align(
                      alignment: soyYo ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: soyYo ? Colors.indigo[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(mensaje['texto'] ?? '', style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _enviarMensaje,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}