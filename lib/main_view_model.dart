import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/social_login.dart';
import 'dart:convert';

import 'normal_login.dart';
import 'kakao.dart';
import 'naver.dart';

class MainViewModel {
  late final SocialLogin _socialLogin;
  late final SharedPreferences prefs;
  bool isLogined = false;
  int loginType = 0;

  MainViewModel(int loginId) {
    loginType = loginId;
    if (loginType == 0) {
      _socialLogin = NormalLogin();
    } else if (loginType == 1) {
      KakaoSdk.init(nativeAppKey: '746c2192ff19a2d5be500ce481428445');
      _socialLogin = KakaoLogin();
    } else if (loginType == 2) {
      _socialLogin = NaverLogin();
    } else {}
  }

  void setId(String id) {
    _socialLogin.loginData['id'] = id;
  }

  Future initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future login() async {
    isLogined = await _socialLogin.login();
  }

  Future logout() async {
    isLogined = await _socialLogin.logout();
  }

  Map GetLoginData() {
    Map data = <String, dynamic>{};
    data['code'] = isLogined ? 100 : -100;
    data['message'] = isLogined ? "로그인 성공" : "로그인 실패";
    data['data'] = _socialLogin.loginData;
    data['data']['login_type'] = loginType;

    if (isLogined) {
      prefs.setString('login', json.encode(data['data']));
    }
    return data;
  }

  Map GetLoginedData() {
    Map data = <String, dynamic>{};
    String login = prefs.getString('login') ?? "{}";
    data['code'] = 100;
    data['message'] = "로그인 데이터를 가져왔습니다.";
    data['data'] = json.decode(login);
    return data;
  }
}
