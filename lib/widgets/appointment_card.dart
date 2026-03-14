import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/appointment_model.dart';
import '../constants.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onCancel;
  final VoidCallback? onPay;
  final VoidCallback? onViewResult;
  final bool isAdmin;
  final VoidCallback? onConfirm;
  final VoidCallback? onMarkDone;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onCancel,
    this.onPay,
    this.onViewResult,
    this.isAdmin = false,
    this.onConfirm,
    this.onMarkDone,
  });

  Color _statusColor() {
    switch (appointment.status) {
      case 'confirmed':  return AppColors.primary;
      case 'done':       return AppColors.success;
      case 'cancelled':  return AppColors.error;
      case 'expired':    return AppColors.textGrey;
      default:           return AppColors.orange;
    }
  }

  IconData _statusIcon() {
    switch (appointment.status) {
      case 'confirmed':  return Icons.check_circle_rounded;
      case 'done':       return Icons.task_alt_rounded;
      case 'cancelled':  return Icons.cancel_rounded;
      case 'expired':    return Icons.history_rounded;
      default:           return Icons.pending_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor();
    final isPaid   = appointment.paymentStatus == 'paid';
    final isDone   = appointment.status == 'done';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: sc.withOpacity(0.08),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(_statusIcon(), color: sc, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    appointment.statusAr,
                    style: GoogleFonts.cairo(
                      color: sc,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'رقم #${appointment.id?.substring(0, 6) ?? ""}',
                    style: GoogleFonts.cairo(
                      color: AppColors.textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Info
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.directions_car_filled_rounded, color: sc, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${appointment.marque} ${appointment.modele}',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppColors.textDark,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            Text(
                              appointment.immatriculation,
                              style: GoogleFonts.cairo(
                                color: AppColors.textLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 16),

                  // Appointment Details
                  _buildDetailRow(Icons.location_on_rounded, appointment.centerName),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.calendar_month_rounded, '${appointment.date}  •  ${appointment.time}'),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.category_rounded, '${appointment.vehicleType} — ${appointment.annee}'),

                  const SizedBox(height: 16),
                  
                  // Payment Info
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPaid ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(Icons.payments_rounded, size: 14, color: isPaid ? AppColors.success : AppColors.warning),
                            const SizedBox(width: 6),
                            Text(
                              isPaid ? 'مدفوع' : 'غير مدفوع',
                              style: GoogleFonts.cairo(
                                color: isPaid ? AppColors.success : AppColors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        appointment.paymentMethod == 'online' ? 'دفع إلكتروني' : 'دفع في المركز',
                        style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  if (appointment.message.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildMessageContainer(),
                  ],

                  if (isDone && appointment.hasIssues) ...[
                    const SizedBox(height: 16),
                    _buildIssueAlert(),
                  ],

                  // Actions
                  const SizedBox(height: 20),
                  _buildActions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cairo(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withOpacity(0.2)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_bubble_rounded, color: AppColors.orange, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              appointment.message,
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w600),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'تم اكتشاف مشكلة — اضغط لعرض التقرير',
              style: GoogleFonts.cairo(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w800),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final isDone = appointment.status == 'done';
    final isCancelled = appointment.status == 'cancelled';
    final isPending = appointment.status == 'pending';

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      textDirection: TextDirection.rtl,
      children: [
        if (isDone && onViewResult != null)
          _buildActionButton('تقرير الفحص', Icons.assignment_rounded, AppColors.primary, onViewResult!),
        if (!appointment.paymentStatus.contains('paid') && !isCancelled && appointment.paymentMethod == 'online' && onPay != null)
          _buildActionButton('ادفع الآن', Icons.payment_rounded, AppColors.success, onPay!),
        if (isAdmin && isPending && onConfirm != null)
          _buildActionButton('تأكيد', Icons.check_circle_rounded, AppColors.primary, onConfirm!),
        if (isAdmin && appointment.status == 'confirmed' && onMarkDone != null)
          _buildActionButton('تم الانتهاء', Icons.task_alt_rounded, AppColors.success, onMarkDone!),
        if (!isCancelled && !isDone && onCancel != null)
          _buildActionButton('إلغاء', Icons.cancel_rounded, AppColors.error, onCancel!),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.cairo(color: color, fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

