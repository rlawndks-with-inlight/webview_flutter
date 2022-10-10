import 'package:shared_preferences/shared_preferences.dart';

class Alarm {
  static late final SharedPreferences prefs;
  static bool isInit = false;
  // Private한 생성자 생성
  Alarm._privateConstructor();
  // 생성자를 호출하고 반환된 Alram 인스턴스를 _instance 변수에 할당
  static final Alarm _instance = Alarm._privateConstructor();
  // Alram() 호출시에 _instance 변수를 반환
  factory Alarm() {
    return _instance;
  }
  Future initPrefs() async {
    if (isInit == false) {
      prefs = await SharedPreferences.getInstance();
      isInit = true;
    }
  }

  String GetString(String key) {
    var a = prefs.getString(key);
    if (a == null) {
      print("a is null @@@@@alarm_cnt@@@@@@@@@@@$key");
      a = "0";
    }
    return a;
  }

  Future SetString(String key, String value) async {
    var result = await prefs.setString(key, value);
    var str_result = result ? "suces" : "fail";
    print(str_result);
  }
}
