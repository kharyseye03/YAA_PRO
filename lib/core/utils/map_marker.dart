import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

/// Dessine un marqueur « pin arrondi » (cercle coloré + anneau blanc
/// + pointe + icône au centre) et l'enregistre auprès du SDK Maps.
///
/// Même rendu que l'app client YAA, pour garder les deux applications
/// visuellement cohérentes. Pour ajuster la taille, jouer sur [w],
/// [circleR] et [stemH] en gardant les proportions.
Future<ImageDescriptor> createMarkerImage(Color color, IconData icon) async {
  const double w = 78, circleR = 29, stemH = 14;
  final center = Offset(w / 2, circleR + 5);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Ombre douce
  canvas.drawCircle(
    center.translate(0, 2),
    circleR + 4,
    Paint()..color = Colors.black.withValues(alpha: 0.15),
  );

  // Anneau blanc
  canvas.drawCircle(center, circleR + 4, Paint()..color = Colors.white);

  // Cercle coloré
  final fill = Paint()..color = color;
  canvas.drawCircle(center, circleR, fill);

  // Pointe (triangle vers le bas)
  final stem = Path()
    ..moveTo(center.dx - 9, center.dy + circleR - 4)
    ..lineTo(center.dx + 9, center.dy + circleR - 4)
    ..lineTo(center.dx, center.dy + circleR + stemH)
    ..close();
  canvas.drawPath(stem, fill);

  // Icône blanche au centre
  final tp = TextPainter(textDirection: TextDirection.ltr)
    ..text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 30,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    )
    ..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

  final img = await recorder
      .endRecording()
      .toImage(w.toInt(), (circleR + 5 + circleR + stemH + 4).toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);

  // Le SDK Navigation ne prend pas de BitmapDescriptor : les images
  // passent par son registre et sont référencées par un descripteur.
  return registerBitmapImage(bitmap: data!);
}
