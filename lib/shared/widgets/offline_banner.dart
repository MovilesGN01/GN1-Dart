import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.isOffline,
    required this.isFromCache,
  });

  final bool isOffline;
  final bool isFromCache;

  @override
  Widget build(BuildContext context) {
    if (!isOffline && !isFromCache) return const SizedBox.shrink();

    final message = isOffline
        ? 'No connection — showing saved data'
        : 'Cached data — refreshing...';

    final bgColor = isOffline
        ? const Color(0xFFD32F2F)
        : const Color(0xFFF57C00);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isOffline || isFromCache ? 36 : 0,
      color: bgColor,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
