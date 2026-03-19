import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dreamloop/config/theme.dart';

/// Shimmer loading placeholder widget.
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: DreamColors.backgroundCard,
      highlightColor: DreamColors.backgroundSurface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: DreamColors.backgroundCard,
        ),
      ),
    );
  }
}
