library fun_qr_generator;

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:custom_qr_generator/custom_qr_generator.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:zxing_lib/qrcode.dart';
import 'package:path_provider/path_provider.dart';

import 'package:image/image.dart' as img;

class FunQr {
  static FunQr? _instance;
  FunQr._();
  factory FunQr() {
    _instance ??= FunQr._();
    return _instance!;
  }

  static QrOptions defaultOptions = _defaultQrOptions;

  Future<bool> saveGalleryForGifCode(String data, String gifUrl) async {
    var gifPath = await generatePathWithGif(data: data, gifUrl: gifUrl);

    var result = await ImageGallerySaver.saveFile(gifPath,
        name: "gif_qr_${DateTime.now().millisecondsSinceEpoch}.gif",
        isReturnPathOfIOS: true);

    if (result is Map && result["errorMessage"] != null) {
      print(result["errorMessage"]);
    }

    return result['isSuccess'] ?? false;
  }

  Future<ui.Image> generateImage({String data = '', ui.Image? bgImage}) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();

    Canvas canvas = Canvas(recorder);

    FunQrPainter(data: data, options: _defaultQrOptions, backgroundImg: bgImage)
        .paint(canvas, const Size(500, 500));

    ui.Picture picture = recorder.endRecording();

    int imageWidth = bgImage != null ? bgImage.width : 200;
    int imageHeight = bgImage != null ? bgImage.height : 200;
    ui.Image image = await picture.toImage(imageWidth, imageHeight);

    return image;
  }

  Future<ByteData?> generateByte(String data, ui.Image bgImage) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);

    FunQrPainter(data: data, options: _defaultQrOptions, backgroundImg: bgImage)
        .paint(
            canvas, Size(bgImage.width.toDouble(), bgImage.height.toDouble()));

    ui.Picture picture = recorder.endRecording();

    ui.Image image = await picture.toImage(bgImage.width, bgImage.height);

    return await image.toByteData(format: ui.ImageByteFormat.png);
  }

  Future<String> generatePathWithGif(
      {String? data = '', String gifUrl = ''}) async {
    // var gifUrl = "https://r.pandoradate.com/qr/GIF/fireworks.gif";

    final url = Uri.parse(gifUrl);
    final ByteData byteData = await NetworkAssetBundle(url).load(url.path);

    final ui.Codec codec =
        await ui.instantiateImageCodec(byteData.buffer.asUint8List());

    final int frameCount = codec.frameCount;

    final List<ByteData> bgImageCodes = [];
    for (int i = 0; i < frameCount; i++) {
      // Get the next frame
      final ui.FrameInfo fi = await codec.getNextFrame();

      var bgImageCodeByte = await generateByte(data!, fi.image);
      if (bgImageCodeByte != null) {
        bgImageCodes.add(bgImageCodeByte);
      }
    }

    print("total $frameCount frame");

    var gifPath =
        "${(await getTemporaryDirectory()).path}/fun_qr_${DateTime.now().millisecondsSinceEpoch}.gif";
    List<int>? combineGif = await generateGif(bgImageCodes);
    if (combineGif != null) {
      File gifFile = await File(gifPath).writeAsBytes(combineGif);
    }

    return gifPath;
  }

  Future<List<int>?> generateGif(List<ByteData> dataList) async {
    final img.PngDecoder decoder = img.PngDecoder();

    final img.Animation animation = img.Animation();

    for (var imgByte in dataList) {
      img.Image image = decoder.decodeImage(imgByte.buffer.asUint8List())!;
      animation.addFrame(image);
    }

    List<int>? gif = img.encodeGifAnimation(animation, samplingFactor: 50);
    return gif;
  }
}

QrOptions _defaultQrOptions = QrOptions(
    padding: 0,
    shapes: const QrShapes(
        lightPixel: QrPixelShapeCircle(radiusFraction: 0.6),
        darkPixel: QrPixelShapeCircle(radiusFraction: 0.6),
        frame: QrFrameShapeDefault(),
        ball: QrBallShapeDefault()),
    colors: QrColors(
        background: const QrColorSolid(Colors.transparent),
        frame: const QrColorSolid(Colors.black),
        ball: const QrColorSolid(Colors.black),
        dark: const QrColorSolid(Colors.black),
        light: QrColorSolid(Colors.white.withOpacity(0.6))));

class FunQrPainter extends CustomPainter {
  final String data;
  final QrOptions options;
  late ByteMatrix matrix;

  ui.Image? backgroundImg;

