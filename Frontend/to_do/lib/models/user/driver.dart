class Driver {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final BusDetails busDetails;
  final String? licenseNumber;
  final String? image;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.busDetails,
    this.licenseNumber,
    this.image,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      busDetails: BusDetails.fromJson(json['busDetails'] ?? {}),
      licenseNumber: json['licenseNumber'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'busDetails': busDetails.toJson(),
      'licenseNumber': licenseNumber,
      'image': image,
    };
  }
}

class BusDetails {
  final String? busColor;
  final String? busModel;
  final String busNumber;

  BusDetails({
    this.busColor,
    this.busModel,
    required this.busNumber,
  });

  factory BusDetails.fromJson(Map<String, dynamic> json) {
    return BusDetails(
      busColor: json['busColor'],
      busModel: json['busModel'],
      busNumber: json['busNumber'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busColor': busColor,
      'busModel': busModel,
      'busNumber': busNumber,
    };
  }
}
