import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/machine_state.dart';
import '../../models/recipe.dart';
import '../../models/recipe_step.dart';
import '../../services/barista_ble_service.dart';
import '../../theme/app_theme.dart';
import 'recipe_detail_dialog.dart';

/// Modal dialog providing immediate guidance when a multi-step recipe pauses
/// at the end of Step 1, clearly instructing the user on what to do for Step 2.
class Step2InstructionDialog extends StatelessWidget {
  final Recipe recipe;
  final BaristaBleService bleService;
  final void Function(Recipe recipe)? onCustomize;

  const Step2InstructionDialog({
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
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: min(720, MediaQuery.of(ctx).size.height * 0.88),
          ),
          child: Material(
            color: Colors.transparent,
            child: Step2InstructionDialog(
              recipe: recipe,
              bleService: bleService,
              onCustomize: onCustomize,
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curve = Curves.easeOutBack.transform(anim.value);
        return Transform.scale(
          scale: 0.92 + (0.08 * curve),
          child: Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = bleService.telemetry.machineState == MachineState.recipePaused;
    final hasStep2 = recipe.steps.length >= 2;
    final RecipeStep? step2 = hasStep2 ? recipe.steps[1] : null;

    final step2Instruction = step2?.instruction ??
        (recipe.instructions.length >= 2 ? recipe.instructions[1] : 'Add remaining ingredients and press dial.');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPaused ? AppTheme.amberHeat : AppTheme.goldPrimary,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPaused ? AppTheme.amberHeat : AppTheme.goldPrimary).withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPaused
                    ? [AppTheme.amberHeat.withOpacity(0.2), Colors.transparent]
                    : [AppTheme.goldPrimary.withOpacity(0.2), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
              border: const Border(
                bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPaused
                        ? AppTheme.amberHeat.withOpacity(0.2)
                        : AppTheme.goldPrimary.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPaused ? AppTheme.amberHeat : AppTheme.goldPrimary,
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    isPaused ? Icons.pause_circle_filled : Icons.bolt,
                    color: isPaused ? AppTheme.amberHeat : AppTheme.goldPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          color: AppTheme.crema,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isPaused
                                  ? AppTheme.amberHeat.withOpacity(0.2)
                                  : AppTheme.goldPrimary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPaused ? '⏸️ PAUSED AT STEP 1' : 'STEP 2 PREVIEW',
                              style: TextStyle(
                                color: isPaused ? AppTheme.amberHeat : AppTheme.goldLight,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Action Required',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Alert Callout
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPaused
                          ? AppTheme.amberHeat.withOpacity(0.12)
                          : AppTheme.cyanCold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPaused
                            ? AppTheme.amberHeat.withOpacity(0.4)
                            : AppTheme.cyanCold.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isPaused ? Icons.touch_app : Icons.info_outline,
                          size: 18,
                          color: isPaused ? AppTheme.amberHeat : AppTheme.cyanCold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isPaused
                                ? 'Step 1 has completed and the machine motor has cut off. Complete the action below, then press the center dial on the Barista machine to resume.'
                                : 'Step 1 is currently in progress. Prepare the ingredients below so you can add them immediately when the machine pauses.',
                            style: TextStyle(
                              color: isPaused ? AppTheme.crema : AppTheme.textSecondary,
                              fontSize: 12.5,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // What is Step 2? Primary Card
                  const Text(
                    'WHAT TO DO NOW FOR STEP 2',
                    style: TextStyle(
                      color: AppTheme.goldPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceInput,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5), width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.restaurant, size: 18, color: AppTheme.goldLight),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step2Instruction,
                            style: const TextStyle(
                              color: AppTheme.crema,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4-Step Action Checklist
                  const Text(
                    'QUICK CHECKLIST',
                    style: TextStyle(
                      color: AppTheme.amberHeat,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildChecklistItem('1', 'Remove the jug lid safely.'),
                  const SizedBox(height: 6),
                  _buildChecklistItem(
                    '2',
                    'Add Step 2 ingredients directly into the jug.',
                  ),
                  const SizedBox(height: 6),
                  _buildChecklistItem('3', 'Securely close the lid.'),
                  const SizedBox(height: 6),
                  _buildChecklistItem(
                    '4',
                    'Press the center dial on the Barista machine to begin Step 2!',
                    icon: Icons.touch_app,
                  ),

                  // Step 2 Machine Parameters
                  if (step2 != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceInput,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat('Duration', '${step2.totalDurationSeconds}s', Icons.timer_outlined),
                          Container(width: 1, height: 22, color: AppTheme.borderSubtle),
                          _buildMiniStat('Temperature', '${step2.maxTemp}°C', Icons.thermostat_outlined),
                          Container(width: 1, height: 22, color: AppTheme.borderSubtle),
                          _buildMiniStat('Peak RPM', '${step2.peakRpm}', Icons.rotate_right),
                        ],
                      ),
                    ),
                  ],

                  // Ingredients Reference
                  if (recipe.ingredients.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(top: 6),
                        title: const Text(
                          'View Recipe Ingredients',
                          style: TextStyle(
                            color: AppTheme.goldLight,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        leading: const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.goldLight),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceInput,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: recipe.ingredients
                                  .map((ing) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('• ',
                                                style: TextStyle(
                                                    color: AppTheme.goldPrimary,
                                                    fontWeight: FontWeight.w800)),
                                            Expanded(
                                              child: Text(
                                                ing,
                                                style: const TextStyle(
                                                  color: AppTheme.crema,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.borderSubtle, width: 1),
              ),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.crema,
                    side: const BorderSide(color: AppTheme.borderSubtle),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.menu_book_outlined, size: 14),
                  label: const Text('Full Guide', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    RecipeDetailDialog.show(
                      context,
                      recipe: recipe,
                      bleService: bleService,
                      onCustomize: onCustomize,
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Got It — Ready for Step 2',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String num, String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.amberHeat.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.amberHeat.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppTheme.amberHeat,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, size: 12, color: Colors.black)
                : Text(
                    num,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.crema,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.goldLight),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.crema,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9.5,
          ),
        ),
      ],
    );
  }
}
