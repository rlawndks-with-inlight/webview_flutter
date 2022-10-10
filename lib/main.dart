import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: false,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  messaging.getToken().then((value) => {print('Token data: ${value}')});
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MaterialApp(home: new MyApp()));
}

Future<File> get _localFile async {
  Directory directory = await getApplicationDocumentsDirectory();
  return File("${directory.path}/settings.json");
}

Future<Map<String, dynamic>> readSettingsFromFile() async {
  final file = await _localFile;

  Map<String, dynamic> settings;
  try {
    final contents = await file.readAsString() ?? "{}";
    settings = jsonDecode(contents);
  } catch (e) {
    settings = {
      "booleanTypeSettingA": true,
      "booleanTypeSettingB": false,
      "numberTypeSettingA": 0,
      "numberTypeSettingB": 0,
      "numberTypeSettingC": 0,
      "stringTypeSettings": "foo",
      "stringTypeSettings": "bar",
    };

    file.writeAsString(
      jsonEncode(settings),
    );
  }

  return settings;
}

Future<void> saveSettingsToFile<T>(String key, T value) async {
  final file = await _localFile;
  Map<String, dynamic> settings = await readSettingsFromFile();

  settings.containsKey(key)
      ? settings[key] = value
      : settings.addAll({key: value});

  await file.writeAsString(
    jsonEncode(settings),
  );
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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Map<String, dynamic> settings = await readSettingsFromFile();
  int alarm_cnt = settings['alarm_cnt'] ?? 0;
  int notice_cnt = settings['notice_cnt'] ?? 0;
  if (message.data['table'] == 'alarm') {
    alarm_cnt++;
    saveSettingsToFile('alarm_cnt', alarm_cnt);
  } else if (message.data['table'] == 'notice') {
    notice_cnt++;
    saveSettingsToFile('notice_cnt', notice_cnt);
  }
  print('add -> alarm_cnt: $alarm_cnt, notice_cnt: $notice_cnt');
  await FlutterAppBadger.updateBadgeCount(alarm_cnt + notice_cnt);
}

Future<String> setAlarmAndNoticeCount(String table) async {
  Map<String, dynamic> settings = await readSettingsFromFile();
  int alarm_cnt = settings['alarm_cnt'] ?? 0;
  int notice_cnt = settings['notice_cnt'] ?? 0;

  if (table == 'alarm') {
    alarm_cnt = 0;
    saveSettingsToFile('alarm_cnt', alarm_cnt);
  } else if (table == 'notice') {
    notice_cnt = 0;
    saveSettingsToFile('notice_cnt', notice_cnt);
  }
  if (alarm_cnt == 0 && notice_cnt == 0) {
    await FlutterAppBadger.removeBadge();
    Eraser.clearAllAppNotifications();
  } else {
    await FlutterAppBadger.updateBadgeCount(alarm_cnt + notice_cnt);
  }

  print('delete -> alarm_cnt: $alarm_cnt, notice_cnt: $notice_cnt');
  Map response = {};
  Map data = {};
  data['alarm_cnt'] = alarm_cnt;
  data['notice_cnt'] = notice_cnt;
  response['code'] = 100;
  response['message'] = '푸시알람 카운팅';
  response['data'] = data;
  return json.encode(response);
}

Future<String> getAlarmCount() async {
  Map<String, dynamic> settings = await readSettingsFromFile();
  int alarm_cnt = settings['alarm_cnt'] ?? 0;
  int notice_cnt = settings['notice_cnt'] ?? 0;
  Map response = {};
  Map data = {};
  data['alarm_cnt'] = alarm_cnt;
  data['notice_cnt'] = notice_cnt;
  response['code'] = 100;
  response['message'] = '푸시알람 카운팅';
  response['data'] = data;
  return json.encode(response);
}

void _removeBadge() {
  FlutterAppBadger.removeBadge();
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
    super.initState();
    initPlatformState();
    subscription = FGBGEvents.stream.listen((event) async {
      print(event); // FGBGType.foreground or FGBGType.background
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return GetMaterialApp(
        home: WillPopScope(
            onWillPop: () => _goBack(context),
            child: Scaffold(
                body: SafeArea(
                    child: Column(children: <Widget>[
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(
                      key: webViewKey,
                      initialUrlRequest: URLRequest(
                          url: Uri.parse("http://172.30.1.88:3000/")),
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
                              Map table_name = json.decode(args[0]);
                              return await setAlarmAndNoticeCount(
                                  table_name['table']);
                            });
                        webViewController?.addJavaScriptHandler(
                            handlerName: "native_get_alarm_count",
                            callback: (args) async {
                              return await getAlarmCount();
                            });
                        webViewController?.addJavaScriptHandler(
                            handlerName: "get_allow_alarm",
                            callback: (args) async {
                              print("alarm_cnt: ");
                              return "{}";
                            });
                        webViewController?.addJavaScriptHandler(
                            handlerName: "set_allow_alarm",
                            callback: (args) async {
                              print(args[0]['is_allow_alarm'].runtimeType);
                              _setAlarmSetting(args[0]['is_allow_alarm']);
                              return await "{}";
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
