class HomeUserAddress {
  const HomeUserAddress({
    required this.fullName,
    required this.phone,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  final String fullName;
  final String phone;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  static const empty = HomeUserAddress(
    fullName: '',
    phone: '',
    line1: '',
    line2: '',
    city: '',
    state: '',
    postalCode: '',
    country: '',
  );

  bool get isComplete {
    return fullName.trim().isNotEmpty &&
        phone.trim().isNotEmpty &&
        line1.trim().isNotEmpty &&
        city.trim().isNotEmpty &&
        state.trim().isNotEmpty &&
        postalCode.trim().isNotEmpty &&
        country.trim().isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'line1': line1.trim(),
      'line2': line2.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'postalCode': postalCode.trim(),
      'country': country.trim(),
    };
  }

  factory HomeUserAddress.fromMap(Map<String, dynamic>? data) {
    final map = data ?? <String, dynamic>{};

    return HomeUserAddress(
      fullName: (map['fullName'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      line1: (map['line1'] ?? '').toString(),
      line2: (map['line2'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      state: (map['state'] ?? '').toString(),
      postalCode: (map['postalCode'] ?? '').toString(),
      country: (map['country'] ?? '').toString(),
    );
  }
}
