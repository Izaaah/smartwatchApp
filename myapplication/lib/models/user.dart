class User {
  final int id;
  final String username;
  final String email;
  final String name;
  final int age;
  final String gender;
  final double height;
  final double weight;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      height: (json['height'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
    };
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String name;
  final int age;
  final String gender;
  final double height;
  final double weight;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
    };
  }
}

class UserUpdateRequest {
  final String email;
  final String name;
  final int age;
  final String gender;
  final double height;
  final double weight;

  UserUpdateRequest({
    required this.email,
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
    };
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final User? user;

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      token: json['data'] != null && json['data']['token'] != null
          ? json['data']['token'] as String
          : null,
      user: json['data'] != null && json['data']['user'] != null
          ? User.fromJson(json['data']['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
