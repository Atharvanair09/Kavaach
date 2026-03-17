import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const SafeTextApp());
}

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────

class ST {
  // Backgrounds
  static const bg = Color(0xFF0F172A);
  static const bgCard = Color(0xFF1E293B);
  static const surface = Color(0xFF334155);
  static const surfaceHover = Color(0xFF475569);

  // Accents
  static const purple = Color(0xFF10B981);
  static const purpleLight = Color(0xFF34D399);
  static const purpleDim = Color(0x1F10B981);
  static const pink = Color(0xFF3B82F6);
  static const pinkDim = Color(0x263B82F6);
  static const pinkGlow = Color(0x593B82F6);
  static const teal = Color(0xFF8B5CF6);
  static const tealDim = Color(0x268B5CF6);
  static const amber = Color(0xFFF59E0B);
  static const amberDim = Color(0x26F59E0B);

  // Text
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFFCBD5E1);
  static const textMuted = Color(0xFF64748B);

  // Borders
  static const border = Color(0x1F94A3B8);
  static const borderGlow = Color(0x4D10B981);

  // Risk colours
  static const riskLow = purple;
  static const riskMed = amber;
  static const riskHigh = Color(0xFFEF4444);

  // Gradients
  static const gradPrimary = LinearGradient(
    colors: [purple, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradPurple = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradBubbleUser = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography helpers
  static TextStyle display(double size, {FontWeight weight = FontWeight.w800, Color color = textPrimary}) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: weight, color: color, letterSpacing: -0.5);

  static TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color color = textPrimary}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

  // Glassmorphism decoration
  static BoxDecoration glass({Color? borderColor, double radius = 16}) => BoxDecoration(
    color: const Color(0xB80F172A),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? border, width: 1),
  );

  static BoxDecoration glassCard({Color accent = purple, double radius = 16}) => BoxDecoration(
    color: Color.fromRGBO(accent.red, accent.green, accent.blue, 0.06),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Color.fromRGBO(accent.red, accent.green, accent.blue, 0.14), width: 1),
  );
}

// ─── APP SHELL ─────────────────────────────────────────────────────────────────

class SafeTextApp extends StatelessWidget {
  const SafeTextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeText',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ST.bg,
        colorScheme: const ColorScheme.dark(
          primary: ST.purple,
          secondary: ST.pink,
          surface: ST.surface,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AppNavigator(),
    );
  }
}

// ─── APP STATE ─────────────────────────────────────────────────────────────────

enum AppFlow { onboarding, secureEntry, fakeNotes, mainApp }
enum RiskLevel { low, medium, high }

class AppState extends ChangeNotifier {
  AppFlow flow = AppFlow.onboarding;
  RiskLevel riskLevel = RiskLevel.low;
  bool locationSharing = false;
  bool escalationActive = false;
  int escalationCountdown = 10;
  Timer? _countdownTimer;

  void setFlow(AppFlow f) { flow = f; notifyListeners(); }
  void setRisk(RiskLevel r) {
    riskLevel = r;
    if (r == RiskLevel.high) { escalationActive = true; _startCountdown(); }
    else { escalationActive = false; _countdownTimer?.cancel(); escalationCountdown = 10; }
    notifyListeners();
  }
  void cancelEscalation() {
    escalationActive = false; _countdownTimer?.cancel(); escalationCountdown = 10;
    notifyListeners();
  }
  void toggleLocation() { locationSharing = !locationSharing; notifyListeners(); }
  void _startCountdown() {
    escalationCountdown = 10;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (escalationCountdown <= 0) { t.cancel(); return; }
      escalationCountdown--;
      notifyListeners();
    });
  }
  @override
  void dispose() { _countdownTimer?.cancel(); super.dispose(); }
}

// ─── APP NAVIGATOR ──────────────────────────────────────────────────────────────

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});
  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  final AppState _state = AppState();

  @override
  void dispose() { _state.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (ctx, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
          child: _buildFlow(),
        );
      },
    );
  }

  Widget _buildFlow() {
    switch (_state.flow) {
      case AppFlow.onboarding:
        return OnboardingScreen(key: const ValueKey('onboarding'), onComplete: () => _state.setFlow(AppFlow.secureEntry));
      case AppFlow.secureEntry:
        return SecureEntryScreen(key: const ValueKey('entry'), onUnlock: () => _state.setFlow(AppFlow.mainApp), onQuickExit: () => _state.setFlow(AppFlow.fakeNotes));
      case AppFlow.fakeNotes:
        return FakeNotesScreen(key: const ValueKey('notes'), onReturn: () => _state.setFlow(AppFlow.secureEntry));
      case AppFlow.mainApp:
        return MainAppShell(key: const ValueKey('app'), appState: _state);
    }
  }
}

// ─── SHARED WIDGETS ─────────────────────────────────────────────────────────────

class STStatusBar extends StatelessWidget {
  const STStatusBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('9:41', style: ST.body(12, weight: FontWeight.w600, color: ST.textSecondary)),
          Row(children: [
            const Icon(Icons.wifi, size: 13, color: ST.textMuted),
            const SizedBox(width: 5),
            Text('●●●●', style: ST.body(9, color: ST.textMuted)),
          ]),
        ],
      ),
    );
  }
}

class RiskBadge extends StatefulWidget {
  final RiskLevel level;
  const RiskBadge({super.key, required this.level});
  @override
  State<RiskBadge> createState() => _RiskBadgeState();
}

