import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/center_model.dart';
import '../constants.dart';
import 'app_widgets.dart';

class CenterCard extends StatelessWidget {
  final CenterModel center;
  final VoidCallback onBook;

  const CenterCard({super.key, required this.center, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.soft,
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onBook,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.location_city_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            center.name,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                color: AppColors.textDark),
                            textDirection: TextDirection.rtl,
                          ),
                          Text(
                            center.city,
                            style: GoogleFonts.cairo(
                                color: AppColors.orange,
                                fontSize: 13,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: center.isActive ? 'مفتوح' : 'مغلق',
                      color: center.isActive ? AppColors.success : AppColors.error,
                      icon: center.isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 16),

                // Info
                InfoRow(Icons.pin_drop_outlined, center.address),
                InfoRow(Icons.access_time_rounded, center.hours),
                InfoRow(Icons.phone_iphone_rounded, center.phone),
                
                const SizedBox(height: 16),

                // Slots
                if (center.isActive) ...[
                  Text(
                    'المواعيد المتاحة اليوم:',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textLight,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: center.timeSlots.take(4).map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                          ),
                          child: Text(t,
                              style: GoogleFonts.cairo(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        )).toList()
                      ..addAll(center.timeSlots.length > 4
                          ? [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('+${center.timeSlots.length - 4}',
                                    style: GoogleFonts.cairo(
                                        color: AppColors.orange, 
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              )
                            ]
                          : []),
                  ),
                ] else
                   Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'الموعد غير متاح حاليا في هذا المركز',
                      style: GoogleFonts.cairo(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                const SizedBox(height: 24),

                // Action
                ElevatedButton(
                  onPressed: center.isActive ? onBook : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: center.isActive ? AppColors.primary : AppColors.textLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        center.isActive ? 'حجز موعد الآن' : 'غير متوفر',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Icon(center.isActive ? Icons.arrow_forward_rounded : Icons.block_flipped, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

