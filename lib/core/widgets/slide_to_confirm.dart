import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/constants.dart';

/// Action à valider en faisant glisser le curseur d'un bout à l'autre.
///
/// Utilisé pour les gestes irréversibles du livreur (colis récupéré,
/// colis livré) : un simple appui se déclenche par accident quand le
/// téléphone est manipulé en roulant, un glissement non.
class SlideToConfirm extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onConfirm;

  const SlideToConfirm({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onConfirm,
    this.busy = false,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _dragX = 0;
  bool _dragging = false;

  /// Part du parcours à franchir pour que l'action se déclenche.
  static const _seuil = 0.75;

  @override
  Widget build(BuildContext context) {
    final hauteur = 58.h;
    final tailleCurseur = hauteur - 8.h;

    return LayoutBuilder(
      builder: (context, constraints) {
        final course = constraints.maxWidth - tailleCurseur - 8.w;
        // Le texte s'efface à mesure que le curseur avance
        final progression = course > 0 ? (_dragX / course).clamp(0.0, 1.0) : 0.0;

        void terminer() {
          if (progression >= _seuil) {
            setState(() {
              _dragging = false;
              _dragX = course;
            });
            widget.onConfirm();
            // Le curseur revient une fois l'action lancée
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) setState(() => _dragX = 0);
            });
          } else {
            setState(() {
              _dragging = false;
              _dragX = 0;
            });
          }
        }

        return Container(
          height: hauteur,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(hauteur / 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Libellé, estompé pendant le glissement
              Opacity(
                opacity: widget.busy ? 0 : (1 - progression * 1.4).clamp(0.0, 1.0),
                child: Padding(
                  padding: EdgeInsets.only(left: tailleCurseur),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: widget.color,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(LucideIcons.chevronsRight,
                          size: 18.r,
                          color: widget.color.withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              ),

              if (widget.busy)
                SizedBox(
                  height: 22.r,
                  width: 22.r,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: widget.color),
                ),

              // Curseur
              if (!widget.busy)
                AnimatedPositioned(
                  duration: Duration(milliseconds: _dragging ? 0 : 220),
                  curve: Curves.easeOut,
                  left: 4.w + _dragX,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) =>
                        setState(() => _dragging = true),
                    onHorizontalDragUpdate: (d) => setState(() {
                      _dragX = (_dragX + d.delta.dx).clamp(0.0, course);
                    }),
                    onHorizontalDragEnd: (_) => terminer(),
                    onHorizontalDragCancel: terminer,
                    child: Container(
                      width: tailleCurseur,
                      height: tailleCurseur,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(widget.icon,
                          color: AppColors.white, size: 22.r),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