class _RiskBadgeState extends State<RiskBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cfg = switch (widget.level) {
      RiskLevel.low    => (color: ST.riskLow, label: 'Safe'),
      RiskLevel.medium => (color: ST.riskMed, label: 'Aware'),
      RiskLevel.high   => (color: ST.riskHigh, label: 'Elevated'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Color.fromRGBO(cfg.color.red, cfg.color.green, cfg.color.blue, 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color.fromRGBO(cfg.color.red, cfg.color.green, cfg.color.blue, 0.28), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Opacity(
            opacity: widget.level != RiskLevel.low ? _pulse.value : 0.8,
            child: Container(width: 6, height: 6, decoration: BoxDecoration(color: cfg.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: cfg.color.withOpacity(0.5), blurRadius: 6)])),
          ),
        ),
        const SizedBox(width: 5),
        Text(cfg.label, style: ST.body(10, weight: FontWeight.w700, color: cfg.color).copyWith(letterSpacing: 0.8)),
      ]),
    );
  }
}

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double? width;
  final double height;
  final double fontSize;
  const GradientButton({super.key, required this.label, required this.onTap, this.width, this.height = 52, this.fontSize = 15});
  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: ST.gradPrimary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: ST.purple.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          alignment: Alignment.center,
          child: Text(widget.label, style: ST.body(widget.fontSize, weight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double? width;
  final double height;
  final double fontSize;
  const GhostButton({super.key, required this.label, required this.onTap, this.width, this.height = 52, this.fontSize = 14});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ST.border, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(label, style: ST.body(fontSize, color: ST.textSecondary)),
      ),
    );
  }
}

class AmbientBlob extends StatefulWidget {
  final Color color;
  final double size;
  final Duration delay;
  const AmbientBlob({super.key, required this.color, required this.size, this.delay = Duration.zero});
  @override
  State<AmbientBlob> createState() => _AmbientBlobState();
}

class _AmbientBlobState extends State<AmbientBlob> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.8).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.12),
          ),
          child: BackdropFilter(
            filter: const ColorFilter.srgbToLinearGamma(),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

// ─── SCREEN 1: ONBOARDING ────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final _slides = const [
    _OnboardSlide(icon: Icons.shield_outlined, accent: ST.purple, title: 'You are not alone.', body: 'SafeText is a private space designed for your safety. Everything here is anonymous, encrypted, and completely discreet.', sub: 'No one else will know you\'re here.'),
    _OnboardSlide(icon: Icons.visibility_outlined, accent: ST.purpleLight, title: 'Completely anonymous.', body: 'Your identity is never stored. No name, no number, no trace. Communicate as freely as you need to.', sub: 'AI-powered. Human-backed.'),
    _OnboardSlide(icon: Icons.psychology_outlined, accent: ST.pink, title: 'We understand context.', body: 'Our AI reads between the lines — detecting stress, urgency, and risk so you don\'t have to say everything out loud.', sub: 'Silent awareness. Quiet strength.'),
    _OnboardSlide(icon: Icons.notifications_none_outlined, accent: ST.teal, title: 'Help, on your terms.', body: 'A hidden gesture, a code word, or a quiet tap — your emergency triggers work however you need them to.', sub: 'Discreet. Immediate. Yours.'),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() { _pageCtrl.dispose(); _fadeCtrl.dispose(); super.dispose(); }

  void _next() {
    if (_page < _slides.length - 1) {
      _fadeCtrl.reverse().then((_) {
        _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
        setState(() => _page++);
        _fadeCtrl.forward();
      });
    } else { widget.onComplete(); }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return Scaffold(
      backgroundColor: ST.bg,
      body: Stack(children: [
        // Ambient blobs
        Positioned(top: -80, right: -80, child: _GlowBlob(color: slide.accent, size: 280)),
        Positioned(bottom: 120, left: -60, child: _GlowBlob(color: ST.pink, size: 200, delay: const Duration(seconds: 3))),
        SafeArea(child: Column(children: [
          const STStatusBar(),
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(gradient: ST.gradPrimary, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.shield, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text('SafeText', style: ST.display(16, weight: FontWeight.w700)),
            ]),
          ),
          // Content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AnimatedIconRing(icon: slide.icon, accent: slide.accent),
                    const SizedBox(height: 36),
                    Text(slide.title, style: ST.display(30, weight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    Text(slide.body, style: ST.body(15, color: ST.textSecondary).copyWith(height: 1.65)),
                    const SizedBox(height: 12),
                    Text(slide.sub, style: ST.body(13, color: slide.accent, weight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
          // Bottom controls
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
            child: Column(children: [
              // Page dots
              Row(children: List.generate(_slides.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(right: 6),
                width: i == _page ? 20 : 6, height: 6,
                decoration: BoxDecoration(
                  gradient: i == _page ? ST.gradPrimary : null,
                  color: i == _page ? null : ST.textMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ))),
              const SizedBox(height: 24),
              _page < _slides.length - 1
                  ? Row(children: [
                Expanded(child: GhostButton(label: 'Skip', onTap: widget.onComplete)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: GradientButton(label: 'Continue →', onTap: _next)),
              ])
                  : GradientButton(label: 'Enter Safely', onTap: widget.onComplete, width: double.infinity),
            ]),
          ),
        ])),
      ]),
    );
  }
}

class _OnboardSlide {
  final IconData icon;
  final Color accent;
  final String title, body, sub;
  const _OnboardSlide({required this.icon, required this.accent, required this.title, required this.body, required this.sub});
}

class _GlowBlob extends StatefulWidget {
  final Color color;
  final double size;
  final Duration delay;
  const _GlowBlob({required this.color, required this.size, this.delay = Duration.zero});
  @override
  State<_GlowBlob> createState() => _GlowBlobState();
}

class _GlowBlobState extends State<_GlowBlob> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.delay != Duration.zero) Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: widget.size, height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: widget.color.withOpacity(_anim.value * 0.25), blurRadius: widget.size * 0.6, spreadRadius: 0)],
        color: widget.color.withOpacity(_anim.value * 0.08),
      ),
    ),
  );
}

class _AnimatedIconRing extends StatefulWidget {
  final IconData icon;
  final Color accent;
  const _AnimatedIconRing({required this.icon, required this.accent});
  @override
  State<_AnimatedIconRing> createState() => _AnimatedIconRingState();
}

class _AnimatedIconRingState extends State<_AnimatedIconRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.8).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SizedBox(width: 96, height: 96, child: Stack(children: [
    AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 96, height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: widget.accent.withOpacity(_anim.value * 0.3), width: 1),
        ),
      ),
    ),
    Positioned(top: 8,left:8,right:8,bottom:8, child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: widget.accent.withOpacity(0.1),
        border: Border.all(color: widget.accent.withOpacity(0.25), width: 1),
        boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.15), blurRadius: 30)],
      ),
      child: Icon(widget.icon, size: 38, color: widget.accent),
    )),
  ]));
}

