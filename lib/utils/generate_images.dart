import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  final List<Map<String, dynamic>> images = [
    {
      'color': Colors.blue.shade700,
      'text': 'Legal Services',
      'subtext': 'Professional Legal Solutions',
    },
    {
      'color': Colors.purple.shade700,
      'text': 'Case Management',
      'subtext': 'Efficient Case Tracking',
    },
    {
      'color': Colors.green.shade700,
      'text': 'Client Portal',
      'subtext': 'Secure Client Access',
    },
    {
      'color': Colors.orange.shade700,
      'text': 'Document Management',
      'subtext': 'Organized Legal Documents',
    },
  ];

  for (var i = 0; i < images.length; i++) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(800, 400);

    // Draw background
    final paint = Paint()
      ..color = images[i]['color']
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    // Draw gradient overlay
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.black.withOpacity(0.2),
        Colors.transparent,
      ],
    );
    final gradientPaint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, gradientPaint);

    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: images[i]['text'],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2 - 20,
      ),
    );

    // Draw subtext
    final subtextPainter = TextPainter(
      text: TextSpan(
        text: images[i]['subtext'],
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subtextPainter.layout();
    subtextPainter.paint(
      canvas,
      Offset(
        (size.width - subtextPainter.width) / 2,
        (size.height - subtextPainter.height) / 2 + 20,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/legal${i + 1}.png';
    final file = File(imagePath);
    await file.writeAsBytes(buffer);

    print('Created image: $imagePath');
  }

  // Copy images to assets/images directory
  final assetsDir = Directory('assets/images');
  if (!await assetsDir.exists()) {
    await assetsDir.create(recursive: true);
  }

  for (var i = 1; i <= 4; i++) {
    final sourceFile =
        File('${(await getApplicationDocumentsDirectory()).path}/legal$i.png');
    final targetFile = File('${assetsDir.path}/legal$i.jpg');

    if (await sourceFile.exists()) {
      await sourceFile.copy(targetFile.path);
      print('Copied legal$i.png to assets/images/legal$i.jpg');
    }
  }
}
