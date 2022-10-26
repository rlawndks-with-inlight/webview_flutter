import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalService {
  static String PREF_USER = "PREF_USER";
  static String PREF_USER_PHONE = "PREF_USER_PHONE";
  static String PREF_RECENT_ADDRESS = "PREF_RECENT_ADDRESS";
  static String PREF_CENTER_EMAIL = "PREF_CENTER_EMAIL";
  static String PREF_RECENT_KEYWORD_LIST = "PREF_RECENT_KEYWORD_LIST";
  static String PREF_NOTI_BADGE_CNT = "PREF_NOTI_BADGE_CNT";
  static String PREF_ALARM_CNT = "PREF_ALARM_CNT";
  static String PREF_NOTICE_CNT = "PREF_NOTICE_CNT";
  static String WANT_ALARM = "WANT_ALARM";
  static String WEBVIEW_URL = "https://weare-first.com";

  static void setCenterEmail(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(PREF_CENTER_EMAIL, email);
  }

  static Future<String> getCenterEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString(PREF_CENTER_EMAIL) ?? "";
    return email;
  }

  static void removeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(PREF_USER);
  }

  static void addRecentKeyword(String keyword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recentKeywordList =
        prefs.getStringList(PREF_RECENT_KEYWORD_LIST) ?? [];

    if (recentKeywordList.contains(keyword)) {
      return;
    }

    recentKeywordList.insert(0, keyword);
    if (recentKeywordList.length > 10) {
      recentKeywordList.removeRange(
          recentKeywordList.length - 10, recentKeywordList.length);
    }

    prefs.setStringList(PREF_RECENT_KEYWORD_LIST, recentKeywordList);
  }

  static void removeRecentKeyword(String keyword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recentKeywordList =
        prefs.getStringList(PREF_RECENT_KEYWORD_LIST) ?? [];

    if (recentKeywordList.contains(keyword)) {
      recentKeywordList.remove(keyword);
      prefs.setStringList(PREF_RECENT_KEYWORD_LIST, recentKeywordList);
    }
  }

  static void removeAllRecentKeywords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(PREF_RECENT_KEYWORD_LIST, []);
  }

  static Future<List<String>> getRecentKeywords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recentKeywordList =
        prefs.getStringList(PREF_RECENT_KEYWORD_LIST) ?? [];
    return recentKeywordList;
  }

  static void setAlarmBadgeCnt(int cnt) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(PREF_ALARM_CNT, cnt);
  }

  static Future<int> getAlarmBadgeCnt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final int cnt = prefs.getInt(PREF_ALARM_CNT) ?? 0;
    return cnt;
  }

  static void setNoticeBadgeCnt(int cnt) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(PREF_NOTICE_CNT, cnt);
  }

  static Future<int> getNoticeBadgeCnt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final int cnt = prefs.getInt(PREF_NOTICE_CNT) ?? 0;
    return cnt;
  }

  static void setWantAlarm(int cnt) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(WANT_ALARM, cnt);
  }

  static Future<int> getWantAlarm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final int cnt = prefs.getInt(WANT_ALARM) ?? 1;
    return cnt;
  }
}
