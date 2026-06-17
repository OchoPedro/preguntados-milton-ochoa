import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PowerupBar extends StatelessWidget {
  final String roomPlayerId;
  final bool   hasAnswered;

  const PowerupBar({
    super.key,
    required this.roomPlayerId,
    required this.hasAnswered,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _PowerupButton(
        icon: Icons.filter_2,
        label: '50/50',
        color: AppColors.info,
        enabled: !hasAnswered,
        onTap: () {},
      ),
      const SizedBox(width: 16),
      _PowerupButton(
        icon: Icons.timer_outlined,
        label: '+10s',
        color: AppColors.success,
        enabled: !hasAnswered,
        onTap: () {},
      ),
      const SizedBox(width: 16),
      _PowerupButton(
        icon: Icons.skip_next,
        label: 'Saltar',
        color: AppColors.warning,
        enabled: !hasAnswered,
        onTap: () {},
      ),
    ],
  );
}

class _PowerupButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final bool     enabled;
  final VoidCallback onTap;

  const _PowerupButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1.0 : 0.4,
    child: GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 3),
          Text(label,
            style: TextStyle(color: color, fontSize: 9,
              fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}
