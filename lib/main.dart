import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:untitled/main_view_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:untitled/Alarm.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:eraser/eraser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled/fcm.dart';
import 'package:untitled/global.dart';
import 'package:untitled/local_service.dart';
import 'package:provider/provider.dart';
import 'package:mac_address/mac_address.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent/android_intent.dart';

String OPEN_APP_URL = "";
Future _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    //showNotification(message.data);
    //await setBadge(message.data['table'], false);
  } catch (e) {
    print(e);
  }
}

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  await Firebase.initializeApp();

  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'weare', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  // 2.

  // 권한 및 채널 설정
  if (Platform.isIOS) {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      showToast("푸시 알림을 이용하기 위해서 알림권한을 허용해주세요.");
    }
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
  } else {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher_white'),
          iOS: IOSInitializationSettings()),
      onSelectNotification: (String? payload) async {});
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(channel.id, channel.name,
              channelDescription: channel.description),
        ),

        // 넘겨줄 데이터가 있으면 아래 코드를 써주면 됨.
        // payload: message.data['argument']
      );
    }
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
    //setBadge(message.data['table'], false);
  });
  //FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage); //foreground
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    _handleMessage(initialMessage);
  }
  //background
  int is_want_alarm = await LocalService.getWantAlarm();
  if (is_want_alarm == 1) {
    await FirebaseMessaging.instance.subscribeToTopic('weare');
  } else {
    await FirebaseMessaging.instance.unsubscribeFromTopic('weare');
  }

  runApp(MaterialApp(home: new MyApp()));
}

void _setAlarmSetting(int num) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: num == 1 ? true : false,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: num == 1 ? true : false,
  );
}

showNotification(Map<String, dynamic> data) async {
  if (Platform.isIOS) {
    return;
  }
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(channel.id, channel.name,
          channelDescription: channel.description,
          sound: RawResourceAndroidNotificationSound('slow_spring_board'),
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');
  const IOSNotificationDetails iOSPlatformChannelSpecifics =
      IOSNotificationDetails(sound: 'slow_spring_board.aiff');
  NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);
  LocalService.OPEN_APP_URI = data['url'] ?? "";

  await flutterLocalNotificationsPlugin.show(
      0, data["title"], data["body"], platformChannelSpecifics,
      payload: json.encode(data));
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'weare', // id
  'High Importance Notifications',
  description: 'High Importance Notifications Description', // title
  importance: Importance.max,
);

void _handleMessage(RemoteMessage message) async {
  showNotification(message.data);
  //await setBadge(message.data['table'], false);
}

Future<void> setBadge(String table, bool is_zero) async {
  try {
    int a_cnt = await LocalService.getAlarmBadgeCnt();
    int n_cnt = await LocalService.getNoticeBadgeCnt();
    if (table == 'alarm') {
      a_cnt++;
      if (is_zero) {
        a_cnt = 0;
      }
    } else if (table == 'notice') {
      n_cnt++;
      if (is_zero) {
        n_cnt = 0;
      }
    }
    LocalService.setAlarmBadgeCnt(a_cnt);
    LocalService.setNoticeBadgeCnt(n_cnt);
    if (a_cnt == 0 && n_cnt == 0) {
      await FlutterAppBadger.removeBadge();
      Eraser.clearAllAppNotifications();
    } else {
      await FlutterAppBadger.updateBadgeCount(a_cnt + n_cnt);
    }
  } catch (e) {
    print(e);
  }
  // if (alarm_cnt == 0 && notice_cnt == 0) {
  //   await FlutterAppBadger.removeBadge();
  //   Eraser.clearAllAppNotifications();
  // } else {
  //   await FlutterAppBadger.updateBadgeCount(alarm_cnt + notice_cnt);
  // }
}

Future<String> setAlarmAndNoticeCountZero(
    int last_alarm_cnt, int last_notice_cnt) async {
  await FlutterAppBadger.removeBadge();
  Eraser.clearAllAppNotifications();
  // await setBadge(table, true);
  // int a_cnt = await LocalService.getAlarmBadgeCnt();
  // int n_cnt = await LocalService.getNoticeBadgeCnt();
  //print('delete -> alarm_cnt: $alarm_cnt, notice_cnt: $notice_cnt');
  LocalService.setLastNoticeCnt(last_notice_cnt);
  LocalService.setLastAlarmCnt(last_alarm_cnt);
  Map response = {};
  Map data = {};
  data['alarm_cnt'] = 0;
  data['notice_cnt'] = 0;
  response['code'] = 100;
  response['message'] = '푸시알람 카운팅';
  response['data'] = data;
  return json.encode(response);
}

