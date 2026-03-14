class InspectionItem {
  final String name;
  final String status; // 'ok' | 'warning' | 'fail'
  final String note;

  const InspectionItem({
    required this.name,
    required this.status,
    this.note = '',
  });

  factory InspectionItem.fromMap(Map<String, dynamic> m) => InspectionItem(
        name: m['name'] ?? '',
        status: m['status'] ?? 'ok',
        note: m['note'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status,
        'note': note,
      };
}

class AppointmentModel {
  final String? id;
  final String userId;
  final String clientName;
  final String centerId;
  final String centerName;
  // Véhicule
  final String marque;
  final String modele;
  final String immatriculation;
  final String annee;
  final String vehicleType;
  // RDV
  final String date;
  final String time;
  final String message;
  // Statut: 'pending' | 'confirmed' | 'done' | 'cancelled'
  final String status;
  // Paiement: method: 'online'|'center' — status: 'paid'|'unpaid'
  final String paymentMethod;
  final String paymentStatus;
  // Résultat inspection
  final List<InspectionItem> inspectionItems;
  final bool repairProposed;
  final bool repairAccepted;
  // Timestamps
  final DateTime? createdAt;

  const AppointmentModel({
    this.id,
    required this.userId,
    this.clientName = '',
    required this.centerId,
    required this.centerName,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    required this.annee,
    required this.vehicleType,
    required this.date,
    required this.time,
    this.message = '',
    this.status = 'pending',
    this.paymentMethod = 'center',
    this.paymentStatus = 'unpaid',
    this.inspectionItems = const [],
    this.repairProposed = false,
    this.repairAccepted = false,
    this.createdAt,
  });

  bool get hasIssues =>
      inspectionItems.any((i) => i.status == 'fail' || i.status == 'warning');

  String get statusAr {
    switch (status) {
      case 'pending':   return 'في الانتظار';
      case 'confirmed': return 'مؤكد';
      case 'done':      return 'منتهي';
      case 'cancelled': return 'ملغى';
      case 'expired':   return 'منتهي الصلاحية';
      default:          return status;
    }
  }

  bool get isPast {
    try {
      final now = DateTime.now();
      final parts = date.split('-');
      if (parts.length != 3) return false;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      final timeParts = time.split(':');
      final hour = timeParts.length > 0 ? int.tryParse(timeParts[0]) ?? 0 : 0;
      final min = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

      final apptDate = DateTime(year, month, day, hour, min);
      return apptDate.isBefore(now);
    } catch (_) {
      return false;
    }
  }

  factory AppointmentModel.fromMap(String id, Map<String, dynamic> m) =>
      AppointmentModel(
        id: id,
        userId: m['userId'] ?? '',
        clientName: m['clientName'] ?? '',
        centerId: m['centerId'] ?? '',
        centerName: m['centerName'] ?? '',
        marque: m['marque'] ?? '',
        modele: m['modele'] ?? '',
        immatriculation: m['immatriculation'] ?? '',
        annee: m['annee'] ?? '',
        vehicleType: m['vehicleType'] ?? '',
        date: m['date'] ?? '',
        time: m['time'] ?? '',
        message: m['message'] ?? '',
        status: m['status'] ?? 'pending',
        paymentMethod: m['paymentMethod'] ?? 'center',
        paymentStatus: m['paymentStatus'] ?? 'unpaid',
        inspectionItems: (m['inspectionItems'] as List<dynamic>? ?? [])
            .map((e) => InspectionItem.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        repairProposed: m['repairProposed'] ?? false,
        repairAccepted: m['repairAccepted'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'clientName': clientName,
        'centerId': centerId,
        'centerName': centerName,
        'marque': marque,
        'modele': modele,
        'immatriculation': immatriculation,
        'annee': annee,
        'vehicleType': vehicleType,
        'date': date,
        'time': time,
        'message': message,
        'status': status,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'inspectionItems': inspectionItems.map((i) => i.toMap()).toList(),
        'repairProposed': repairProposed,
        'repairAccepted': repairAccepted,
        'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };

  AppointmentModel copyWith({
    String? status,
    String? paymentStatus,
    List<InspectionItem>? inspectionItems,
    bool? repairProposed,
    bool? repairAccepted,
  }) =>
      AppointmentModel(
        id: id,
        userId: userId,
        clientName: clientName,
        centerId: centerId,
        centerName: centerName,
        marque: marque,
        modele: modele,
        immatriculation: immatriculation,
        annee: annee,
        vehicleType: vehicleType,
        date: date,
        time: time,
        message: message,
        status: status ?? this.status,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        inspectionItems: inspectionItems ?? this.inspectionItems,
        repairProposed: repairProposed ?? this.repairProposed,
        repairAccepted: repairAccepted ?? this.repairAccepted,
        createdAt: createdAt,
      );
}
