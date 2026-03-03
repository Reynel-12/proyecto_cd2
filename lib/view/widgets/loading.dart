import 'package:flutter/material.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class CargandoInventario extends StatelessWidget {
  const CargandoInventario({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      body: _buildLoadingState(),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.black
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Provider.of<TemaProveedor>(context).esModoOscuro
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar skeleton
              _buildShimmerCircle(48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerLine(180, 16),
                    const SizedBox(height: 8),
                    _buildShimmerLine(120, 12),
                  ],
                ),
              ),
              _buildShimmerLine(60, 16, alignment: MainAxisAlignment.end),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerCircle(double size) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildShimmerLine(
    double width,
    double height, {
    MainAxisAlignment? alignment,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