// ─── SCREEN 2: SECURE ENTRY ───────────────────────────────────────────────────────

class SecureEntryScreen extends StatefulWidget {
  final VoidCallback onUnlock, onQuickExit;
  const SecureEntryScreen({super.key, required this.onUnlock, required this.onQuickExit});
  @override
  State<SecureEntryScreen> createState() => _SecureEntryScreenState();
}

class _SecureEntryScreenState extends State<SecureEntryScreen> with TickerProviderStateMixin {
  final _target = [1, 4, 9, 2];
  List<int> _pin = [];
  bool _biometricMode = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _bioCtrl;
  late Animation<double> _bioAnim;
  bool _bioScanning = false, _bioSuccess = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
    _bioCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _bioAnim = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _bioCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _shakeCtrl.dispose(); _bioCtrl.dispose(); super.dispose(); }

  void _addDigit(int d) {
    if (_pin.length >= 4) return;
    setState(() => _pin = [..._pin, d]);
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        if (_pin.join() == _target.join()) { widget.onUnlock(); }
        else {
          _shakeCtrl.forward(from: 0).then((_) { if (mounted) setState(() => _pin = []); });
        }
      });
    }
  }

  void _backspace() { if (_pin.isNotEmpty) setState(() => _pin = _pin.sublist(0, _pin.length - 1)); }

  void _triggerBio() {
    setState(() { _bioScanning = true; });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() { _bioScanning = false; _bioSuccess = true; });
      Future.delayed(const Duration(milliseconds: 400), widget.onUnlock);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ST.bg,
      body: Stack(children: [
        Positioned(top: -40, left: -60, child: _GlowBlob(color: ST.purple, size: 260)),
        SafeArea(child: Column(children: [
          const STStatusBar(),
          // Quick Exit button — top right, discreet
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 20, 0),
              child: GestureDetector(
                onTap: widget.onQuickExit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ST.textMuted.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ST.textMuted.withOpacity(0.2)),
                  ),
                  child: Text('Notes ✎', style: ST.body(11, color: ST.textMuted)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Lock icon
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: ST.purple.withOpacity(0.08),
              border: Border.all(color: ST.purple.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: ST.purple.withOpacity(0.12), blurRadius: 30)],
            ),
            child: const Icon(Icons.lock_outline, size: 30, color: ST.purpleLight),
          ),
          const SizedBox(height: 8),
          Text('Welcome back', style: ST.body(13, color: ST.textMuted)),
          const Spacer(),
          if (!_biometricMode) ...[
            // PIN dots with shake animation
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(math.sin(_shakeAnim.value * math.pi * 6) * 10, 0),
                child: child,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.elasticOut,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: _pin.length > i ? 16 : 14,
                height: _pin.length > i ? 16 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _pin.length > i ? ST.gradPrimary : null,
                  color: _pin.length > i ? null : Colors.transparent,
                  border: _pin.length > i ? null : Border.all(color: ST.textMuted.withOpacity(0.4), width: 2),
                  boxShadow: _pin.length > i ? [BoxShadow(color: ST.purple.withOpacity(0.5), blurRadius: 10)] : null,
                ),
              ))),
            ),
            const SizedBox(height: 12),
            Text('Enter your PIN', style: ST.body(13, color: ST.textMuted)),
            const SizedBox(height: 40),
            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Column(children: [
                for (var row in [[1,2,3],[4,5,6],[7,8,9],[null,0,'⌫']])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: row.map((k) => _KeypadButton(
                      label: k?.toString() ?? '',
                      onTap: k == null ? null : (k == '⌫' ? _backspace : () => _addDigit(k as int)),
                    )).toList()),
                  ),
              ]),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() => _biometricMode = true),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.fingerprint, size: 16, color: ST.textMuted),
                const SizedBox(width: 6),
                Text('Use biometrics', style: ST.body(13, color: ST.textMuted)),
              ]),
            ),
          ] else ...[
            // Biometric view
            GestureDetector(
              onTap: _bioScanning || _bioSuccess ? null : _triggerBio,
              child: AnimatedBuilder(
                animation: _bioAnim,
                builder: (_, __) => Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _bioSuccess ? ST.gradPrimary : null,
                    color: _bioSuccess ? null : ST.purple.withOpacity(0.08),
                    border: Border.all(color: _bioScanning ? ST.purple : ST.purple.withOpacity(0.25), width: _bioScanning ? 2 : 1.5),
                    boxShadow: _bioScanning || _bioSuccess ? [BoxShadow(color: ST.purple.withOpacity(_bioAnim.value * 0.5), blurRadius: 40)] : null,
                  ),
                  child: Icon(_bioSuccess ? Icons.check : Icons.fingerprint, size: 50, color: _bioSuccess ? Colors.white : ST.purple),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(_bioScanning ? 'Scanning…' : _bioSuccess ? 'Authenticated ✓' : 'Touch to authenticate',
                style: ST.body(14, color: ST.textSecondary)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() => _biometricMode = false),
              child: Text('Use PIN instead', style: ST.body(13, color: ST.textMuted)),
            ),
          ],
          const Spacer(),
          const SizedBox(height: 40),
        ])),
      ]),
    );
  }
}

class _KeypadButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _KeypadButton({required this.label, this.onTap});
  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.92).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (widget.label.isEmpty) return const SizedBox(width: 72, height: 68);
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 72, height: 68,
          decoration: BoxDecoration(
            color: ST.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ST.border, width: 1),
            boxShadow: [const BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          alignment: Alignment.center,
          child: Text(widget.label, style: widget.label == '⌫'
              ? ST.body(22, color: ST.textSecondary)
              : ST.display(22, weight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ─── SCREEN 3: FAKE NOTES (QUICK EXIT) ────────────────────────────────────────────

class FakeNotesScreen extends StatefulWidget {
  final VoidCallback onReturn;
  const FakeNotesScreen({super.key, required this.onReturn});
  @override
  State<FakeNotesScreen> createState() => _FakeNotesScreenState();
}

class _FakeNotesScreenState extends State<FakeNotesScreen> {
  final _notes = const [
    _NoteItem('Grocery list', '• Oat milk\n• Spinach\n• Greek yogurt\n• Lemons\n• Sourdough bread'),
    _NoteItem('Meeting notes — Tuesday', 'Discussed Q4 goals\nFollow up with team\nSend agenda by Friday'),
    _NoteItem('Book recommendations', '- The Midnight Library\n- Pachinko\n- Braiding Sweetgrass'),
    _NoteItem('Weekend plans', 'Saturday: brunch with Maya\nSunday: farmers market\nCall mom'),
  ];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Notes', style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(10)),
              child: Text('Edit', style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF3A3A3C))),
            ),
          ]),
        ),
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _notes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _selected == i ? const Color(0xFFFFD60A) : Colors.transparent, width: 2),
                boxShadow: [const BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_notes[i].title, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Text(_notes[i].preview, style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF8E8E93)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: GestureDetector(
            onTap: widget.onReturn, // Hidden: in production, this would be a secret gesture
            child: Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(color: const Color(0xFFFFD60A), borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Text('+ New Note', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
            ),
          ),
        ),
      ])),
    );
  }
}

