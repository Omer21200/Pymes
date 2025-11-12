import 'package:flutter/material.dart';
import '../widgets/profile_card.dart';
import '../main.dart';

class EmpresasPage extends StatefulWidget {
  final String userName;

  const EmpresasPage({this.userName = 'Super Admin', super.key});

  @override
  State<EmpresasPage> createState() => _EmpresasPageState();
}

class _EmpresasPageState extends State<EmpresasPage> {
  List<Map<String, dynamic>> _companies = [];

  // form controllers for creating empresa
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _rucCtrl = TextEditingController();
  final TextEditingController _direccionCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _horaEntradaCtrl = TextEditingController();
  final TextEditingController _toleranciaCtrl = TextEditingController(text: '15');
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final res = await supabase.from('empresas').select().order('nombre');
      final List resList = res as List;
      setState(() {
        _companies = resList.map<Map<String, dynamic>>((e) => {
              'id': e['id'],
              'name': e['nombre'] ?? e['name'] ?? '',
              'ruc': e['ruc'] ?? '',
              'direccion': e['direccion'] ?? '',
              'telefono': e['telefono'] ?? '',
              'email': e['email'] ?? '',
              'hora_entrada': e['hora_entrada'] ?? '',
              'tolerancia_minutos': e['tolerancia_minutos'] ?? 0,
            }).toList();
      });
    } catch (e) {
      debugPrint('Error cargando empresas (EmpresasPage): $e');
    }
  }

  Future<void> _createEmpresa() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre es obligatorio'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isCreating = true);
    try {
      final payload = {
        'nombre': nombre,
        'ruc': _rucCtrl.text.trim().isNotEmpty ? _rucCtrl.text.trim() : null,
        'direccion': _direccionCtrl.text.trim().isNotEmpty ? _direccionCtrl.text.trim() : null,
        'telefono': _telefonoCtrl.text.trim().isNotEmpty ? _telefonoCtrl.text.trim() : null,
        'email': _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        'hora_entrada': _horaEntradaCtrl.text.trim().isNotEmpty ? _horaEntradaCtrl.text.trim() : null,
        'tolerancia_minutos': int.tryParse(_toleranciaCtrl.text) ?? 0,
      };

      final inserted = await supabase.from('empresas').insert([payload]).select().maybeSingle();
      if (inserted != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empresa creada')));
        // limpiar form
        _nombreCtrl.clear();
        _rucCtrl.clear();
        _direccionCtrl.clear();
        _telefonoCtrl.clear();
        _emailCtrl.clear();
        _horaEntradaCtrl.clear();
        _toleranciaCtrl.text = '15';
        // recargar lista
        await _loadCompanies();
      }
    } catch (e) {
      debugPrint('Error creando empresa (EmpresasPage): $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creando empresa: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _rucCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _horaEntradaCtrl.dispose();
    _toleranciaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16, top: 12),
      child: Column(
        children: [
          // Profile card with user info
          const SizedBox(height: 12),
          ProfileCard(userName: widget.userName, institutionName: 'NEXUS', role: 'Super Administrador'),
          const SizedBox(height: 12),

          // Form card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.apartment, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Nueva Empresa', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nombreCtrl,
                    decoration: InputDecoration(hintText: 'Nombre de la Empresa', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rucCtrl,
                    decoration: InputDecoration(hintText: 'RUC', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(hintText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _telefonoCtrl,
                          decoration: InputDecoration(hintText: 'Teléfono', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _direccionCtrl,
                          decoration: InputDecoration(hintText: 'Dirección', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _horaEntradaCtrl,
                          readOnly: true,
                          onTap: () async {
                            // abrir selector de hora
                            TimeOfDay initial = TimeOfDay.now();
                            if (_horaEntradaCtrl.text.isNotEmpty) {
                              final parts = _horaEntradaCtrl.text.split(':');
                              if (parts.length == 2) {
                                final h = int.tryParse(parts[0]) ?? initial.hour;
                                final m = int.tryParse(parts[1]) ?? initial.minute;
                                initial = TimeOfDay(hour: h, minute: m);
                              }
                            }
                            final picked = await showTimePicker(context: context, initialTime: initial);
                            if (picked != null) {
                              final hh = picked.hour.toString().padLeft(2, '0');
                              final mm = picked.minute.toString().padLeft(2, '0');
                              _horaEntradaCtrl.text = '$hh:$mm';
                            }
                          },
                          decoration: InputDecoration(hintText: 'Hora de Entrada (HH:MM)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        child: DropdownButtonFormField<String>(
                          value: _toleranciaCtrl.text,
                          items: ['0','5','10','15','20','30','45','60']
                              .map((m) => DropdownMenuItem<String>(value: m, child: Text('$m')))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _toleranciaCtrl.text = v);
                          },
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createEmpresa,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD92344)),
                      child: _isCreating ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Crear Empresa'),
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          // Heading for registered companies
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Empresas Registradas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text('${_companies.length} empresas', style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // List of companies
          Column(
            children: _companies.map((c) {
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.apartment, color: Colors.red)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text('RUC: ${c['ruc'] ?? ''}', style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: const Text('BDL24X8K', style: TextStyle(fontSize: 12))),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: const Text('Código de Registro', style: TextStyle(fontSize: 12))),
                                ])
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              IconButton(onPressed: () {}, icon: const Icon(Icons.edit, color: Colors.red)),
                              IconButton(onPressed: () {}, icon: const Icon(Icons.delete_forever, color: Colors.red)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(child: Text(c['direccion'] ?? '', style: const TextStyle(color: Colors.grey))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(c['telefono'] ?? '', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(width: 12),
                          const Icon(Icons.email, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(c['email'] ?? '', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Entrada: ${c['hora_entrada'] ?? '-'} (±${c['tolerancia_minutos'] ?? 0} min)', style: const TextStyle(color: Colors.grey)),
                          Text('Registrada: --', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Ver Detalles')))
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
