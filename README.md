<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

generate gif for custom code with gif background image

// display custom code in widget tree

## Features

![](https://github.com/hongeSunCoder/fun_qr_generator/blob/main/example/template_qr.jpg)
![](https://github.com/hongeSunCoder/fun_qr_generator/blob/main/example/gif_qr.GIF)

## Getting started


## Usage



```dart

// use custom qr in widget tree
Container(
    decoration: const BoxDecoration(
        image:
            DecorationImage(image: AssetImage("your asset image"))),
    child: CustomPaint(
    size: const Size(200, 200),
    painter: FunQrPainter(
        data: "data",
        options: FunQr.defaultOptions,
    )),
)


// use the temp gif path to save gallery or do other things
String gifPath = await FunQr().generatePathWithGif(
              data: "qr content", gifUrl: "https://yourgif.gif");

          
```

## Additional information