class _NoteItem {
  final String title, preview;
  const _NoteItem(this.title, this.preview);
}

// ─── SCREEN 4: MAIN APP SHELL ─────────────────────────────────────────────────────

class MainAppShell extends StatefulWidget {
  final AppState appState;
  const MainAppShell({super.key, required this.appState});
  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (ctx, _) {
        final screens = [
          ChatScreen(appState: widget.appState),
          const LocationScreen(),
          const HelplineScreen(),
          const DashboardScreen(),
        ];
        return Scaffold(
          backgroundColor: ST.bg,
          body: Stack(children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(_tab), child: Padding(
                padding: const EdgeInsets.only(bottom: 72),
                child: screens[_tab],
              )),
            ),
            Positioned(bottom: 0, left: 0, right: 0, child: _BottomNav(current: _tab, onTap: (i) => setState(() => _tab = i))),
          ]),
        );
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (icon: Icons.chat_bubble_outline, label: 'Chat'),
      (icon: Icons.location_on_outlined, label: 'Nearby'),
      (icon: Icons.favorite_outline, label: 'Support'),
      (icon: Icons.grid_view_outlined, label: 'Manage'),
    ];
    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xB8080B14),
          border: const Border(top: BorderSide(color: ST.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (i) {
                final t = tabs[i];
                final isActive = current == i;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? ST.purple.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Icon(t.icon, size: 22, color: isActive ? ST.purpleLight : ST.textMuted),
                        if (i == 3) Positioned(top: -2, right: -2, child: Container(
                          width: 7, height: 7,
                          decoration: const BoxDecoration(color: ST.pink, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Color(0x99F472B6), blurRadius: 6)]),
                        )),
                      ]),
                      const SizedBox(height: 4),
                      Text(t.label, style: ST.body(10, weight: FontWeight.w500, color: isActive ? ST.purpleLight : ST.textMuted)),
                      if (isActive) ...[
                        const SizedBox(height: 3),
                        Container(width: 4, height: 4, decoration: BoxDecoration(
                          gradient: ST.gradPrimary, borderRadius: BorderRadius.circular(2),
                        )),
                      ],
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SCREEN 5: CHAT ───────────────────────────────────────────────────────────────

