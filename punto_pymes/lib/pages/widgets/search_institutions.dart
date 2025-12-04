import 'package:flutter/material.dart';

class SearchInstitutions extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final String hintText;
  final bool showTitle;

  const SearchInstitutions({
    super.key,
    this.onChanged,
    this.hintText = 'Buscar institución...',
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle)
          const Text(
            'Empleado - Selecciona tu institución',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        const SizedBox(height: 8),
        Material(
          elevation: 2,

          borderRadius: BorderRadius.circular(30),
          child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
