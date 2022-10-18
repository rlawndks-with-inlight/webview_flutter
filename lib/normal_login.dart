import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:untitled/social_login.dart';

class NormalLogin implements SocialLogin {
  @override
  Map loginData = <String, dynamic>{};

  @override
  Future<bool> login() async {
    return true;
  }

  @override
  Future<bool> logout() async {
    return true;
  }
}
