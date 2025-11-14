import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../widgets/profile_card.dart';
import '../main.dart';

class AdminsPage extends StatefulWidget {
  final String userName;

  const AdminsPage({this.userName = 'Super Admin', super.key});

  @override
  State<AdminsPage> createState() => _AdminsPageState();
}

class _AdminsPageState extends State<AdminsPage> {
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _admins = [];

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  String? _selectedCompanyId;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _loadAdmins();
  }

  Future<void> _loadCompanies() async {
    try {
      final res = await supabase.from('empresas').select().order('nombre');
      final List resList = res as List;
      setState(() {
        _companies = resList
            .map<Map<String, dynamic>>(
              (e) => {
                'id': (e['id'] ?? '').toString(),
                'name': (e['nombre'] ?? e['name'] ?? '').toString(),
              },
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Error cargando empresas en AdminsPage: $e');
    }
  }

  Future<void> _loadAdmins() async {
    try {
      final res = await supabase.from('usuarios').select().eq('rol', 'admin');
      final List resList = res as List;
      setState(() {
        _admins = resList
            .map<Map<String, dynamic>>(
              (e) => {
                'id': (e['id'] ?? '').toString(),
                'nombre': (e['nombre_completo'] ?? e['nombre'] ?? '')
                    .toString(),
                'email': (e['email'] ?? e['correo'] ?? '').toString(),
                'telefono': (e['telefono'] ?? '').toString(),
                'empresa_id': (e['empresa_id'] ?? '').toString(),
              },
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Error cargando admins: $e');
    }
  }

  Future<void> _createAdmin() async {
    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final empresaId = _selectedCompanyId;
    // Validaciones básicas
    final emailPattern = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (nombre.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!emailPattern.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El correo no tiene un formato válido'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Email inválido intentado: "$email" (len=${email.length})');
      return;
    }

    setState(() => _isCreating = true);
    try {
      // Normalizar email: lowercase y eliminar caracteres invisibles/control
      String normalizedEmail = email.toLowerCase();
      normalizedEmail = normalizedEmail.replaceAll(
        RegExp(r'[\u0000-\u001F\u007F-\u009F\u200B-\u200F\uFEFF]'),
        '',
      );
      debugPrint('Email raw: "$email" (len=${email.length})');
      debugPrint(
        'Email normalized: "$normalizedEmail" (len=${normalizedEmail.length})',
      );
      debugPrint('Email runes: ${normalizedEmail.runes.toList()}');
      debugPrint('Email codeUnits: ${normalizedEmail.codeUnits}');

      // 1) Crear usuario en Supabase Auth
      debugPrint('Attempting signUp with normalized email: "$normalizedEmail"');
      final signUpResp = await supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
      );
      final userId = signUpResp.user?.id;

      // 2) Insertar metadata en tabla usuarios
      // Hashear la contraseña para almacenarla en contrasena_hash
      final hashed = sha256.convert(utf8.encode(password)).toString();

      final userInsert = {
        if (userId != null) 'id': userId,
        'empresa_id': empresaId,
        'nombre_completo': nombre,
        'email': normalizedEmail,
        'contrasena_hash': hashed,
        'telefono': _telefonoCtrl.text.trim().isNotEmpty
            ? _telefonoCtrl.text.trim()
            : null,
        'rol': 'admin',
        'estado': true,
      };

      final inserted = await supabase
          .from('usuarios')
          .insert([userInsert])
          .select()
          .maybeSingle();
      if (inserted != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Admin creado')));
        _nombreCtrl.clear();
        _emailCtrl.clear();
        _passwordCtrl.clear();
        _selectedCompanyId = null;
        await _loadAdmins();
      }
    } catch (e) {
      debugPrint('Error creando admin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creando admin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _deleteAdmin(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Eliminar este administrador?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // Eliminar metadata
      await supabase.from('usuarios').delete().eq('id', id);
      // NOTA: eliminar también en Auth requiere la service_role; en cliente solo borramos metadata
      await _loadAdmins();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Admin eliminado')));
    } catch (e) {
      debugPrint('Error eliminando admin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error eliminando admin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          ProfileCard(
            userName: widget.userName,
            institutionName: 'NEXUS',
            role: 'Super Administrador',
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Gestión de Administradores',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.person_add, color: Colors.red),
                    title: Text('Nuevo Administrador'),
                    subtitle: Text(
                      'Crea credenciales para un admin de empresa',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nombreCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nombre Completo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      hintText: 'admin@empresa.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _telefonoCtrl,
                    decoration: InputDecoration(
                      hintText: 'Celular',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCompanyId,
                    items: _companies
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c['id'].toString(),
                            child: Text(c['name'].toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCompanyId = v),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    hint: const Text('Selecciona una empresa'),
                  ),
                  const SizedBox(height: 8),
                  // Contraseña: el usuario la ingresa manualmente
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createAdmin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD92344),
                        foregroundColor: Colors.white,
                      ),
                      child: _isCreating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Crear Administrador'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            'Administradores Registrados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Column(
            children: _admins.map((a) {
              final companyName = _companies.firstWhere(
                (c) => c['id'] == (a['empresa_id'] ?? ''),
                orElse: () => {'name': '—'},
              )['name'];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (a['nombre'] ?? 'U')
                          .toString()
                          .substring(0, 1)
                          .toUpperCase(),
                    ),
                  ),
                  title: Text(a['nombre'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['email'] ?? ''),
                      if ((a['telefono'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tel: ${a['telefono']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        companyName,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    onPressed: () => _deleteAdmin(a['id']),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
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
