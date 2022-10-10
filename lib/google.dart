import 'package:untitled/social_login.dart';

class GoogleLogin implements SocialLogin{
  @override
  Map loginData = <String, dynamic>{};

  @override
  Future<bool> login() async {
    try {
      return true;
    } catch(e) {
      return false;
    }
  }
  @override
  Future<bool> logout() async {
    try {
      return true;
    } catch(e) {
      return false;
    }
  }
}