Future<String> setPermissionAlarm(Map obj) async {
  int cnt = obj['is_allow_alarm'];
  if (cnt == 0) {
    await FirebaseMessaging.instance.unsubscribeFromTopic('weare');
  } else if (cnt == 1) {
    await FirebaseMessaging.instance.subscribeToTopic('weare');
  }
  LocalService.setWantAlarm(cnt);

  Map response = {};
  Map data = {};
  response['code'] = 100;
  response['message'] = '알람 허용 여부 변경';
  response['data'] = data;
  return json.encode(response);
}

Future<String> getPermissionAlarm() async {
  int cnt = await LocalService.getWantAlarm();

  Map response = {};
  Map data = {};
  data['is_want_alarm'] = cnt;
  response['code'] = 100;
  response['message'] = '알람 허용 여부 가져오기';
  response['data'] = data;
  return json.encode(response);
}

getAlarmAndNoticeLastCount() async {
  try {
    int a_cnt = await LocalService.getLastAlarmCnt();
    int n_cnt = await LocalService.getLastNoticeCnt();

    Map response = {};
    Map data = {};
    data['alarm_last_pk'] = a_cnt;
    data['notice_last_pk'] = n_cnt;
    response['code'] = 100;
    response['message'] = '마지막 체크 카운팅';
    response['data'] = data;
    return json.encode(response);
  } catch (e) {
    print(e);
  }
}

getMacAddress() async {
  try {
    int a_cnt = await LocalService.getAlarmBadgeCnt();
    int n_cnt = await LocalService.getNoticeBadgeCnt();

    Map response = {};
    Map data = {};
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await GetMac.macAddress;
    } on PlatformException {
      platformVersion = 'Failed to get Device MAC Address.';
    }
    data['mac_address'] = await GetMac.macAddress;
    response['code'] = 100;
    response['message'] = '맥어드레스';
    response['data'] = data;
    return json.encode(response);
  } catch (e) {
    print(e);
  }
}

