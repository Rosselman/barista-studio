import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'app_toast.dart';

class AboutBaristaDialog extends StatelessWidget {
  const AboutBaristaDialog({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => const AboutBaristaDialog(),
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
    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.goldPrimary, width: 1),
                    ),
                    child: const Icon(Icons.coffee, color: AppTheme.goldPrimary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BARISTA STUDIO',
                          style: TextStyle(
                            color: AppTheme.crema,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'v1.5.0 • Release',
                          style: TextStyle(
                            color: AppTheme.goldPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
              const SizedBox(height: 18),

              // Description
              const Text(
                'A dedicated Bluetooth LE companion and custom recipe manager for the Nespresso Barista W545 recipe maker.',
                style: TextStyle(
                  color: AppTheme.crema,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),

              // Developer Info Card
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
                    const Row(
                      children: [
                        Icon(Icons.code, size: 16, color: AppTheme.goldPrimary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'DEVELOPMENT & PROTOCOL',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Rosselman',
                      style: TextStyle(
                        color: AppTheme.crema,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Reconstructed SDataWay BLE protocol, proprietary 16-byte CRC-16 CCITT packet sequencer, and hardware EEPROM synchronization.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(const ClipboardData(text: 'https://reddit.com/u/Rosselman'));
                        AppToast.success(context, 'Reddit contact copied: /u/Rosselman');
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.forum_outlined, size: 15, color: AppTheme.goldPrimary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Reddit: /u/Rosselman',
                                style: TextStyle(
                                  color: AppTheme.crema,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.copy, size: 13, color: AppTheme.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Capabilities
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureItem(Icons.memory, '13 Hardware EEPROM Recipe Slots'),
                    const SizedBox(height: 6),
                    _buildFeatureItem(Icons.alt_route, 'Native Multi-Step Execution & Firmware Pause'),
                    const SizedBox(height: 6),
                    _buildFeatureItem(Icons.auto_awesome, 'Guided Barista & Dual-Stage Formulator'),
                    const SizedBox(height: 6),
                    _buildFeatureItem(Icons.share, 'Deep Linking & Universal Recipe Sharing'),
                    const SizedBox(height: 6),
                    _buildFeatureItem(Icons.speed, 'Variable Whisk Motor (300 – 4000 RPM)'),
                    const SizedBox(height: 6),
                    _buildFeatureItem(Icons.local_fire_department, 'Induction Heater Coiling (Cold – 70°C)'),
                    const SizedBox(height: 6),
                    _buildFeatureItem(Icons.sync_alt, 'Real-time Rotary Dial Telemetry'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildFeatureItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.goldLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
