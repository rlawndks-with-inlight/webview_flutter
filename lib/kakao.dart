import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:untitled/social_login.dart';

class KakaoLogin implements SocialLogin {
  @override
  Map loginData = <String, dynamic>{};

  @override
  Future<bool> login() async {
    try {
      User user;
      bool isInstalled = await isKakaoTalkInstalled();
      if (isInstalled) {
        try {
          await UserApi.instance.loginWithKakaoTalk();
          user = await UserApi.instance.me();
        } catch (e) {
          return false;
        }
      } else {
        try {
          await UserApi.instance.loginWithKakaoAccount();
          user = await UserApi.instance.me();
        } catch (e) {
          return false;
        }
      }
      loginData['id'] = user.id;
      loginData['name'] = user.kakaoAccount?.name;
      loginData['birthday'] = user.kakaoAccount?.birthday;
      loginData['legal_name'] = user.kakaoAccount?.legalName;
      loginData['phone_number'] = user.kakaoAccount?.phoneNumber;
      loginData['profile_nickname'] = user.kakaoAccount?.profile?.nickname;
      loginData['profile_image_url'] =
          user.kakaoAccount?.profile?.profileImageUrl;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> logout() async {
    try {
      await UserApi.instance.unlink();
      return true;
    } catch (error) {
      return false;
    }
  }
}
