import 'package:flutter/material.dart';
import '../models/producto.dart';
import 'package:intl/intl.dart';

class ProductButton extends StatelessWidget {
  final Producto producto;
  final int maxPosibles;
  final VoidCallback onTap;

  const ProductButton({
    super.key,
    required this.producto,
    required this.maxPosibles,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final bool isDisabled = maxPosibles <= 0;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Material(
        color: isDisabled ? Theme.of(context).colorScheme.surface : Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(16),
        elevation: isDisabled ? 0 : 4,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary,
                width: 2,
              ),
              gradient: isDisabled 
                  ? null 
                  : LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        const Color(0xFF922B21), // Rojo un poco más oscuro
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: Row(
              children: [
                Text(producto.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDisabled ? 'Sin inventario suficiente' : 'Puedes hacer ~$maxPosibles',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(producto.precioVenta),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
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
