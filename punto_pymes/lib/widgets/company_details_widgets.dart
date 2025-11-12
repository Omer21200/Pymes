import 'package:flutter/material.dart';

class CompanyHeader extends StatelessWidget {
  final String name;
  final String logoUrl;
  final String codigo;

  const CompanyHeader({required this.name, required this.logoUrl, required this.codigo, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade100),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: logoUrl.isNotEmpty ? Image.network(logoUrl, fit: BoxFit.cover) : const Icon(Icons.apartment, color: Colors.red),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [Text(codigo, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)), const SizedBox(width: 8), const Icon(Icons.copy, size: 16, color: Colors.red)]),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class InfoSection extends StatelessWidget {
  final String ruc;
  final String telefono;
  final String email;
  final String direccion;

  const InfoSection({required this.ruc, required this.telefono, required this.email, required this.direccion, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Información General', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.receipt, size: 16, color: Colors.grey), const SizedBox(width: 6), Expanded(child: Text('RUC: $ruc'))]),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.phone, size: 16, color: Colors.grey), const SizedBox(width: 6), Text(telefono)]),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.email, size: 16, color: Colors.grey), const SizedBox(width: 6), Text(email)]),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.grey), const SizedBox(width: 6), Expanded(child: Text(direccion))]),
        ]),
      ),
    );
  }
}

class AttendanceConfigSection extends StatelessWidget {
  final String horaEntrada;
  final String horaSalida;
  final String horaAlmuerzo;
  final String horaEntradaAlmuerzo;
  final String toleranciaMinutos;

  const AttendanceConfigSection({required this.horaEntrada, required this.horaSalida, required this.horaAlmuerzo, required this.horaEntradaAlmuerzo, required this.toleranciaMinutos, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Configuración de Asistencia', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hora de Entrada: $horaEntrada', style: const TextStyle(color: Colors.grey)), Text('Tolerancia: $toleranciaMinutos min', style: const TextStyle(color: Colors.grey))]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hora de Salida: $horaSalida', style: const TextStyle(color: Colors.grey)), Text('Hora Almuerzo: $horaAlmuerzo', style: const TextStyle(color: Colors.grey))]),
          const SizedBox(height: 8),
          Text('Entrada Almuerzo: $horaEntradaAlmuerzo', style: const TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}

class StatsSection extends StatelessWidget {
  final String empleadosRegistrados;
  final String administradores;

  const StatsSection({required this.empleadosRegistrados, required this.administradores, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Empleados Registrados', style: TextStyle(color: Colors.grey)), const SizedBox(height: 6), Text(empleadosRegistrados, style: const TextStyle(fontWeight: FontWeight.w700))])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Administradores', style: TextStyle(color: Colors.grey)), const SizedBox(height: 6), Text(administradores, style: const TextStyle(fontWeight: FontWeight.w700))])),
        ]),
      ),
    );
  }
}
