import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Center-crop + resize user images for MorphOS icons / wallpapers.
/// Pure byte transforms — unit-testable without a device gallery.
class ImageCustomize {
  ImageCustomize._();

  /// Square icon cut from the center of [bytes]. Max edge [maxSize].
  /// Returns PNG bytes, or null if decode fails.
  static Uint8List? cropIconSquare(
    List<int> bytes, {
    int maxSize = 192,
  }) {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) return null;
    final side = decoded.width < decoded.height ? decoded.width : decoded.height;
    final x = ((decoded.width - side) / 2).floor();
    final y = ((decoded.height - side) / 2).floor();
    var cropped = img.copyCrop(
      decoded,
      x: x,
      y: y,
      width: side,
      height: side,
    );
    if (cropped.width > maxSize) {
      cropped = img.copyResize(
        cropped,
        width: maxSize,
        height: maxSize,
        interpolation: img.Interpolation.average,
      );
    }
    return Uint8List.fromList(img.encodePng(cropped));
  }

  /// Resize a wallpaper image for storage (keeps aspect, max long edge).
  static Uint8List? prepareWallpaper(
    List<int> bytes, {
    int maxLongEdge = 1280,
    int jpegQuality = 82,
  }) {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) return null;
    final long = decoded.width > decoded.height ? decoded.width : decoded.height;
    img.Image out = decoded;
    if (long > maxLongEdge) {
      final scale = maxLongEdge / long;
      out = img.copyResize(
        decoded,
        width: (decoded.width * scale).round().clamp(1, maxLongEdge),
        height: (decoded.height * scale).round().clamp(1, maxLongEdge),
        interpolation: img.Interpolation.average,
      );
    }
    return Uint8List.fromList(img.encodeJpg(out, quality: jpegQuality));
  }

  /// True when bytes look like a usable image payload for MorphOS storage.
  static bool isReasonableIconPayload(List<int> bytes) {
    if (bytes.isEmpty) return false;
    if (bytes.length > 200 * 1024) return false;
    return true;
  }

  static bool isReasonableWallpaperPayload(List<int> bytes) {
    if (bytes.isEmpty) return false;
    if (bytes.length > 900 * 1024) return false;
    return true;
  }

  /// Rasterize a vertical gradient so MorphOS can push it as the system wallpaper.
  static Uint8List gradientJpeg({
    required int topArgb,
    required int bottomArgb,
    int width = 540,
    int height = 960,
    int jpegQuality = 80,
  }) {
    final image = img.Image(width: width, height: height);
    final tr = (topArgb >> 16) & 0xFF;
    final tg = (topArgb >> 8) & 0xFF;
    final tb = topArgb & 0xFF;
    final br = (bottomArgb >> 16) & 0xFF;
    final bg = (bottomArgb >> 8) & 0xFF;
    final bb = bottomArgb & 0xFF;
    for (var y = 0; y < height; y++) {
      final t = height == 1 ? 0.0 : y / (height - 1);
      final r = (tr + (br - tr) * t).round().clamp(0, 255);
      final g = (tg + (bg - tg) * t).round().clamp(0, 255);
      final b = (tb + (bb - tb) * t).round().clamp(0, 255);
      final color = img.ColorRgb8(r, g, b);
      for (var x = 0; x < width; x++) {
        image.setPixel(x, y, color);
      }
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: jpegQuality));
  }
}
