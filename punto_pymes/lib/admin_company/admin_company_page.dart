import 'package:flutter/material.dart';
import '../../main.dart';
import '../../widgets/admin_nav_pill.dart';
import 'inicio_admin.dart';
import 'anuncios_admin.dart';
import 'registros_admin.dart';

class AdminCompanyPage extends StatefulWidget {
  final String userId;
  final String? companyName;

  const AdminCompanyPage({required this.userId, this.companyName, super.key});

  @override
  State<AdminCompanyPage> createState() => _AdminCompanyPageState();
}

class _AdminCompanyPageState extends State<AdminCompanyPage> {
  int _selectedIndex = 0;

  Widget _bodyForIndex() {
    switch (_selectedIndex) {
      case 0:
        return InicioAdmin(userId: widget.userId, companyName: widget.companyName);
      case 1:
        return AnunciosAdmin(userId: widget.userId, companyName: widget.companyName);
      case 2:
        return RegistrosAdmin(userId: widget.userId, companyName: widget.companyName);
      default:
        return InicioAdmin(userId: widget.userId, companyName: widget.companyName);
    }
  }

  void _onFloating() {
    // acción rápida: navegar a crear anuncio
    Navigator.push(context, MaterialPageRoute(builder: (_) => AnunciosAdmin(userId: widget.userId, companyName: widget.companyName, createMode: true)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.companyName ?? 'Panel de Admin'),
        backgroundColor: const Color(0xFFD92344),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/access-selection', (route) => false);
              }
            },
          )
        ],
      ),
      body: _bodyForIndex(),
      bottomNavigationBar: Material(
        elevation: 8,
        color: Colors.white,
        child: SafeArea(
          bottom: true,
          child: Container(
            height: 96,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.95,
                child: AdminNavPill(selectedIndex: _selectedIndex, onSelect: (i) => setState(() => _selectedIndex = i), onFloating: _onFloating),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
