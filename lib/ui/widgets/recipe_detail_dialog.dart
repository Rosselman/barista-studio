import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../services/barista_ble_service.dart';
import '../../theme/app_theme.dart';
import 'flash_recipe_dialog.dart';

class RecipeDetailDialog extends StatelessWidget {
  final Recipe recipe;
  final BaristaBleService bleService;
  final void Function(Recipe recipe)? onCustomize;

  const RecipeDetailDialog({
    super.key,
    required this.recipe,
    required this.bleService,
    this.onCustomize,
  });

  static void show(
    BuildContext context, {
    required Recipe recipe,
    required BaristaBleService bleService,
    void Function(Recipe recipe)? onCustomize,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppTheme.borderSubtle),
      ),
      builder: (ctx) => RecipeDetailDialog(
        recipe: recipe,
        bleService: bleService,
        onCustomize: onCustomize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCold = recipe.isCold;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title & Badges
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            color: AppTheme.crema,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.category,
                          style: const TextStyle(
                            color: AppTheme.goldPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isCold
                          ? AppTheme.cyanCold.withOpacity(0.15)
                          : AppTheme.amberHeat.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCold ? AppTheme.cyanCold : AppTheme.amberHeat,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCold ? Icons.ac_unit : Icons.local_fire_department,
                          size: 14,
                          color: isCold ? AppTheme.cyanCold : AppTheme.amberHeat,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCold ? 'Cold Foam' : '${recipe.maxTemp}°C Hot',
                          style: TextStyle(
                            color: isCold ? AppTheme.cyanCold : AppTheme.amberHeat,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                recipe.description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Phase Breakdown
              const Text(
                'Barista Motor & Thermal Sequence',
                style: TextStyle(
                  color: AppTheme.crema,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < recipe.activePhases.length; i++) ...[
                      if (i > 0) const Divider(color: AppTheme.borderSubtle, height: 16),
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppTheme.goldPrimary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: AppTheme.goldLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Phase ${i + 1}: ${recipe.activePhases[i].speed} RPM, ${recipe.activePhases[i].temp}°C',
                              style: const TextStyle(
                                color: AppTheme.crema,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${recipe.activePhases[i].duration}s',
                            style: const TextStyle(
                              color: AppTheme.goldLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Ingredients
              if (recipe.ingredients.isNotEmpty) ...[
                const Text(
                  'Ingredients',
                  style: TextStyle(
                    color: AppTheme.crema,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final ing in recipe.ingredients)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            color: AppTheme.goldPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            ing,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],

              // Preparation Steps
              if (recipe.instructions.isNotEmpty) ...[
                const Text(
                  'Preparation Instructions',
                  style: TextStyle(
                    color: AppTheme.crema,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < recipe.instructions.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.borderSubtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: AppTheme.crema,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            recipe.instructions[i],
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('Customize'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCustomize?.call(recipe);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.flash_on, size: 18),
                      label: const Text('Flash to Machine'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        FlashRecipeDialog.show(
                          context,
                          recipe: recipe,
                          bleService: bleService,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