  FunQrPainter(
      {required this.data, required this.options, this.backgroundImg}) {
    matrix = Encoder.encode(data, options.ecl).matrix!;

    var width = matrix.width ~/ 4;
    if (width % 2 != matrix.width % 2) {
      width++;
    }
    var height = matrix.height ~/ 4;
    if (height % 2 != matrix.height % 2) {
      height++;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final codeSize = min(size.width, size.height);

    if (backgroundImg != null) {
      canvas.drawImageRect(
          backgroundImg!,
          Rect.fromLTWH(0, 0, backgroundImg!.width.toDouble(),
              backgroundImg!.height.toDouble()),
          Rect.fromLTWH(0, 0, codeSize, codeSize),
          Paint());
    }

    final padding = codeSize * options.padding / 2;
    final pixelSize = (codeSize - 2 * padding) / matrix.width;
    final realCodeSize = codeSize - padding * 2;
    final lightPaint =
        options.colors.light.createPaint(realCodeSize, realCodeSize);
    final darkPaint =
        options.colors.dark.createPaint(realCodeSize, realCodeSize);
    Path? darkPath;
    Path fullDarkPath = Path();
    Path? myLightPath;
    Path fullMyLightPath = Path();

    var frameSize = pixelSize * 7;
    var ballSize = pixelSize * 3;

    final framePathZeroOffset = options.shapes.frame
        .createPath(Offset.zero, frameSize, Neighbors.empty);
    final framePaint =
        options.colors.frame.createPaint(pixelSize * 1, pixelSize * 1);

    final ballPathZeroOffset = options.shapes.ball
        .createPath(Offset.zero, pixelSize * 3, Neighbors.empty);
    final ballPaint =
        options.colors.ball.createPaint(pixelSize * 3, pixelSize * 3);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        options.colors.background.createPaint(size.width, size.height));

    canvas.save();
    canvas.translate(padding, padding);

    void drawFrame(double dx, double dy) {
      if (options.colors.frame is! QrColorUnspecified) {
        canvas.save();
        canvas.translate(dx, dy);
        canvas.drawRect(Rect.fromLTRB(0, 0, frameSize, frameSize),
            options.colors.light.createPaint(frameSize, frameSize));
        canvas.drawPath(framePathZeroOffset, framePaint);
        canvas.restore();
      } else {
        var path = options.shapes.frame
            .createPath(Offset(dx, dy), frameSize, Neighbors.empty);
        canvas.drawPath(path, darkPaint);
      }
    }

    void drawBall(double dx, double dy) {
      if (options.colors.ball is! QrColorUnspecified) {
        canvas.save();
        canvas.translate(dx, dy);
        canvas.drawPath(ballPathZeroOffset, ballPaint);
        canvas.restore();
      } else {
        var path = options.shapes.ball
            .createPath(Offset(dx, dy), ballSize, Neighbors.empty);
        canvas.drawPath(path, darkPaint);
      }
    }

    drawFrame(0, 0);
    drawBall(pixelSize * 2, pixelSize * 2);

    drawFrame(pixelSize * (matrix.width - 7), 0);
    drawBall(pixelSize * (matrix.width - 5), pixelSize * 2);

    drawFrame(0, pixelSize * (matrix.width - 7));
    drawBall(pixelSize * 2, pixelSize * (matrix.height - 5));

    for (int i = 0; i < matrix.width; i++) {
      for (int j = 0; j < matrix.height; j++) {
        if ((i.inRange(0, 6) && j.inRange(0, 6) ||
            i.inRange(matrix.width - 7, matrix.width - 1) && j.inRange(0, 6) ||
            j.inRange(matrix.height - 7, matrix.height - 1) &&
                i.inRange(0, 6))) {
          continue;
        }

        if (options.colors.dark is! QrColorUnspecified) {
          darkPath = options.shapes.darkPixel
              .createPath(Offset.zero, pixelSize, matrix.neighbors(i, j));
        }

        if (options.colors.light is! QrColorUnspecified) {
          myLightPath = options.shapes.lightPixel
              .createPath(Offset.zero, pixelSize, matrix.neighbors(i, j));
        }

        if (matrix.get(i, j) == 1 &&
            options.colors.dark is! QrColorUnspecified) {
          fullDarkPath.addPath(darkPath!, Offset(i * pixelSize, j * pixelSize));
        }
        if (matrix.get(i, j) == 0 &&
            options.colors.light is! QrColorUnspecified) {
          fullMyLightPath.addPath(
              myLightPath!, Offset(i * pixelSize, j * pixelSize));
        }
      }
    }

    if (options.colors.dark is! QrColorUnspecified) {
      canvas.drawPath(fullDarkPath, darkPaint);
    }
    if (options.colors.light is! QrColorUnspecified) {
      canvas.drawPath(fullMyLightPath, lightPaint);
    }
    canvas.restore();
  }

  @override
  bool operator ==(Object other) =>
      other is QrPainter && other.data == data && other.options == options;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }

  @override
  int get hashCode => (data.hashCode) * 31 + options.hashCode;
}
