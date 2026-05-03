import 'package:url_launcher/url_launcher.dart';

/// NOTE: adjust ios and android settings based on the links you want to launch (https, sms, tel, etc.)
/// https://pub.dev/packages/url_launcher
/// - by default already setup for https and mailto

void launchLink(String url) async {
  Uri uri = Uri.parse(url);
  try {
    await canLaunchUrl(uri) ? await launchUrl(uri) : throw 'Could not launch $url';
  } catch (e) {
    print(e);
  }
}
