import 'package:flutter/material.dart';

class AdminEmpresaAnnouncements extends StatefulWidget {
  const AdminEmpresaAnnouncements({super.key});

  @override
  State<AdminEmpresaAnnouncements> createState() => _AdminEmpresaAnnouncementsState();
}

class _AdminEmpresaAnnouncementsState extends State<AdminEmpresaAnnouncements> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, String>> _sentAnnouncements = [
    {
      'title': 'Actualización de horarios',
      'message': 'Se modifican los horarios de entrada para el turno mañana.',
      'meta': 'UTPL · 2025-11-01'
    },
    {
      'title': 'Revisión de indicadores',
      'message': 'Revisa la nueva plataforma de reportes, activa tus alertas.',
      'meta': 'UTPL · 2025-10-29'
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleSendAnnouncement() {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese título y mensaje.')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anuncio enviado (simulado)')));
    _titleController.clear();
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Anuncios y notificaciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Envía mensajes a los empleados', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          _buildFormCard(context),
          const SizedBox(height: 16),
          const Text('Anuncios enviados', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._sentAnnouncements.map((announce) => _buildAnnouncementRow(announce)),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Título del anuncio',
              hintText: 'Ej: Reunión general',
              filled: true,
              fillColor: const Color(0xFFF3F3F3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Mensaje',
              hintText: 'Escribe el contenido del anuncio...',
              filled: true,
              fillColor: const Color(0xFFF3F3F3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Enviar anuncio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD92344),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _handleSendAnnouncement,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementRow(Map<String, String> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(data['message'] ?? '', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(data['meta'] ?? '', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
        ],
      ),
    );
  }
}
