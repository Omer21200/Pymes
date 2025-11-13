import 'package:flutter/material.dart';
import '../../main.dart';

class AnunciosAdmin extends StatefulWidget {
  final String userId;
  final String? companyName;
  final bool createMode;

  const AnunciosAdmin({required this.userId, this.companyName, this.createMode = false, super.key});

  @override
  State<AnunciosAdmin> createState() => _AnunciosAdminState();
}

class _AnunciosAdminState extends State<AnunciosAdmin> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa título y mensaje'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _sending = true);
    try {
      // intentar resolver empresa_id desde companyName
      String? empresaId;
      if (widget.companyName != null && widget.companyName!.isNotEmpty) {
        final ent = await supabase.from('empresas').select('id').eq('nombre', widget.companyName!).maybeSingle();
        if (ent != null && ent['id'] != null) empresaId = ent['id'].toString();
      }

      final payload = {
        'titulo': title,
        'contenido': body,
        if (empresaId != null) 'empresa_id': empresaId,
      };

      final inserted = await supabase.from('notificaciones').insert([payload]).select().maybeSingle();
      if (inserted != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anuncio enviado')));
        // limpiar formulario
        _titleCtrl.clear();
        _bodyCtrl.clear();
        // si estamos en modo create (pantalla independiente) regresar
        if (widget.createMode) Navigator.pop(context);
      } else {
        throw Exception('No se pudo crear anuncio');
      }
    } catch (e) {
      debugPrint('Error creando anuncio: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _buildCreateForm() {
    return Scaffold(
      appBar: AppBar(title: const Text('Anuncios y Notificaciones'), backgroundColor: const Color(0xFFD92344)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anuncios y Notificaciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Envía mensajes a los empleados', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Título del anuncio', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ej: Reunión general',
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Mensaje', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bodyCtrl,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Escribe el contenido del anuncio...',
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sending ? null : _handleSend,
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text('Enviar Anuncio', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD92344),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.createMode) return _buildCreateForm();

    // Listado simple (placeholder) cuando no estamos creando
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Anuncios', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Card(child: ListTile(leading: Icon(Icons.campaign), title: Text('Anuncio ejemplo'), subtitle: Text('Contenido...'))),
        ],
      ),
    );
  }
}