class ChatMessage {
  final String text, time;
  final bool isUser;
  ChatMessage({required this.text, required this.time, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  final AppState appState;
  const ChatScreen({super.key, required this.appState});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isAnalyzing = false, _showPrompts = false, _isRecording = false;
  int _headerTapCount = 0;
  Timer? _tapTimer;
  late AnimationController _borderCtrl;
  late Animation<double> _borderAnim;
  late AnimationController _escalCtrl;
  late Animation<Offset> _escalSlide;

  final List<ChatMessage> _messages = [
    ChatMessage(text: "Hi, I'm here with you. This is a safe, private space. How are you feeling right now?", time: "9:38", isUser: false),
    ChatMessage(text: "I'm okay, just needed somewhere to talk", time: "9:39", isUser: true),
    ChatMessage(text: "I'm glad you're here. Take your time — there's no rush. Would you like to tell me more about what's on your mind?", time: "9:39", isUser: false),
  ];

  final _prompts = const ['I feel unsafe right now', 'I need someone to talk to', 'Can you find help near me?', 'Share my location quietly'];

  @override
  void initState() {
    super.initState();
    _borderCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _borderAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _borderCtrl, curve: Curves.easeInOut));
    _escalCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _escalSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _escalCtrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() { _textCtrl.dispose(); _scrollCtrl.dispose(); _borderCtrl.dispose(); _escalCtrl.dispose(); _tapTimer?.cancel(); super.dispose(); }

  void _onHeaderTap() {
    _headerTapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(seconds: 3), () => _headerTapCount = 0);
    if (_headerTapCount >= 5) {
      _headerTapCount = 0;
      widget.appState.setRisk(RiskLevel.high);
      _escalCtrl.forward();
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text.trim(), time: 'now', isUser: true));
      _isAnalyzing = true;
      _showPrompts = false;
    });
    _textCtrl.clear();
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      final responses = {
        RiskLevel.low: 'Thank you for sharing that with me. I\'m here, and I\'m listening.',
        RiskLevel.medium: 'I hear you. It sounds like things might be difficult right now. Would it help to let a trusted contact know you\'re okay?',
        RiskLevel.high: 'I\'m with you right now. I\'ve quietly identified support services near you. Would you like me to prepare an emergency notification?',
      };
      setState(() {
        _isAnalyzing = false;
        _messages.add(ChatMessage(text: responses[widget.appState.riskLevel]!, time: 'now', isUser: false));
        if (widget.appState.riskLevel == RiskLevel.high) _escalCtrl.forward();
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() => Future.delayed(const Duration(milliseconds: 100), () {
    if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  Color get _borderColor => switch (widget.appState.riskLevel) {
    RiskLevel.low    => Colors.transparent,
    RiskLevel.medium => ST.amber.withOpacity(0.25),
    RiskLevel.high   => ST.pink.withOpacity(0.3),
  };

  @override
  Widget build(BuildContext context) {
    // Bottom nav height + safe area so input bar never hides behind nav
    final bottomNavHeight = 72 + MediaQuery.of(context).padding.bottom;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      decoration: BoxDecoration(
        color: ST.bg,
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: widget.appState.riskLevel == RiskLevel.high ? [BoxShadow(color: ST.pink.withOpacity(0.06), blurRadius: 60, spreadRadius: 20)] : [],
      ),
      child: Column(children: [
        const STStatusBar(),
        // Header — silent tap zone
        GestureDetector(
          onTap: _onHeaderTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: ST.purple.withOpacity(0.1),
                  border: Border.all(color: ST.purple.withOpacity(0.2)),
                ),
                child: const Icon(Icons.shield_outlined, size: 20, color: ST.purpleLight),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SafeText', style: ST.display(15, weight: FontWeight.w700)),
                Text('Private & encrypted', style: ST.body(11, color: ST.textMuted)),
              ])),
              AnimatedBuilder(
                animation: widget.appState,
                builder: (_, __) => RiskBadge(level: widget.appState.riskLevel),
              ),
            ]),
          ),
        ),
        // Risk demo buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Row(children: [
            ...RiskLevel.values.map((r) {
              final isActive = widget.appState.riskLevel == r;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () { widget.appState.setRisk(r); if (r == RiskLevel.high) _escalCtrl.forward(); else _escalCtrl.reverse(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? ST.purple.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isActive ? ST.purple.withOpacity(0.35) : ST.textMuted.withOpacity(0.2)),
                    ),
                    child: Text(r.name, style: ST.body(10, weight: FontWeight.w600, color: isActive ? ST.purpleLight : ST.textMuted).copyWith(letterSpacing: 0.5)),
                  ),
                ),
              );
            }),
            Text('demo', style: ST.body(9, color: ST.textMuted).copyWith(fontStyle: FontStyle.italic)),
          ]),
        ),
        // Escalation panel
        AnimatedBuilder(
          animation: widget.appState,
          builder: (_, __) => SlideTransition(
            position: _escalSlide,
            child: widget.appState.escalationActive && widget.appState.riskLevel == RiskLevel.high
                ? _EscalationCard(appState: widget.appState, onDismiss: () { widget.appState.cancelEscalation(); _escalCtrl.reverse(); })
                : const SizedBox.shrink(),
          ),
        ),
        // Messages
        Expanded(child: ListView.builder(
          controller: _scrollCtrl,
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          itemCount: _messages.length + (_isAnalyzing ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == _messages.length) return const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(top: 8), child: _TypingIndicator()));
            final msg = _messages[i];
            return _ChatBubble(message: msg);
          },
        )),
        // Suggestions
        if (_showPrompts)
          _SuggestedPrompts(prompts: _prompts, onSelect: _sendMessage),
        // Input bar
        _ChatInputBar(
          controller: _textCtrl,
          isRecording: _isRecording,
          locationOn: widget.appState.locationSharing,
          showingPrompts: _showPrompts,
          onSend: () => _sendMessage(_textCtrl.text),
          onRecord: () => setState(() => _isRecording = !_isRecording),
          onToggleLocation: () => widget.appState.toggleLocation(),
          onTogglePrompts: () => setState(() => _showPrompts = !_showPrompts),
        ),
      ]),
    );
  }
}

class _EscalationCard extends StatelessWidget {
  final AppState appState;
  final VoidCallback onDismiss;
  const _EscalationCard({required this.appState, required this.onDismiss});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appState,
    builder: (_, __) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ST.pink.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ST.pink.withOpacity(0.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Support Ready', style: ST.body(11, weight: FontWeight.w700, color: ST.pink).copyWith(letterSpacing: 0.8)),
              const SizedBox(height: 3),
              Text('Emergency contact will be notified in ${appState.escalationCountdown}s', style: ST.body(12, color: ST.textSecondary)),
            ]),
            GestureDetector(onTap: onDismiss, child: const Icon(Icons.close, size: 16, color: ST.textMuted)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: GhostButton(label: 'Cancel', onTap: onDismiss, height: 38, fontSize: 12)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: GradientButton(label: 'Notify Now', onTap: () {}, height: 38, fontSize: 12)),
          ]),
        ]),
      ),
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Column(
      crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (message.isUser)
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: ST.gradBubbleUser,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4)),
              boxShadow: [BoxShadow(color: ST.purple.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Text(message.text, style: ST.body(14).copyWith(height: 1.5)),
          )
        else
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: ST.surface,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
              border: Border.all(color: ST.border, width: 1),
            ),
            child: Text(message.text, style: ST.body(14, color: ST.textPrimary).copyWith(height: 1.5)),
          ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(message.time, style: ST.body(10, color: ST.textMuted)),
        ),
      ],
    ),
  );
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;
  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true));
    _anims = List.generate(3, (i) { Future.delayed(Duration(milliseconds: i * 180), () { if (mounted) _ctrls[i].repeat(reverse: true); }); return Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrls[i], curve: Curves.easeInOut)); });
  }
  @override
  void dispose() { for (final c in _ctrls) c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: ST.surface, borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)), border: Border.all(color: ST.border)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      ...List.generate(3, (i) => Padding(
        padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
        child: AnimatedBuilder(animation: _anims[i], builder: (_, __) => Opacity(opacity: _anims[i].value, child: Transform.translate(offset: Offset(0, (_anims[i].value - 0.7) * -4), child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: ST.purple, shape: BoxShape.circle))))),
      )),
      const SizedBox(width: 8),
      Text('Analyzing situation', style: ST.body(13, color: ST.textMuted)),
    ]),
  );
}

class _SuggestedPrompts extends StatelessWidget {
  final List<String> prompts;
  final ValueChanged<String> onSelect;
  const _SuggestedPrompts({required this.prompts, required this.onSelect});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Column(children: prompts.map((p) => GestureDetector(
      onTap: () => onSelect(p),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: ST.purple.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ST.purple.withOpacity(0.15)),
        ),
        child: Text(p, style: ST.body(13, color: ST.textSecondary)),
      ),
    )).toList()),
  );
}

