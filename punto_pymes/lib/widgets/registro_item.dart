import 'package:flutter/material.dart';

class RegistroItem extends StatelessWidget {
  final String usuarioId;
  final String? timestamp;
  final String? fotoUrl;

  const RegistroItem({required this.usuarioId, this.timestamp, this.fotoUrl, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(usuarioId),
        subtitle: Text(timestamp ?? ''),
        trailing: fotoUrl != null && fotoUrl!.isNotEmpty ? Image.network(fotoUrl!, width: 40, height: 40, fit: BoxFit.cover) : const SizedBox.shrink(),
        onTap: () {},
      ),
    );
  }
}
