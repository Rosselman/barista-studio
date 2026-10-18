import 'dart:math';
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: min(780, MediaQuery.of(ctx).size.height * 0.88),
          ),
          child: Material(
            color: Colors.transparent,
            child: RecipeDetailDialog(
              recipe: recipe,
              bleService: bleService,
              onCustomize: onCustomize,
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curve = Curves.easeOutCubic.transform(anim.value);
        return Transform.scale(
          scale: 0.94 + (0.06 * curve),
          child: Opacity(
            opacity: anim.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCold = recipe.isCold;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    recipe.name,
                    style: const TextStyle(
                      color: AppTheme.crema,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.borderSubtle, height: 1),

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
                        ),
                        child: Text(
                          recipe.category,
                          style: const TextStyle(
                            color: AppTheme.goldLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCold
                              ? AppTheme.cyanCold.withOpacity(0.15)
                              : AppTheme.amberHeat.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCold ? AppTheme.cyanCold : AppTheme.amberHeat,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCold ? Icons.ac_unit : Icons.local_fire_department,
                              size: 13,
                              color: isCold ? AppTheme.cyanCold : AppTheme.amberHeat,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCold ? 'Cold Foam' : '${recipe.maxTemp}°C Hot',
                              style: TextStyle(
                                color: isCold ? AppTheme.cyanCold : AppTheme.amberHeat,
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

                  // Telemetry Stats Row
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceInput,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Duration', '${recipe.totalDurationSeconds}s', Icons.timer_outlined),
                        Container(width: 1, height: 28, color: AppTheme.borderSubtle),
                        _buildStatItem('Peak RPM', '${recipe.peakRpm}', Icons.rotate_right),
                        Container(width: 1, height: 28, color: AppTheme.borderSubtle),
                        _buildStatItem('Phases', '${recipe.activePhases.length}', Icons.layers_outlined),
                        Container(width: 1, height: 28, color: AppTheme.borderSubtle),
                        _buildStatItem('Max Temp', '${recipe.maxTemp}°C', Icons.thermostat_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Ingredients & Preparation Guide
                  if (recipe.ingredients.isNotEmpty) ...[
                    const Text(
                      'INGREDIENTS & PREPARATION',
                      style: TextStyle(
                        color: AppTheme.goldPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceInput,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: recipe.ingredients
                            .map((ing) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ',
                                          style: TextStyle(
                                              color: AppTheme.goldPrimary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14)),
                                      Expanded(
                                        child: Text(
                                          ing,
                                          style: const TextStyle(
                                            color: AppTheme.crema,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Phase Breakdown
                  const Text(
                    'MOTOR & HEATER PHASES',
                    style: TextStyle(
                      color: AppTheme.goldPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < recipe.phases.length; i++)
                    if (recipe.phases[i].isActive)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceInput,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: AppTheme.goldLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Phase ${i + 1}: ${recipe.phases[i].duration}s @ ${recipe.phases[i].speed} RPM',
                                    style: const TextStyle(
                                      color: AppTheme.crema,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Heat: ${recipe.phases[i].isCold ? "None (Cold)" : "${recipe.phases[i].temp}°C"}',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Action Buttons Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.goldPrimary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.crema,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