class _ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isRecording, locationOn, showingPrompts;
  final VoidCallback onSend, onRecord, onToggleLocation, onTogglePrompts;
  const _ChatInputBar({required this.controller, required this.isRecording, required this.locationOn, required this.showingPrompts, required this.onSend, required this.onRecord, required this.onToggleLocation, required this.onTogglePrompts});
  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> with SingleTickerProviderStateMixin {
  late AnimationController _waveCtrl;
  bool _hasText = false;
  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    widget.controller.addListener(() => setState(() => _hasText = widget.controller.text.isNotEmpty));
  }
  @override
  void dispose() { _waveCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(14, 6, 14, bottomPad > 0 ? bottomPad + 8 : 16),
      child: Column(children: [
        // Tool row
        Row(children: [
          _PillButton(
            label: widget.locationOn ? 'Sharing' : 'Share location',
            icon: Icons.location_on_outlined,
            active: widget.locationOn,
            activeColor: ST.teal,
            onTap: widget.onToggleLocation,
          ),
          const SizedBox(width: 8),
          _PillButton(label: 'Suggestions', icon: Icons.auto_awesome_outlined, active: widget.showingPrompts, onTap: widget.onTogglePrompts),
        ]),
        const SizedBox(height: 8),
        // Input row
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          // Voice
          GestureDetector(
            onTap: widget.onRecord,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: widget.isRecording ? ST.gradPrimary : null,
                color: widget.isRecording ? null : ST.surface,
                borderRadius: BorderRadius.circular(14),
                border: widget.isRecording ? null : Border.all(color: ST.border),
                boxShadow: widget.isRecording ? [BoxShadow(color: ST.purple.withOpacity(0.4), blurRadius: 16)] : null,
              ),
              child: widget.isRecording
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => _WaveBar(ctrl: _waveCtrl, delay: i * 0.15)))
                  : const Icon(Icons.mic_outlined, size: 20, color: ST.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(
            constraints: const BoxConstraints(maxHeight: 100),
            decoration: BoxDecoration(
              color: ST.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: ST.border),
            ),
            child: TextField(
              controller: widget.controller,
              maxLines: null,
              style: ST.body(14),
              decoration: InputDecoration(
                hintText: 'Say anything…',
                hintStyle: ST.body(14, color: ST.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              ),
            ),
          )),
          const SizedBox(width: 8),
          // Send
          GestureDetector(
            onTap: _hasText ? widget.onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: _hasText ? ST.gradPrimary : null,
                color: _hasText ? null : ST.surface,
                borderRadius: BorderRadius.circular(14),
                border: _hasText ? null : Border.all(color: ST.border),
                boxShadow: _hasText ? [BoxShadow(color: ST.purple.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 4))] : null,
              ),
              child: Icon(Icons.send_rounded, size: 18, color: _hasText ? Colors.white : ST.textMuted),
            ),
          ),
        ]),   // closes input Row
      ]),   // closes Column children
    );      // closes Container
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.icon, required this.active, this.activeColor = ST.purple, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? Color.fromRGBO(activeColor.red, activeColor.green, activeColor.blue, 0.1) : ST.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? Color.fromRGBO(activeColor.red, activeColor.green, activeColor.blue, 0.3) : ST.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: active ? activeColor : ST.textMuted),
        const SizedBox(width: 4),
        Text(label, style: ST.body(11, weight: FontWeight.w500, color: active ? activeColor : ST.textMuted)),
      ]),
    ),
  );
}

class _WaveBar extends StatelessWidget {
  final AnimationController ctrl;
  final double delay;
  const _WaveBar({required this.ctrl, required this.delay});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ctrl,
    builder: (_, __) {
      final val = (math.sin((ctrl.value + delay) * math.pi * 2) + 1) / 2;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        width: 3,
        height: 6 + val * 14,
        decoration: BoxDecoration(
          gradient: ST.gradPrimary,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    },
  );
}

// ─── SCREEN 6: LOCATION ASSISTANCE ───────────────────────────────────────────────

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});
  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _filter = 'all';
  int? _selected;

  final _places = const [
    _Place(id: 1, type: 'police', name: 'Central Police Station', dist: '0.4 km', eta: '6 min'),
    _Place(id: 2, type: 'hospital', name: 'City General Hospital', dist: '0.9 km', eta: '12 min'),
    _Place(id: 3, type: 'shelter', name: "SafeHaven Women's Shelter", dist: '1.2 km', eta: '15 min'),
    _Place(id: 4, type: 'hospital', name: 'Sunrise Clinic (24hr)', dist: '2.1 km', eta: '20 min'),
    _Place(id: 5, type: 'shelter', name: 'Hope House NGO', dist: '2.8 km', eta: '28 min'),
  ];

  Color _typeColor(String t) => switch (t) { 'police' => ST.purple, 'hospital' => ST.teal, _ => ST.pink };
  String _typeEmoji(String t) => switch (t) { 'police' => '🛡', 'hospital' => '🏥', _ => '🏠' };

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'all' ? _places : _places.where((p) => p.type == _filter).toList();
    return Scaffold(
      backgroundColor: ST.bg,
      body: Column(children: [
        const STStatusBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(children: [
            const Icon(Icons.location_on_outlined, size: 20, color: ST.purple),
            const SizedBox(width: 8),
            Text('Nearby Safety', style: ST.display(20, weight: FontWeight.w700)),
          ]),
        ),
        // Simulated map
        _SimulatedMap(),
        // Filter chips
        SizedBox(height: 52, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), children: ['all', 'police', 'hospital', 'shelter'].map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _filter == f ? ST.purple.withOpacity(0.2) : ST.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _filter == f ? ST.purple.withOpacity(0.4) : ST.border),
              ),
              child: Text(f[0].toUpperCase() + f.substring(1), style: ST.body(12, weight: FontWeight.w600, color: _filter == f ? ST.purpleLight : ST.textSecondary)),
            ),
          ),
        )).toList())),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final p = filtered[i];
            final isExpanded = _selected == p.id;
            final col = _typeColor(p.type);
            return GestureDetector(
              onTap: () => setState(() => _selected = isExpanded ? null : p.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ST.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isExpanded ? col.withOpacity(0.3) : ST.border),
                ),
                child: Column(children: [
                  Row(children: [
                    Container(width: 42, height: 42, decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: col.withOpacity(0.2))),
                        child: Center(child: Text(_typeEmoji(p.type), style: const TextStyle(fontSize: 20)))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: ST.body(14, weight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('${p.dist} · ${p.eta} walk', style: ST.body(12, color: ST.textMuted)),
                    ])),
                    AnimatedRotation(turns: isExpanded ? 0.25 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.chevron_right, color: ST.textMuted, size: 18)),
                  ]),
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: GradientButton(label: 'Navigate', onTap: () {}, height: 38, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(child: GhostButton(label: 'Call', onTap: () {}, height: 38, fontSize: 12)),
                    ]),
                  ],
                ]),
              ),
            );
          },
        )),
      ]),
    );
  }
}

