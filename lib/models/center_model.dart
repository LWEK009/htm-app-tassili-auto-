class CenterModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final String hours;
  final List<String> timeSlots;
  final bool isActive;

  const CenterModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.hours,
    required this.timeSlots,
    this.isActive = true,
  });

  factory CenterModel.fromMap(String id, Map<String, dynamic> m) => CenterModel(
        id: id,
        name: m['name'] ?? '',
        address: m['address'] ?? '',
        city: m['city'] ?? '',
        phone: m['phone'] ?? '',
        hours: m['hours'] ?? '',
        timeSlots: List<String>.from(m['timeSlots'] ?? []),
        isActive: m['isActive'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'city': city,
        'phone': phone,
        'hours': hours,
        'timeSlots': timeSlots,
        'isActive': isActive,
      };

  CenterModel copyWith({bool? isActive}) => CenterModel(
        id: id,
        name: name,
        address: address,
        city: city,
        phone: phone,
        hours: hours,
        timeSlots: timeSlots,
        isActive: isActive ?? this.isActive,
      );

  static List<CenterModel> get defaults => [
        const CenterModel(
          id: 'center_illizi',
          name: 'مركز تاسيلي — إليزي',
          address: 'شارع أول نوفمبر، إليزي',
          city: 'إليزي',
          phone: '029 41 12 34',
          hours: '08:00 - 16:00',
          timeSlots: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00'],
          isActive: false, // Closed
        ),
        const CenterModel(
          id: 'center_mila',
          name: 'مركز تاسيلي — ميلة',
          address: 'حي 500 مسكن، ميلة',
          city: 'ميلة',
          phone: '031 57 88 99',
          hours: '08:00 - 17:00',
          timeSlots: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00','16:00'],
          isActive: false, // Closed
        ),
        const CenterModel(
          id: 'center_soukahras',
          name: 'مركز تاسيلي — سوق أهراس',
          address: 'طريق عنابة، سوق أهراس',
          city: 'سوق أهراس',
          phone: '037 72 44 55',
          hours: '08:00 - 17:00',
          timeSlots: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00','16:00'],
        ),
        const CenterModel(
          id: 'center_algiers_n',
          name: 'مركز تاسيلي — الجزائر الشمال',
          address: 'بئر مراد رايس، الجزائر',
          city: 'الجزائر',
          phone: '023 45 67 89',
          hours: '08:00 - 17:00',
          timeSlots: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00','16:00'],
        ),
        const CenterModel(
          id: 'center_oran',
          name: 'مركز تاسيلي — وهران',
          address: 'حي العقيد لطفي، وهران',
          city: 'وهران',
          phone: '041 33 22 11',
          hours: '08:00 - 17:00',
          timeSlots: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00','16:00'],
        ),
        const CenterModel(
          id: 'center_constanine',
          name: 'مركز تاسيلي — قسنطينة',
          address: 'المنطقة الصناعية، قسنطينة',
          city: 'قسنطينة',
          phone: '031 99 88 77',
          hours: '08:00 - 17:00',
          timeSlots: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00','16:00'],
        ),
        const CenterModel(
          id: 'center_setif',
          name: 'مركز تاسيلي — سطيف',
          address: 'شارع 8 ماي 1945، سطيف',
          city: 'سطيف',
          phone: '036 44 55 66',
          hours: '08:00 - 17:00',
          timeSlots: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00','16:00'],
        ),
        const CenterModel(
          id: 'center_bechar',
          name: 'مركز تاسيلي — بشار',
          address: 'طريق تندوف، بشار',
          city: 'بشار',
          phone: '049 81 22 33',
          hours: '08:00 - 16:00',
          timeSlots: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00'],
          isActive: false, // Closed
        ),
        const CenterModel(
          id: 'center_tamanrasset',
          name: 'مركز تاسيلي — تمنراست',
          address: 'حي السلام، تمنراست',
          city: 'تمنراست',
          phone: '029 32 11 00',
          hours: '07:00 - 15:00',
          timeSlots: ['07:00','08:00','09:00','10:00','11:00','13:00','14:00'],
          isActive: false, // Closed
        ),
        const CenterModel(
          id: 'center_annaba',
          name: 'مركز تاسيلي — عنابة',
          address: 'حي سيدي ابراهيم، عنابة',
          city: 'عنابة',
          phone: '038 66 55 44',
          hours: '08:00 - 17:00',
          timeSlots: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00','16:00'],
        ),
        const CenterModel(
          id: 'center_tlemcen',
          name: 'مركز تاسيلي — تلمسان',
          address: 'شارع المنصورة، تلمسان',
          city: 'تلمسان',
          phone: '043 21 00 11',
          hours: '08:00 - 17:00',
          timeSlots: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00','16:00'],
          isActive: false, // Closed
        ),
        const CenterModel(
          id: 'center_batna',
          name: 'مركز تاسيلي — باتنة',
          address: 'طريق بسكرة، باتنة',
          city: 'باتنة',
          phone: '033 88 77 66',
          hours: '08:00 - 17:00',
          timeSlots: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00','16:00'],
        ),
        const CenterModel(
          id: 'center_ghardaia',
          name: 'مركز تاسيلي — غرداية',
          address: 'بونيورة، غرداية',
          city: 'غرداية',
          phone: '029 88 11 22',
          hours: '08:00 - 16:00',
          timeSlots: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00'],
        ),
        const CenterModel(
          id: 'center_tiaret',
          name: 'مركز تاسيلي — تيارت',
          address: 'حي التفاح، تيارت',
          city: 'تيارت',
          phone: '046 42 33 44',
          hours: '08:00 - 17:00',
          timeSlots: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00','16:00'],
          isActive: false, // Closed
        ),
      ];
}
