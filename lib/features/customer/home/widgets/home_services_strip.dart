import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/booking_model.dart';

class HomeServicesStrip extends StatelessWidget {
  final List<ServiceCategoryModel> categories;
  final String? selectedSlug;
  final String Function(String name) shortName;
  final IconData Function(String slug) iconFor;
  final void Function(ServiceCategoryModel category) onTap;
  final VoidCallback? onViewAll;

  const HomeServicesStrip({
    super.key,
    required this.categories,
    required this.selectedSlug,
    required this.shortName,
    required this.iconFor,
    required this.onTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text(
                'Services',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const Spacer(),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: const Text(
                    'View all',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final c = categories[i];
              final selected = selectedSlug == c.slug;
              final color = AppColors.categoryColor(c.slug);
              return _ServiceChip(
                label: shortName(c.name),
                rate: c.baseRate.toInt(),
                icon: iconFor(c.slug),
                color: color,
                selected: selected,
                onTap: () => onTap(c),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final int rate;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceChip({
    required this.label,
    required this.rate,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 72,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : Colors.grey.shade200,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))
              else
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: selected ? color : AppColors.navy,
                ),
              ),
              Text(
                '₹$rate/hr',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
