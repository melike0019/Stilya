import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth/auth_gate.dart';

// ─── Renk paleti (moda tonu, sadece pembe değil) ──────────────────────────────
const List<Color> _palette = [
  Color(0xFFC4607E), // gül
  Color(0xFFBF6050), // terracotta
  Color(0xFFC8A050), // altın
  Color(0xFF7A9870), // adaçayı
  Color(0xFF6888A8), // çelik mavisi
  Color(0xFF9070B0), // lavanta
  Color(0xFF803050), // bordo
  Color(0xFFD07060), // mercan
  Color(0xFF508888), // teal
  Color(0xFFC0A880), // deve tüyü
  Color(0xFFB05878), // gül kurusu
  Color(0xFF809060), // zeytin yeşili
];

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Faz 1 — ince çizgiler akar, S harfi şekli oluşur (0.00 → 0.52)
  late final Animation<double> _linesAnim;

  // Faz 2 — S bir süre durur (0.52 → 0.62), sonra solar (0.58 → 0.72)
  late final Animation<double> _sFade;

  // Faz 3 — STILYA yazısı yükselir (0.68 → 0.84)
  late final Animation<double> _titleFade;
  late final Animation<double> _titleRise;

  // Faz 4 — Tagline soluktan → parıltılı (0.80 → 0.98)
  late final Animation<double> _tagAnim;

  List<_LineData>? _lines;
  Size? _cachedSize;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5200));

    _linesAnim = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.00, 0.52, curve: Curves.easeInOut));

    _sFade = CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.58, 0.72, curve: Curves.easeOut))
        .drive(Tween(begin: 1.0, end: 0.0));

    _titleFade = CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.68, 0.84, curve: Curves.easeIn))
        .drive(Tween(begin: 0.0, end: 1.0));

    _titleRise = CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.68, 0.84, curve: Curves.easeOutCubic))
        .drive(Tween(begin: 1.0, end: 0.0)); // 1→0 means offset goes 40→0

    _tagAnim = CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.80, 0.98, curve: Curves.easeIn))
        .drive(Tween(begin: 0.0, end: 1.0));

    _ctrl.forward().then((_) {
      if (mounted) _navigate();
    });
  }

  void _initLines(Size size) {
    if (_cachedSize == size) return;
    _cachedSize = size;
    _lines = _LineData.generate(size);
  }

  void _navigate() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, secAnim) => const AuthGate(),
        transitionsBuilder: (ctx, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EEF0), // çok soft pembe-krem
      body: LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initLines(size);
        final lines = _lines;
        if (lines == null) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // ── Faz 1-2: Çizgilerden oluşan renkli S ────────────
                Opacity(
                  opacity: _sFade.value,
                  child: CustomPaint(
                    painter: _LinePainter(
                      lines: lines,
                      progress: _linesAnim.value,
                    ),
                    size: Size.infinite,
                  ),
                ),

                // ── Faz 3-4: STILYA + tagline ────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // STILYA
                    Opacity(
                      opacity: _titleFade.value,
                      child: Transform.translate(
                        offset: Offset(0, 44.0 * _titleRise.value),
                        child: Text(
                          'STILYA',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3A1825),
                            letterSpacing: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tagline — soluktan parıltılı canlıya
                    _TaglineWidget(progress: _tagAnim.value),
                  ],
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

// ─── Tagline: soluk → parıltılı (ShaderMask shimmer) ─────────────────────────
class _TaglineWidget extends StatelessWidget {
  final double progress;
  const _TaglineWidget({required this.progress});

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();

    final opacity = (progress * 1.3).clamp(0.0, 1.0);
    final shimmerPos = Curves.easeOut.transform(progress);

    return Opacity(
      opacity: opacity,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFF9A7080), // soluk
            Color(0xFF3A1825), // canlı koyu
            Color(0xFF9A7080), // soluk
          ],
          stops: [
            (shimmerPos - 0.45).clamp(0.0, 1.0),
            shimmerPos.clamp(0.0, 1.0),
            (shimmerPos + 0.45).clamp(0.0, 1.0),
          ],
        ).createShader(bounds),
        child: Text(
          'Stilin, Sana Özgü',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// ─── Çizgi verisi ─────────────────────────────────────────────────────────────
class _LineData {
  final Offset start;
  final Offset ctrl1;
  final Offset ctrl2;
  final Offset end;
  final Color color;
  final double delay; // 0.0 – 0.40
  final double width; // 0.8 – 2.4

  Path? _cachedPath;

  _LineData({
    required this.start,
    required this.ctrl1,
    required this.ctrl2,
    required this.end,
    required this.color,
    required this.delay,
    required this.width,
  });

  Path get path {
    _cachedPath ??= Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, end.dx, end.dy);
    return _cachedPath!;
  }

  static List<_LineData> generate(Size size) {
    final rng = math.Random(2025);
    final endPoints = _sampleSPath(size, 90);

    return endPoints.map((endPt) {
      // Ekranın 4 kenarından rastgele başlangıç
      final edge = rng.nextInt(4);
      final Offset start;
      switch (edge) {
        case 0:
          start = Offset(rng.nextDouble() * size.width, -30);
          break;
        case 1:
          start = Offset(size.width + 30, rng.nextDouble() * size.height);
          break;
        case 2:
          start = Offset(rng.nextDouble() * size.width, size.height + 30);
          break;
        default:
          start = Offset(-30, rng.nextDouble() * size.height);
      }

      // ctrl1: tamamen rastgele (çizgi önce "yanlış" yöne gider — dalgalanma efekti)
      final ctrl1 = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );

      // ctrl2: hedefe yakın ama offset'li (son dönüşü oluşturur)
      final ctrl2 = Offset(
        (ctrl1.dx + endPt.dx) * 0.5 +
            (rng.nextDouble() - 0.5) * size.width * 0.5,
        (ctrl1.dy + endPt.dy) * 0.5 +
            (rng.nextDouble() - 0.5) * size.height * 0.4,
      );

      return _LineData(
        start: start,
        ctrl1: ctrl1,
        ctrl2: ctrl2,
        end: endPt,
        color: _palette[rng.nextInt(_palette.length)],
        delay: rng.nextDouble() * 0.40,
        width: 0.8 + rng.nextDouble() * 1.6,
      );
    }).toList();
  }

  // ── S harfi yolu ─────────────────────────────────────────────────────────
  static Path _buildSPath(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    // S'i ekranın yukarı kısmında konumlandır (metin için altta alan bırak)
    final cy = h * 0.40;

    final sw = w * 0.20; // S yatay yarı-çap
    final sh = h * 0.11; // S dikey yarı-çap (her bir yay için)

    final path = Path();

    // ── Üst yatay çizgi (sağdan sola) ───────────────────────────
    path.moveTo(cx + sw * 0.72, cy - sh * 1.85);
    path.lineTo(cx - sw * 0.50, cy - sh * 1.85);

    // ── Üst yay: sol taraftan aşağı kıvrılır → merkeze gelir ────
    path.moveTo(cx + sw * 0.72, cy - sh * 1.85);
    path.cubicTo(
      cx - sw * 0.55, cy - sh * 1.85, // üste sola uzanır
      cx - sw * 1.10, cy - sh * 1.10, // sol dış kıvrım
      cx - sw * 1.10, cy - sh * 0.30, // sol yan, orta hizasına iner
    );
    path.cubicTo(
      cx - sw * 1.10, cy + sh * 0.05, // sol altta döner
      cx - sw * 0.15, cy - sh * 0.05, // merkeze yaklaşır
      cx, cy,                          // merkez bel noktası
    );

    // ── Alt yay: merkezden sağ tarafa kıvrılır → aşağı iner ────
    path.moveTo(cx, cy);
    path.cubicTo(
      cx + sw * 0.15, cy + sh * 0.05,
      cx + sw * 1.10, cy - sh * 0.05,
      cx + sw * 1.10, cy + sh * 0.30,
    );
    path.cubicTo(
      cx + sw * 1.10, cy + sh * 1.10, // sağ dış kıvrım
      cx + sw * 0.55, cy + sh * 1.85, // alta sağa uzanır
      cx - sw * 0.72, cy + sh * 1.85, // alt sol uç
    );

    // ── Alt yatay çizgi (sağdan sola) ───────────────────────────
    path.moveTo(cx + sw * 0.50, cy + sh * 1.85);
    path.lineTo(cx - sw * 0.72, cy + sh * 1.85);

    return path;
  }

  // S yolu üzerinde eşit aralıklı noktalar örnekle
  static List<Offset> _sampleSPath(Size size, int count) {
    final path = _buildSPath(size);
    final metrics = path.computeMetrics().toList();
    final totalLen = metrics.fold(0.0, (s, m) => s + m.length);
    if (totalLen == 0) return [];

    final points = <Offset>[];
    for (final metric in metrics) {
      final n = (count * metric.length / totalLen).round().clamp(1, count);
      for (int i = 0; i < n; i++) {
        final d = metric.length * (i + 0.5) / n;
        final t = metric.getTangentForOffset(d);
        if (t != null) points.add(t.position);
      }
    }
    return points;
  }
}

// ─── Çizgi Painter ────────────────────────────────────────────────────────────
class _LinePainter extends CustomPainter {
  final List<_LineData> lines;
  final double progress;

  const _LinePainter({required this.lines, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      // Her çizginin gecikme sonrası yerel ilerleme değeri
      final localProg =
          ((progress - line.delay) / (1.0 - line.delay)).clamp(0.0, 1.0);
      if (localProg <= 0) continue;

      // Bezier yolunun şu ana kadar olan kısmını çiz
      for (final metric in line.path.computeMetrics()) {
        final partial =
            metric.extractPath(0, metric.length * localProg);

        canvas.drawPath(
          partial,
          Paint()
            ..color = line.color.withAlpha(200)
            ..strokeWidth = line.width
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.progress != progress;
}
