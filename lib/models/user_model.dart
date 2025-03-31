class UserModel {
  final int id;
  final String phoneNumber;
  final String? userProfileImage;
  final String email;
  final String userName;
  final String? userDob;
  final String? userAddress1;
  final String? userAddress2;
  final String? userAddress3;
  final String? userDistrictPincode;
  final String? advocateRegistrationNumber;
  final String? userState;
  final String? userDistrict;

  UserModel({
    required this.id,
    required this.phoneNumber,
    this.userProfileImage,
    required this.email,
    required this.userName,
    this.userDob,
    this.userAddress1,
    this.userAddress2,
    this.userAddress3,
    this.userDistrictPincode,
    this.advocateRegistrationNumber,
    this.userState,
    this.userDistrict,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      phoneNumber: json['phone_number'] ?? '',
      userProfileImage: json['user_profile_image'],
      email: json['email'] ?? '',
      userName: json['user_name'] ?? '',
      userDob: json['user_dob'],
      userAddress1: json['user_address1'],
      userAddress2: json['user_address2'],
      userAddress3: json['user_address3'],
      userDistrictPincode: json['user_district_pincode'],
      advocateRegistrationNumber: json['advocate_registration_number'],
      userState: json['user_state'],
      userDistrict: json['user_district'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'user_profile_image': userProfileImage,
      'email': email,
      'user_name': userName,
      'user_dob': userDob,
      'user_address1': userAddress1,
      'user_address2': userAddress2,
      'user_address3': userAddress3,
      'user_district_pincode': userDistrictPincode,
      'advocate_registration_number': advocateRegistrationNumber,
      'user_state': userState,
      'user_district': userDistrict,
    };
  }
}
