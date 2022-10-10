abstract class SocialLogin {
  Map loginData = <String, dynamic>{};
  Future<bool> login();
  Future<bool> logout();
}