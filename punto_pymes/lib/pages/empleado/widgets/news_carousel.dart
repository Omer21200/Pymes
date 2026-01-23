import 'package:flutter/material.dart';
import 'dart:async';

import '../../../theme.dart';

class NewsCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> noticias;
  final VoidCallback? onNewsPressed;

  const NewsCarousel({super.key, required this.noticias, this.onNewsPressed});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _animationController;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    // viewportFraction reducido para dejar espacio lateral y que las tarjetas
    // se vean más compactas y centradas.
    // Aumentar viewportFraction para que las tarjetas ocupen más ancho
    _pageController = PageController(viewportFraction: 0.92, initialPage: 0);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || widget.noticias.isEmpty) return;
      final nextPage = (_currentPage + 1) % widget.noticias.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 2000),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _autoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.noticias.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.newspaper, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Sin noticias por el momento',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado con decoración
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.brandRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Noticias',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            if (widget.noticias.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.noticias.length} noticia${widget.noticias.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandRed,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Carrusel de noticias compacto
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: widget.noticias.length,
            itemBuilder: (context, index) {
              final noticia = widget.noticias[index];
              return _NewsCard(
                noticia: noticia,
                onPressed: widget.onNewsPressed,
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Indicadores de página (dots)
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.noticias.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentPage == index ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFFD92344)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NewsCard extends StatefulWidget {
  final Map<String, dynamic> noticia;
  final VoidCallback? onPressed;

  const _NewsCard({required this.noticia, this.onPressed});

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                // Imagen a la izquierda (más estrecha)
                SizedBox(
                  width: 120,
                  height: double.infinity,
                  child:
                      (widget.noticia['imagen_url'] != null &&
                          widget.noticia['imagen_url'].toString().isNotEmpty)
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          child: Image.network(
                            widget.noticia['imagen_url'].toString(),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey.shade400,
                                      size: 40,
                                    ),
                                  );
                                },
                            loadingBuilder:
                                (
                                  BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? progress,
                                ) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF3F3F4),
                          child: Icon(
                            Icons.newspaper,
                            color: Colors.grey.shade500,
                            size: 40,
                          ),
                        ),
                ),

                // Contenido a la derecha
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mostrar la etiqueta de prioridad encima del título.
                        // Preferir la etiqueta enviada por la base (badge_text / etiqueta / label),
                        // si no existe, caer a 'Importante' cuando `es_importante` sea true.
                        Builder(
                          builder: (context) {
                            final mapa = widget.noticia;
                            final badgeText =
                                (mapa['badge_text'] ??
                                        mapa['etiqueta'] ??
                                        mapa['label'])
                                    ?.toString() ??
                                ((mapa['es_importante'] == true)
                                    ? 'Importante'
                                    : null);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (badgeText != null)
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentBlue.withAlpha(
                                          36,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: const TextStyle(
                                          color: AppColors.accentBlue,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (widget.noticia['titulo'] ??
                                                'Sin título')
                                            .toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        Text(
                          (widget.noticia['contenido'] ?? 'Sin descripción')
                              .toString(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppColors.accentBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Leer más',
                              style: const TextStyle(
                                color: Color(0xFF2B7AE4),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
