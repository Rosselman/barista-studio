import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/recipe.dart';
import '../../services/barista_ble_service.dart';
import '../../services/recipe_share_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import 'app_toast.dart';
import 'flash_recipe_dialog.dart';

class RecipeDetailDialog extends StatelessWidget {
  final Recipe recipe;
  final BaristaBleService bleService;
  final StorageService? storageService;
  final void Function(Recipe recipe)? onCustomize;
  final bool isSharedImport;
  final VoidCallback? onSavedToMyRecipes;

  const RecipeDetailDialog({
    super.key,
    required this.recipe,
    required this.bleService,
    this.storageService,
    this.onCustomize,
    this.isSharedImport = false,
    this.onSavedToMyRecipes,
  });

  static void show(
    BuildContext context, {
    required Recipe recipe,
    required BaristaBleService bleService,
    StorageService? storageService,
    void Function(Recipe recipe)? onCustomize,
    bool isSharedImport = false,
    VoidCallback? onSavedToMyRecipes,
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
              storageService: storageService,
              onCustomize: onCustomize,
              isSharedImport: isSharedImport,
              onSavedToMyRecipes: onSavedToMyRecipes,
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
                if (recipe.isCustom || isSharedImport)
                  IconButton(
                    icon: const Icon(Icons.share, color: AppTheme.goldLight, size: 20),
                    tooltip: 'Copy Share Code / Link',
                    onPressed: () {
                      final link = RecipeShareService.encodeShareUrl(recipe);
                      Clipboard.setData(ClipboardData(text: link));
                      AppToast.success(context, 'Share link copied to clipboard!');
                    },
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
                  if (isSharedImport) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppTheme.goldLight, size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SHARED RECIPE PREVIEW',
                                  style: TextStyle(
                                    color: AppTheme.goldLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Imported from a shared link. Save it to My Recipes with 1 tap or flash it directly to your machine.',
                                  style: TextStyle(
                                    color: AppTheme.crema,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Badges / Tags Wrap
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildBadge(
                        backgroundColor: AppTheme.goldPrimary.withOpacity(0.15),
                        borderColor: AppTheme.goldPrimary.withOpacity(0.4),
                        child: Text(
                          recipe.category,
                          style: const TextStyle(
                            color: AppTheme.goldLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _buildBadge(
                        backgroundColor: isCold
                            ? AppTheme.cyanCold.withOpacity(0.15)
                            : AppTheme.amberHeat.withOpacity(0.15),
                        borderColor:
                            isCold ? AppTheme.cyanCold : AppTheme.amberHeat,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              isCold
                                  ? Icons.ac_unit
                                  : Icons.local_fire_department,
                              size: 13,
                              color: isCold
                                  ? AppTheme.cyanCold
                                  : AppTheme.amberHeat,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCold ? 'Cold Foam' : '${recipe.maxTemp}°C Hot',
                              style: TextStyle(
                                color: isCold
                                    ? AppTheme.cyanCold
                                    : AppTheme.amberHeat,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (recipe.isMultiStep)
                        _buildBadge(
                          backgroundColor:
                              AppTheme.goldPrimary.withOpacity(0.18),
                          borderColor: AppTheme.goldPrimary,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.alt_route,
                                  size: 13, color: AppTheme.goldLight),
                              const SizedBox(width: 4),
                              Text(
                                'Multi-Step (${recipe.stepCount} Steps)',
                                style: const TextStyle(
                                  color: AppTheme.goldLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      for (final tag in recipe.tags)
                        if (tag != recipe.category &&
                            tag != 'Multi-Step' &&
                            !tag.toLowerCase().contains('step'))
                          _buildBadge(
                            backgroundColor: AppTheme.surfaceInput,
                            borderColor: AppTheme.borderSubtle,
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
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
                        Expanded(child: _buildStatItem('Duration', '${recipe.totalDurationSeconds}s', Icons.timer_outlined)),
                        Container(width: 1, height: 28, color: AppTheme.borderSubtle),
                        Expanded(child: _buildStatItem('Peak RPM', '${recipe.peakRpm}', Icons.rotate_right)),
                        Container(width: 1, height: 28, color: AppTheme.borderSubtle),
                        Expanded(child: _buildStatItem('Phases', '${recipe.activePhases.length}', Icons.layers_outlined)),
                        Container(width: 1, height: 28, color: AppTheme.borderSubtle),
                        Expanded(child: _buildStatItem('Max Temp', '${recipe.maxTemp}°C', Icons.thermostat_outlined)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Turmeric Staining Disclaimer
                  if (recipe.hasTurmeric) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 22),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.amberHeat.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.amberHeat.withOpacity(0.4)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.wb_sunny_outlined,
                              color: AppTheme.amberHeat, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TURMERIC CARE NOTICE',
                                  style: TextStyle(
                                    color: AppTheme.amberHeat,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Turmeric stains plastic pieces (such as the whisk or lid). Any stain can easily be removed by leaving the cleaned part exposed to direct sunlight.',
                                  style: TextStyle(
                                    color: AppTheme.crema,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Ingredients
                  if (recipe.ingredients.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 15, color: AppTheme.goldPrimary),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'INGREDIENTS',
                            style: TextStyle(
                              color: AppTheme.goldPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
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
                                            height: 1.35,
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

                  // Step-by-Step Preparation Guide
                  if (recipe.instructions.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.format_list_numbered, size: 15, color: AppTheme.goldPrimary),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'STEP-BY-STEP PREPARATION GUIDE',
                            style: TextStyle(
                              color: AppTheme.goldPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
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
                        children: [
                          for (int i = 0; i < recipe.instructions.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(top: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldPrimary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: AppTheme.goldLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    recipe.instructions[i],
                                    style: const TextStyle(
                                      color: AppTheme.crema,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Phase Breakdown
                  Row(
                    children: [
                      const Icon(Icons.tune, size: 15, color: AppTheme.goldPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          recipe.isMultiStep
                              ? 'MULTI-STEP EXECUTION PROFILE'
                              : 'MOTOR & HEATER PHASES',
                          style: const TextStyle(
                            color: AppTheme.goldPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (recipe.isMultiStep) ...[
                    for (int sIdx = 0; sIdx < recipe.steps.length; sIdx++) ...[
                      if (sIdx > 0) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.pause_circle_outline, color: AppTheme.goldLight, size: 22),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MACHINE PAUSE: ADD INGREDIENTS',
                                      style: TextStyle(
                                        color: AppTheme.goldLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'The motor stops and heating pauses automatically. Add your milk or ingredients into the jug, then press the center button on the machine dial to start Step 2.',
                                      style: TextStyle(
                                        color: AppTheme.crema,
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Step ${sIdx + 1}: ${recipe.steps[sIdx].name}',
                                style: const TextStyle(
                                  color: AppTheme.goldLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${recipe.steps[sIdx].totalDurationSeconds}s • ${recipe.steps[sIdx].peakRpm} RPM • ${recipe.steps[sIdx].isCold ? "Cold" : "${recipe.steps[sIdx].maxTemp}°C"}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (recipe.steps[sIdx].instruction != null &&
                          recipe.steps[sIdx].instruction!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            'Action: ${recipe.steps[sIdx].instruction!}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      for (int pIdx = 0; pIdx < recipe.steps[sIdx].phases.length; pIdx++)
                        if (recipe.steps[sIdx].phases[pIdx].isActive)
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
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceCard,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${pIdx + 1}',
                                      style: const TextStyle(
                                        color: AppTheme.goldLight,
                                        fontSize: 10,
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
                                        'Phase ${pIdx + 1}: ${recipe.steps[sIdx].phases[pIdx].duration}s @ ${recipe.steps[sIdx].phases[pIdx].speed} RPM (accel ${recipe.steps[sIdx].phases[pIdx].accel})',
                                        style: const TextStyle(
                                          color: AppTheme.crema,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Heat: ${recipe.steps[sIdx].phases[pIdx].isCold ? "None (Cold)" : "${recipe.steps[sIdx].phases[pIdx].temp}°C"}',
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
                    ],
                  ] else ...[
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
                  ],
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
                if (isSharedImport && storageService != null) ...[
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.bookmark_add, size: 18),
                      label: const Text(
                        'Save to My Recipes',
                        style: TextStyle(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () async {
                        await storageService!.saveCustomRecipe(recipe);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          AppToast.success(context, 'Saved "${recipe.name}" to My Recipes!');
                          onSavedToMyRecipes?.call();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.flash_on, size: 16),
                      label: const Text('Flash', maxLines: 1, overflow: TextOverflow.ellipsis),
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
                ] else ...[
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

  Widget _buildBadge({
    required Widget child,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
