import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';
import '../../theme.dart';
import 'widgets/superadmin_header.dart';
import 'gestion_horario.dart';

class DepartamentoDetallePage extends StatefulWidget {
  final String departamentoId;
  final String departamentoNombre;

  const DepartamentoDetallePage({
    super.key,
    required this.departamentoId,
    required this.departamentoNombre,
  });

  @override
  State<DepartamentoDetallePage> createState() =>
      _DepartamentoDetallePageState();
}

class _DepartamentoDetallePageState extends State<DepartamentoDetallePage> {
  bool _loadingHorario = true;
  Map<String, dynamic>? _horario;

  @override
  void initState() {
    super.initState();
    _fetchHorario();
  }

  Future<void> _fetchHorario() async {
    if (!mounted) return;
    setState(() => _loadingHorario = true);
    try {
      final data = await SupabaseService.instance.getHorarioPorDepartamento(
        widget.departamentoId,
      );
      if (mounted) {
        setState(() {
          _horario = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el horario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingHorario = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the horario content widget separately to avoid complex inline
    // collection-if/ternary logic inside the children list which can confuse
    // some analyzers. This keeps the widget tree clearer.
    Widget horarioWidget;
    if (_loadingHorario) {
      horarioWidget = const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_horario == null) {
      horarioWidget = Expanded(
        child: Center(child: Text('No hay un horario definido.')),
      );
    } else {
      horarioWidget = Expanded(child: _buildHorarioDetails());
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SuperadminHeader(
              showBack: true,
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.departamentoNombre,
                      style: AppTextStyles.largeTitle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => GestionHorarioPage(
                            departamentoId: widget.departamentoId,
                            horarioInicial: _horario,
                          ),
                        ),
                      );
                      if (result == true) _fetchHorario();
                    },
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: Text(_horario == null ? 'Crear' : 'Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.access_time,
                                      color: AppColors.accentBlue,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Horario del Departamento',
                                        style: AppTextStyles.sectionTitle,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Define la hora de entrada y salida para este horario.',
                                        style: AppTextStyles.subtitle,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // horario details area
                            horarioWidget,
                          ],
                        ),
                      ),
                      // no positioned button here — button moved to header row
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHorarioDetails() {
    final dias = {
      'Lunes': _horario!['lunes'] as bool? ?? false,
      'Martes': _horario!['martes'] as bool? ?? false,
      'Miércoles': _horario!['miercoles'] as bool? ?? false,
      'Jueves': _horario!['jueves'] as bool? ?? false,
      'Viernes': _horario!['viernes'] as bool? ?? false,
      'Sábado': _horario!['sabado'] as bool? ?? false,
      'Domingo': _horario!['domingo'] as bool? ?? false,
    };

    final diasLaborables = dias.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .join(', ');

    final String horaEntrada = _horario!['hora_entrada'] ?? 'N/A';
    final String horaSalida = _horario!['hora_salida'] ?? 'N/A';
    final String horaSalidaAlm = _horario!['hora_salida_almuerzo'] ?? '';
    final String horaRegresoAlm = _horario!['hora_regreso_almuerzo'] ?? '';
    final String tolerancia =
        '${_horario!['tolerancia_entrada_minutos'] ?? 0} minutos';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Días laborables
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Días Laborables',
                  style: AppTextStyles.smallLabel.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  diasLaborables.isNotEmpty ? diasLaborables : 'Ninguno',
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
          const Divider(height: 20, thickness: 1),

          // Hora de Entrada
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hora de Entrada',
                        style: AppTextStyles.smallLabel.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(horaEntrada, style: AppTextStyles.subtitle),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    horaEntrada,
                    style: AppTextStyles.smallLabel.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20, thickness: 1),

          // Hora de Salida
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hora de Salida',
                        style: AppTextStyles.smallLabel.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(horaSalida, style: AppTextStyles.subtitle),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    horaSalida,
                    style: AppTextStyles.smallLabel.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20, thickness: 1),

          // Salida/Regreso almuerzo (opcional)
          if (horaSalidaAlm.isNotEmpty || horaRegresoAlm.isNotEmpty) ...[
            const Divider(height: 20, thickness: 1),

            if (horaSalidaAlm.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salida a Comer',
                            style: AppTextStyles.smallLabel.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(horaSalidaAlm, style: AppTextStyles.subtitle),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        horaSalidaAlm,
                        style: AppTextStyles.smallLabel.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (horaRegresoAlm.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Regreso de Comer',
                            style: AppTextStyles.smallLabel.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(horaRegresoAlm, style: AppTextStyles.subtitle),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        horaRegresoAlm,
                        style: AppTextStyles.smallLabel.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // Tolerancia
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tolerancia de Entrada',
                  style: AppTextStyles.smallLabel.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(tolerancia, style: AppTextStyles.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