class _Place {
  final int id;
  final String type, name, dist, eta;
  const _Place({required this.id, required this.type, required this.name, required this.dist, required this.eta});
}

class _SimulatedMap extends StatefulWidget {
  @override
  State<_SimulatedMap> createState() => _SimulatedMapState();
}

class _SimulatedMapState extends State<_SimulatedMap> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ripple;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); _ripple = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ST.purple.withOpacity(0.15)),
        gradient: LinearGradient(
          colors: [const Color(0xFF0A0F1E), const Color(0xFF111827), const Color(0xFF0A0F1E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          // Grid lines
          CustomPaint(painter: _GridPainter(), size: const Size(double.infinity, 180)),
          // Map pins
          ...[
            (left: 0.35, top: 0.35, emoji: '🛡', color: ST.purple),
            (left: 0.65, top: 0.60, emoji: '🏥', color: ST.teal),
            (left: 0.70, top: 0.28, emoji: '🏠', color: ST.pink),
          ].map((pin) => Positioned(
            left: MediaQuery.of(context).size.width * pin.left - 60,
            top: 180 * pin.top,
            child: Container(width: 30, height: 30, decoration: BoxDecoration(color: pin.color.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: pin.color.withOpacity(0.4))), child: Center(child: Text(pin.emoji, style: const TextStyle(fontSize: 14)))),
          )),
          // User dot with ripple
          Positioned(left: MediaQuery.of(context).size.width * 0.5 - 77, top: 82, child: SizedBox(width: 40, height: 40, child: Stack(alignment: Alignment.center, children: [
            AnimatedBuilder(animation: _ripple, builder: (_, __) => Opacity(opacity: (1 - _ripple.value) * 0.5, child: Container(width: 14 + _ripple.value * 30, height: 14 + _ripple.value * 30, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ST.pink.withOpacity(0.6), width: 1.5))))),
            Container(width: 14, height: 14, decoration: const BoxDecoration(shape: BoxShape.circle, color: ST.pink, boxShadow: [BoxShadow(color: Color(0x99F472B6), blurRadius: 10)])),
          ]))),
          // Badges
          Positioned(bottom: 10, left: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: ST.bg.withOpacity(0.8), borderRadius: BorderRadius.circular(8), border: Border.all(color: ST.border)), child: Text('📍 Current location', style: ST.body(10, color: ST.textSecondary)))),
          Positioned(bottom: 10, right: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: ST.bg.withOpacity(0.8), borderRadius: BorderRadius.circular(8), border: Border.all(color: ST.teal.withOpacity(0.3))), child: Text('Safe route active', style: ST.body(10, color: ST.teal)))),
        ]),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = ST.purple.withOpacity(0.04)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─── SCREEN 7: HELPLINE DIRECTORY ─────────────────────────────────────────────────

class HelplineScreen extends StatefulWidget {
  const HelplineScreen({super.key});
  @override
  State<HelplineScreen> createState() => _HelplineScreenState();
}

class _HelplineScreenState extends State<HelplineScreen> {
  String _filter = 'all';

  final _helplines = const [
    _Helpline(id: 1, cat: 'gbv', name: 'Gender Violence Helpline', desc: '24/7 crisis support', number: '0800 150 150', color: ST.pink),
    _Helpline(id: 2, cat: 'mental', name: 'SADAG Mental Health Line', desc: 'Counselling & support', number: '0800 456 789', color: ST.purple),
    _Helpline(id: 3, cat: 'legal', name: 'Legal Aid South Africa', desc: 'Free legal advice', number: '0800 110 110', color: ST.teal),
    _Helpline(id: 4, cat: 'shelter', name: "Women's Shelter Network", desc: 'Emergency accommodation', number: '0800 200 200', color: ST.amber),
    _Helpline(id: 5, cat: 'gbv', name: 'Rape Crisis Support', desc: 'Trauma counselling', number: '021 447 9762', color: ST.pink),
    _Helpline(id: 6, cat: 'mental', name: 'Lifeline Counselling', desc: 'Emotional support 24/7', number: '011 728 1347', color: ST.purple),
  ];

  final _cats = const {'all': 'All', 'gbv': 'GBV', 'mental': 'Mental Health', 'legal': 'Legal Aid', 'shelter': 'Shelters'};

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'all' ? _helplines : _helplines.where((h) => h.cat == _filter).toList();
    return Scaffold(
      backgroundColor: ST.bg,
      body: Column(children: [
        const STStatusBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(children: [
            const Icon(Icons.favorite_outline, size: 20, color: ST.pink),
            const SizedBox(width: 8),
            Text('Support Lines', style: ST.display(20, weight: FontWeight.w700)),
          ]),
        ),
        SizedBox(height: 46, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 0, 16, 0), children: _cats.entries.map((e) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _filter = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _filter == e.key ? ST.pink.withOpacity(0.14) : ST.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _filter == e.key ? ST.pink.withOpacity(0.3) : ST.border),
              ),
              child: Text(e.value, style: ST.body(12, weight: FontWeight.w600, color: _filter == e.key ? ST.pink : ST.textSecondary)),
            ),
          ),
        )).toList())),
        const SizedBox(height: 8),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final h = filtered[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ST.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ST.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(shape: BoxShape.circle, color: h.color, boxShadow: [BoxShadow(color: h.color.withOpacity(0.5), blurRadius: 6)])),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(h.name, style: ST.body(14, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(h.desc, style: ST.body(12, color: ST.textMuted)),
                    const SizedBox(height: 2),
                    Text(h.number, style: ST.body(12, color: h.color, weight: FontWeight.w500)),
                  ])),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _ActionButton(label: 'Call', icon: Icons.phone_outlined, primary: true, color: h.color, onTap: () {})),
                  const SizedBox(width: 6),
                  Expanded(child: _ActionButton(label: 'SMS', icon: Icons.sms_outlined, primary: false, color: h.color, onTap: () {})),
                  const SizedBox(width: 6),
                  Expanded(child: _ActionButton(label: 'WhatsApp', icon: Icons.chat_outlined, primary: false, color: h.color, onTap: () {})),
                ]),
              ]),
            );
          },
        )),
      ]),
    );
  }
}

