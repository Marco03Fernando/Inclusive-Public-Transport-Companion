import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ChoiceTileButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ChoiceTileButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(
            minHeight: 58,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.black
                : AppColors.white,
            borderRadius: BorderRadius.circular(
              AppRadius.button,
            ),
            border: Border.all(
              color: AppColors.black,
              width: selected ? 2 : 1.3,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.white
                  : AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}