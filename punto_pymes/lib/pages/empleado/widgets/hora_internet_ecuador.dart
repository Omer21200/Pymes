import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// Clase estática para acceder a la hora de Ecuador desde cualquier lugar
class EcuadorTimeManager {
  static DateTime? _currentTime;

  /// Obtiene la hora actual de Ecuador
  static DateTime? getCurrentTime() => _currentTime;

  /// Actualiza la hora actual (llamado internamente por el widget)
  static void _setCurrentTime(DateTime? time) {
    _currentTime = time;
  }
}

/// Widget profesional que obtiene la hora actual de Ecuador (America/Guayaquil)
/// desde worldtimeapi.org y muestra un reloj sincronizado en tiempo real.
class HoraInternetEcuador extends StatefulWidget {
  const HoraInternetEcuador({super.key});

  @override
  HoraInternetEcuadorState createState() => HoraInternetEcuadorState();

  /// Obtiene la hora actual de Ecuador del state del widget
  static DateTime? getEcuadorTime(BuildContext context) {
    final state = context.findAncestorStateOfType<HoraInternetEcuadorState>();
    return state?._currentServerTime;
  }
}

class HoraInternetEcuadorState extends State<HoraInternetEcuador>
    with SingleTickerProviderStateMixin {
  DateTime? _serverTimeAtFetch;
  DateTime? _deviceTimeAtFetch;
  Timer? _ticker;
  String? _timezone;
  String? _error;
  bool _loading = true;
  AnimationController? _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fetchServerTime();
  }

  Future<void> _fetchServerTime() async {
    _refreshController?.forward().then((_) {
      _refreshController?.reset();
    });

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(
        'https://worldtimeapi.org/api/timezone/America/Guayaquil',
      );
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data =
          jsonDecode(body) as Map<String, dynamic>;
      final String datetimeStr = data['datetime'] as String;
      final String timezone =
          (data['timezone'] as String?) ?? 'America/Guayaquil';
      final DateTime serverTime = DateTime.parse(datetimeStr).toUtc();

      setState(() {
        _serverTimeAtFetch = serverTime;
        _deviceTimeAtFetch = DateTime.now();
        _timezone = timezone;
        _loading = false;
        // Actualizar la hora global para que esté disponible en toda la app
        EcuadorTimeManager._setCurrentTime(serverTime);
      });

      _startTicker();
    } catch (e) {
      setState(() {
        _error = 'Error al obtener hora, recarge por favor.';
        _loading = false;
      });
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final cur = _currentServerTime;
        if (cur != null) {
          EcuadorTimeManager._setCurrentTime(cur);
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _refreshController?.dispose();
    super.dispose();
  }

  DateTime? get _currentServerTime {
    if (_serverTimeAtFetch == null || _deviceTimeAtFetch == null) return null;
    final elapsed = DateTime.now().difference(_deviceTimeAtFetch!);
    return _serverTimeAtFetch!.add(elapsed);
  }

  String _format(DateTime dt) {
    final guayaquilDt = dt.toUtc().subtract(const Duration(hours: 5));
    final hh = guayaquilDt.hour.toString().padLeft(2, '0');
    final mm = guayaquilDt.minute.toString().padLeft(2, '0');
    final ss = guayaquilDt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final cur = _currentServerTime;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD92344), Color(0xFFA81830)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD92344).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con icono y título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hora de Ecuador',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _timezone ?? 'America/Guayaquil',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                RotationTransition(
                  turns: _refreshController ?? AlwaysStoppedAnimation(0.0),
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    color: Colors.white,
                    onPressed: _loading ? null : _fetchServerTime,
                    tooltip: 'Actualizar',
                    splashRadius: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Contenido principal
            if (_loading) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ] else if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (cur != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _format(cur),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Courier',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Sin datos',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