class _Helpline {
  final int id;
  final String cat, name, desc, number;
  final Color color;
  const _Helpline({required this.id, required this.cat, required this.name, required this.desc, required this.number, required this.color});
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.primary, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 34,
      decoration: BoxDecoration(
        color: primary ? color.withOpacity(0.14) : ST.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary ? color.withOpacity(0.28) : ST.border),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 12, color: primary ? color : ST.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: ST.body(11, weight: FontWeight.w600, color: primary ? color : ST.textSecondary)),
      ]),
    ),
  );
}

// ─── SCREEN 8: NGO DASHBOARD ───────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _selected;

  final _incidents = const [
    _Incident(id: 'USR-8821', risk: 'high', location: 'Soweto, GP', time: '2 min ago', status: 'active', note: 'User reports feeling unsafe at home'),
    _Incident(id: 'USR-4492', risk: 'medium', location: 'Sandton, GP', time: '8 min ago', status: 'monitoring', note: 'Repeated contact, elevated language'),
    _Incident(id: 'USR-1103', risk: 'low', location: 'Cape Town, WC', time: '22 min ago', status: 'resolved', note: 'Requested helpline information'),
    _Incident(id: 'USR-7743', risk: 'high', location: 'Durban, KZN', time: '35 min ago', status: 'active', note: 'Silent trigger activated'),
    _Incident(id: 'USR-2291', risk: 'medium', location: 'Pretoria, GP', time: '1 hr ago', status: 'monitoring', note: 'Shared location, awaiting response'),
  ];

  Color _riskColor(String r) => switch (r) { 'high' => ST.pink, 'medium' => ST.amber, _ => ST.teal };
  Color _statusColor(String s) => switch (s) { 'active' => ST.pink, 'monitoring' => ST.amber, _ => ST.teal };
  String _statusLabel(String s) => switch (s) { 'active' => 'Active', 'monitoring' => 'Monitoring', _ => 'Resolved' };
  String _riskLabel(String r) => switch (r) { 'high' => 'High', 'medium' => 'Medium', _ => 'Low' };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ST.bg,
      body: Column(children: [
        const STStatusBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NGO Dashboard', style: ST.display(18, weight: FontWeight.w700)),
              Text('Incident management · Secure', style: ST.body(11, color: ST.textMuted)),
            ])),
            Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: ST.pink, boxShadow: [BoxShadow(color: Color(0x99F472B6), blurRadius: 8)])),
              const SizedBox(width: 6),
              Text('2 urgent', style: ST.body(11, color: ST.textMuted)),
            ]),
          ]),
        ),
        // Stats row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            _StatCard(label: 'Active Cases', value: '14', color: ST.pink),
            const SizedBox(width: 8),
            _StatCard(label: 'Today', value: '38', color: ST.purple),
            const SizedBox(width: 8),
            _StatCard(label: 'Resolved', value: '91%', color: ST.teal),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
          child: Align(alignment: Alignment.centerLeft, child: Text('LIVE INCIDENT FEED', style: ST.body(11, weight: FontWeight.w600, color: ST.textMuted).copyWith(letterSpacing: 0.8))),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: _incidents.length,
          itemBuilder: (ctx, i) {
            final inc = _incidents[i];
            final isExpanded = _selected == i;
            final rc = _riskColor(inc.risk);
            final sc = _statusColor(inc.status);
            return GestureDetector(
              onTap: () => setState(() => _selected = isExpanded ? null : i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ST.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: rc, width: 3), top: BorderSide(color: isExpanded ? rc.withOpacity(0.2) : ST.border), right: BorderSide(color: isExpanded ? rc.withOpacity(0.2) : ST.border), bottom: BorderSide(color: isExpanded ? rc.withOpacity(0.2) : ST.border)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(inc.id, style: ST.display(13, weight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: rc.withOpacity(0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: rc.withOpacity(0.25))),
                        child: Text(_riskLabel(inc.risk), style: ST.body(10, weight: FontWeight.w700, color: rc).copyWith(letterSpacing: 0.5))),
                    const Spacer(),
                    Text(inc.time, style: ST.body(11, color: ST.textMuted)),
                  ]),
                  const SizedBox(height: 6),
                  Text('📍 ${inc.location}', style: ST.body(12, color: ST.textSecondary)),
                  const SizedBox(height: 6),
                  if (!isExpanded)
                    Row(children: [
                      Expanded(child: Text(inc.note.length > 38 ? '${inc.note.substring(0, 38)}…' : inc.note, style: ST.body(11, color: ST.textMuted).copyWith(fontStyle: FontStyle.italic))),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                          child: Text(_statusLabel(inc.status), style: ST.body(10, weight: FontWeight.w600, color: sc))),
                    ])
                  else ...[
                    Text(inc.note, style: ST.body(12, color: ST.textSecondary).copyWith(height: 1.5)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(flex: 2, child: GradientButton(label: 'Respond', onTap: () {}, height: 38, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(child: GhostButton(label: 'Close', onTap: () => setState(() => _selected = null), height: 38, fontSize: 12)),
                    ]),
                  ],
                ]),
              ),
            );
          },
        )),
      ]),
    );
  }
}

class _Incident {
  final String id, risk, location, time, status, note;
  const _Incident({required this.id, required this.risk, required this.location, required this.time, required this.status, required this.note});
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: ST.glass(radius: 14),
    child: Column(children: [
      Text(value, style: ST.display(22, weight: FontWeight.w800, color: color)),
      const SizedBox(height: 3),
      Text(label, style: ST.body(10, color: ST.textMuted), textAlign: TextAlign.center),
    ]),
  ));
}