import 'package:flutter/material.dart';
import '../theme.dart';

class DepartmentSelectorCard extends StatelessWidget {
  final List<Map<String, dynamic>>? departamentos;
  final String? departamentoId;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final String label;

  const DepartmentSelectorCard({
    super.key,
    this.departamentos,
    this.departamentoId,
    this.onChanged,
    this.enabled = true,
    this.label = 'Departamento',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.smallLabel),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: departamentoId,
            items: (departamentos ?? []).map((d) {
              final id = d['id']?.toString() ?? '';
              final nombre = d['nombre']?.toString() ?? id;
              return DropdownMenuItem<String>(value: id, child: Text(nombre));
            }).toList(),
            onChanged: enabled
                ? (v) {
                    if (onChanged != null) onChanged!(v == '' ? null : v);
                  }
                : null,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            hint: const Text('Seleccione departamento'),
          ),
        ],
      ),
    );
  }
}