_launchURL(URL) async {
  var url = "${URL}";
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

createIntent(url, company) async {
  if (Platform.isAndroid) {
    final AndroidIntent intent = AndroidIntent(
        action: 'action_view', data: Uri.encodeFull(url), package: company);
    intent.launch();
  } else {}
}

void _removeBadge() {
  FlutterAppBadger.removeBadge();
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String fcmToken = "";
  String _appBadgeSupported = 'Unknown';

  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  late StreamSubscription<FGBGType> subscription;

  @override
  void initState() {
    requestingPermissionForIOS();
    getToken();
    super.initState();
    initPlatformState();
    subscription = FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground) {
        print("fore");
      } else {
        print("back");
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      print("onMessageOpenedApp data: ${message.data.toString()}");
      print(
          "onMessageOpenedApp notification:  ${message.notification.toString()}");
      if (message.data['url'] != null) {
        setState(() {
          webViewController?.loadUrl(
              urlRequest: URLRequest(
                  url: Uri.parse(
                      LocalService.WEBVIEW_URL + message.data['url'])));
        });
      }
    });

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  getToken() async {
    String? token = await _firebaseMessaging.getToken();
    fcmToken = token!;
    print("fcmToken: $fcmToken");
  }

  @override
  void dispose() {
    super.dispose();
  }

  initPlatformState() async {
    String appBadgeSupported;
    try {
      bool res = await FlutterAppBadger.isAppBadgeSupported();
      if (res) {
        appBadgeSupported = 'Supported';
      } else {
        appBadgeSupported = 'Not supported';
      }
    } on PlatformException {
      appBadgeSupported = 'Failed to get badge support.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _appBadgeSupported = appBadgeSupported;
    });
  }

  Future<String> login(Map req) async {
    MainViewModel viewModel = MainViewModel(req['login_type']);
    if (req['login_type'] == 0) viewModel.setId(req['id']);
    Map response = {};

    await viewModel.initPrefs();
    await viewModel.login();
    setState(() {});
    response = viewModel.GetLoginData();

    return json.encode(response);
  }

  void showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        backgroundColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM);
  }

  Future<String> logout(Map req) async {
    MainViewModel viewModel = MainViewModel(req['login_type']);
    Map response = {};

    await viewModel.initPrefs();
    viewModel.prefs.remove('login');
    response['code'] = 100;
    response['message'] = '로그아웃에 성공하였습니다.';
    response['data'] = {};
    return json.encode(response);
  }

  Future<String> getLoginedInfo() async {
    MainViewModel viewModel = MainViewModel(0);
    Map response = {};
    await viewModel.initPrefs();
    response = viewModel.GetLoginedData();
    return json.encode(response);
  }

  requestingPermissionForIOS() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permission");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("User granted provisional permission");
    } else {
      print("User declined or has not accepted permission");
    }
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);
  }

  DateTime? currentBackPressTime;
  int clickBackCount = 0;
  onWillPop() {
    DateTime now = DateTime.now();

    if ((currentBackPressTime == null ||
            now.difference(currentBackPressTime!) >
                const Duration(seconds: 2)) ||
        clickBackCount < 3) {
      currentBackPressTime = now;
      if (now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
        clickBackCount = 1;
      } else {
        clickBackCount++;
      }
      if (clickBackCount == 3) {
        Fluttertoast.showToast(
            msg: "'뒤로' 버튼을 한번 더 누르시면 종료됩니다.",
            gravity: ToastGravity.BOTTOM,
            backgroundColor: const Color(0xff6E6E6E),
            fontSize: 20,
            toastLength: Toast.LENGTH_SHORT);
      }

      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    return GetMaterialApp(
        home: WillPopScope(
            onWillPop: () async {
              bool result = onWillPop();
              if (!result) {
                return _goBack(context);
              }
              return await Future.value(result);
            },
            child: Scaffold(
                body: SafeArea(
                    child: Column(children: <Widget>[
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(
                      key: webViewKey,
                      initialUrlRequest: URLRequest(
                          url: Uri.parse(
                              "${LocalService.WEBVIEW_URL}${LocalService.OPEN_APP_URI}")),
                      initialOptions: options,
                      pullToRefreshController: pullToRefreshController,
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                        webViewController?.addJavaScriptHandler(
                            handlerName: "native_app_logined",
                            callback: (args) async {
                              return await getLoginedInfo();
                            });
                        webViewController?.addJavaScriptHandler(
                            handlerName: "native_app_login",
                            callback: (args) async {
                              return await login(json.decode(args[0]));
                            });
                        webViewController?.addJavaScriptHandler(
                            handlerName: "native_app_logout",
                            callback: (args) async {
                              return await logout(json.decode(args[0]));
                            });
                        webViewController?.addJavaScriptHandler(
                            handlerName: "native_alarm_count_zero",
                            callback: (args) async {
                              return await setAlarmAndNoticeCountZero(
                                  args[0]['alarm_last_pk'],
                                  args[0]['notice_last_pk']);
                            });
                        webViewController?.addJavaScriptHandler(
                            handlerName:
                                "native_get_alarm_and_notice_last_count",
                            callback: (args) async {
                              return await getAlarmAndNoticeLastCount();
                            });
                        webViewController?.addJavaScriptHandler(
                            handlerName: "get_allow_alarm",
                            callback: (args) async {
                              return getPermissionAlarm();
                            });
                        webViewController?.addJavaScriptHandler(
                            handlerName: "set_allow_alarm",
                            callback: (args) async {
                              return await setPermissionAlarm(
                                  json.decode(args[0]));
                            });
                        webViewController?.addJavaScriptHandler(
                            handlerName: "open_internet_browser",
                            callback: (args) async {
                              return await launchUrl(args[0]['url']);
                            });
                        webViewController?.addJavaScriptHandler(
                            handlerName: "native_app_open_youtube",
                            callback: (args) async {
                              return await createIntent(
                                  args[0]['url'], args[0]['company']);
                            });
                      },
                      onLoadStart: (controller, url) {
                        setState(() {
                          _removeBadge();
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      androidOnPermissionRequest:
                          (controller, origin, resources) async {
                        return PermissionRequestResponse(
                            resources: resources,
                            action: PermissionRequestResponseAction.GRANT);
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        var uri = navigationAction.request.url!;
                        if (![
                          "http",
                          "https",
                          "file",
                          "chrome",
                          "data",
                          "javascript",
                          "about"
                        ].contains(uri.scheme)) {
                          if (await canLaunch(url)) {
                            // Launch the App
                            await launch(
                              url,
                            );
                            // and cancel the request
                            return NavigationActionPolicy.CANCEL;
                          }
                        }
                        return NavigationActionPolicy.ALLOW;
                      },
                      onLoadStop: (controller, url) async {
                        pullToRefreshController.endRefreshing();
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      onLoadError: (controller, url, code, message) {
                        pullToRefreshController.endRefreshing();
                      },
                      onProgressChanged: (controller, progress) {
                        if (progress == 100) {
                          pullToRefreshController.endRefreshing();
                        }
                        setState(() {
                          this.progress = progress / 100;
                          urlController.text = url;
                        });
                      },
                      onUpdateVisitedHistory:
                          (controller, url, androidIsReload) {
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        print('consoleMessage: ${consoleMessage}');
                      },
                    ),
                    progress < 1.0
                        ? LinearProgressIndicator(value: progress)
                        : Container(),
                  ],
                ),
              ),
            ])))));
  }

  Future<bool> _goBack(BuildContext context) async {
    if (webViewController == null) {
      return true;
    }
    if (await webViewController!.canGoBack()) {
      webViewController!.goBack();
      return Future.value(false);
    } else {
      return Future.value(true);
    }
  }
}
