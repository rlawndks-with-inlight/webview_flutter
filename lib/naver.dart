import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:untitled/social_login.dart';

class NaverLogin implements SocialLogin{
  @override
  Map loginData = <String, dynamic>{};

  @override
  Future<bool> login() async {
    try {
      NaverLoginResult? user;
      user = await FlutterNaverLogin.logIn();
      bool isLogin = await FlutterNaverLogin.isLoggedIn;
      if(isLogin) {
        loginData['id']            = user.account.id;
        loginData['name']          = user.account.name;
        loginData['birthday']      = user.account.birthday;
        loginData['legal_name']     = user.account.name;
        loginData['phone_number']   = user.account.mobile;
        loginData['profile_nickname']   = user.account.nickname;
        loginData['profile_image_url']  = user.account.profileImage;
        return true;
      }
      else {
        print("로그인 실패");
        return false;
      }
    } catch(e) {
      print(e);
      return false;
    }
  }
  @override
  Future<bool> logout() async {
    try {
      await FlutterNaverLogin.logOut();
      return true;
    } catch(e) {
      return false;
    }
  }
}