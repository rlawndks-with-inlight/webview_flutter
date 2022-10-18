//user level

String CUSTOMER_CENTER = "admin@kyadmeeting.com";
String APP_INSTALL_URL = "https://digcard.page.link/install";
//const String API_BASE_URL = "http://192.168.0.13:8203/";
const String API_BASE_URL = "http://52.79.91.16/";
const String DEFAULT_IMG = "/assets/images/img_photo_default.png";

const String HOTDEAL_TYPE = "hotdeal";
const String EVENT_TYPE = "event";
const String COMMUNITY_TYPE = "community";

String gPushKey = "";
String gLangCode = "en";
bool gIsChatRoom = false;

enum ResultStatus { success, error, delete }

enum MainTab { home, event, community, chatting, my }

enum WebViewType { term, privacy, opensource }

enum PhoneAuthType { login, signup, changePhone }
