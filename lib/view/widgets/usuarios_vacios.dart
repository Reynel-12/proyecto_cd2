import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_cd2/model/preferences.dart';

class UsuariosVacios extends StatefulWidget {
  const UsuariosVacios({super.key});

  @override
  State<UsuariosVacios> createState() => _UsuariosVacioState();
}

class _UsuariosVacioState extends State<UsuariosVacios>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Inicializar el controlador de animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Animación de escala para el icono
    _iconScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.0,
              end: 1.2,
            ).chain(CurveTween(curve: Curves.elasticOut)),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.2,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 40,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );

    // Animación de fade in para los textos
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    // Animación de deslizamiento para los textos
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    // Animación para el botón

    // Iniciar la animación
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double iconSize = isMobile ? 80.0 : (isTablet ? 100.0 : 120.0);
    final double titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);
    final double subtitleFontSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
    final double contentPadding = isMobile ? 20.0 : (isTablet ? 30.0 : 40.0);
    final double cardWidth = isMobile
        ? screenSize.width * 0.9
        : (isTablet ? screenSize.width * 0.7 : screenSize.width * 0.5);

    return Center(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: cardWidth,
            padding: EdgeInsets.all(contentPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Provider.of<TemaProveedor>(context).esModoOscuro
                    ? [
                        Color.fromRGBO(30, 30, 30, 1),
                        Color.fromRGBO(30, 30, 30, 1),
                      ]
                    : [Colors.white, Colors.white],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono animado
                Transform.scale(
                  scale: _iconScaleAnimation.value,
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Color.fromRGBO(50, 50, 80, 0.3)
                          : Color.fromRGBO(240, 240, 255, 0.7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Círculo pulsante
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.8, end: 1.2),
                          duration: Duration(seconds: 2),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: iconSize * 0.8,
                                height: iconSize * 0.8,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                          // Repetir la animación
                          onEnd: () {
                            setState(() {});
                          },
                        ),

                        // Icono principal
                        Icon(
                          Icons.person_off,
                          size: iconSize * 0.5,
                          color: Colors.blueAccent,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: contentPadding * 0.7),

                // Título con animación
                Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeInAnimation.value,
                    child: Text(
                      '!Usuarios vacío!',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                SizedBox(height: contentPadding * 0.3),

                // Subtítulo con animación
                Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeInAnimation.value,
                    child: Text(
                      'No hay usuarios por mostrar',
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
