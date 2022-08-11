import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SongView extends StatelessWidget {
  final String html;

  const SongView({super.key, required this.html});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сборник песен'),
      ),
      body: WebView(
        onWebViewCreated: (controller) {
          controller.loadHtmlString(html);
        },
      ),
    );
  }
}
