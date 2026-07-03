class DriverDetail {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String telephone;
  final String username;
  final String profile;
  final String? address;
  final String? imageFileName;
  final double? latitude;
  final double? longitude;

  const DriverDetail({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.telephone,
    required this.username,
    required this.profile,
    this.address,
    this.imageFileName,
    this.latitude,
    this.longitude,
  });

  String get fullName => '$firstName $lastName';

  factory DriverDetail.fromJson(Map<String, dynamic> json) {
    return DriverDetail(
      id: json['id'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profile: json['profile'] as String? ?? '',
      address: json['address'] as String?,
      imageFileName: json['imageFileName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
