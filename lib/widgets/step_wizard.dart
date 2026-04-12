import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StepWizard extends StatelessWidget {
  final String status;

  const StepWizard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    int currentStep = 0;
    switch (status) {
      case 'pending_payment': currentStep = 0; break;
      case 'held': currentStep = 1; break;
      case 'delivered': currentStep = 2; break;
      case 'released':
      case 'approved': currentStep = 3; break;
      case 'disputed': currentStep = 2; break; 
      default: currentStep = 0;
    }

    final steps = [
      _StepItem(label: 'Payment', icon: Icons.payment, active: currentStep >= 0, completed: currentStep > 0),
      _StepItem(label: 'Locked', icon: Icons.lock_outline, active: currentStep >= 1, completed: currentStep > 1),
      _StepItem(label: 'Shipped', icon: Icons.local_shipping_outlined, active: currentStep >= 2, completed: currentStep > 2),
      _StepItem(label: 'Approved', icon: Icons.check_circle_outline, active: currentStep >= 3, completed: currentStep > 3),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index % 2 == 0) {
          final stepIndex = index ~/ 2;
          return _buildStep(steps[stepIndex], theme);
        } else {
          final stepIndex = index ~/ 2;
          return _buildConnector(steps[stepIndex].completed, theme);
        }
      }),
    );
  }

  Widget _buildStep(_StepItem item, ThemeData theme) {
    final color = item.completed 
        ? theme.colorScheme.primary 
        : (item.active ? theme.colorScheme.primary : Colors.grey.shade300);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: item.completed ? theme.colorScheme.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Icon(
              item.completed ? Icons.check : item.icon,
              color: item.completed ? Colors.white : color,
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: item.active ? FontWeight.w700 : FontWeight.w500,
            color: item.active ? const Color(0xFF1A1A1A) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool completed, ThemeData theme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Container(
          height: 2,
          color: completed ? theme.colorScheme.primary : Colors.grey.withOpacity(0.1),
        ),
      ),
    );
  }
}

class _StepItem {
  final String label;
  final IconData icon;
  final bool active;
  final bool completed;

  _StepItem({required this.label, required this.icon, required this.active, required this.completed});
}
