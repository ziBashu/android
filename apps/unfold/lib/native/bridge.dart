import 'package:flutter/services.dart';

class UnfoldNative {
  static const channel = MethodChannel('com.zibashu.unfold/native');

  static Future<String?> pick() async {
    try {
      return await channel.invokeMethod<String>('pick');
    } on MissingPluginException {
      return null;
    }
  }

  static Future<bool> share(String path, {String mime = 'application/octet-stream'}) async {
    try {
      await channel.invokeMethod<void>('share', {'path': path, 'mime': mime});
      return true;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> saveAs(String name, Uint8List bytes, {String mime = 'application/octet-stream'}) async {
    try {
      return await channel.invokeMethod<bool>('saveAs', {
            'name': name,
            'bytes': bytes,
            'mime': mime,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<String?> incoming() async {
    try {
      return await channel.invokeMethod<String>('incoming');
    } on MissingPluginException {
      return null;
    }
  }

  static void listenOpen(void Function(String path) onOpen) {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'open' && call.arguments is String) {
        onOpen(call.arguments as String);
      }
    });
  }

  static Future<Uint8List?> renderPdfPage(String path, int index, int width) async {
    try {
      final raw = await channel.invokeMethod<dynamic>('renderPdfPage', {
        'path': path,
        'index': index,
        'width': width,
      });
      if (raw is Uint8List) return raw;
      if (raw is List<int>) return Uint8List.fromList(raw);
      return null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<int?> pdfPageCount(String path) async {
    try {
      return await channel.invokeMethod<int>('pdfPageCount', {'path': path});
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
