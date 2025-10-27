import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PlutterApp());
}

class PlutterApp extends StatelessWidget {
  const PlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF6F61),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plutter Auth',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: baseScheme,
        scaffoldBackgroundColor: const Color(0xFFFFF8F6),
        textTheme: GoogleFonts.poppinsTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: baseScheme.primary, width: 1.6),
          ),
        ),
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isSubmitting = false;
  late final AnimationController _hueController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _hueController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    FocusScope.of(context).unfocus();

    final formKey = _isLogin ? _loginFormKey : _registerFormKey;
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isLogin) {
        final token = await AuthService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Signed in successfully. Token: $token')),
        );
      } else {
        await AuthService.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Account created! Please sign in.')),
        );
        setState(() {
          _isLogin = true;
          _hueController.forward(from: 0);
        });
      }
    } on AuthException catch (error) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Something went wrong: $error')),
      );
    } finally {
      if (navigator.mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _hueController.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _hueController,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _AnimatedBackdrop(hue: _isLogin ? 0 : 0.6, progress: _hueController.value),
              child!,
            ],
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Card(
                  elevation: 0,
                  color: Colors.white.withOpacity(0.88),
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    padding: EdgeInsets.symmetric(
                      vertical: isWide ? 48 : 32,
                      horizontal: isWide ? 64 : 28,
                    ),
                    child: isWide
                        ? Row(
                            children: [
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 600),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(opacity: animation, child: child),
                                  child: _IllustrationPanel(
                                    key: ValueKey(_isLogin),
                                    isLogin: _isLogin,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 56),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, formConstraints) {
                                    return SingleChildScrollView(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: formConstraints.maxHeight,
                                        ),
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: _AuthForm(
                                            isLogin: _isLogin,
                                            loginFormKey: _loginFormKey,
                                            registerFormKey: _registerFormKey,
                                            emailController: _emailController,
                                            passwordController: _passwordController,
                                            nameController: _nameController,
                                            confirmPasswordController: _confirmPasswordController,
                                            onSubmit: _submit,
                                            onToggle: _toggleMode,
                                            isSubmitting: _isSubmitting,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 600),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(opacity: animation, child: child),
                                  child: _IllustrationPanel(
                                    key: ValueKey(_isLogin),
                                    isLogin: _isLogin,
                                    compact: true,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _AuthForm(
                                  isLogin: _isLogin,
                                  loginFormKey: _loginFormKey,
                                  registerFormKey: _registerFormKey,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  nameController: _nameController,
                                  confirmPasswordController: _confirmPasswordController,
                                  onSubmit: _submit,
                                  onToggle: _toggleMode,
                                  isSubmitting: _isSubmitting,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedBackdrop extends StatelessWidget {
  const _AnimatedBackdrop({required this.hue, required this.progress});

  final double hue;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorTween = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFFFF4EF),
          end: HSVColor.fromAHSV(1, (hue * 360) % 360, 0.55, 1).toColor(),
        ),
        weight: 1,
      ),
    ]);

    final backgroundColor = colorTween.transform(progress) ?? const Color(0xFFFFF4EF);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor.withOpacity(0.9),
            const Color(0xFFFFD1C1),
            const Color(0xFFFFF8F6),
          ],
        ),
      ),
      child: Stack(
        children: [
          _GlowingOrb(
            alignment: Alignment.topRight,
            color: Colors.white.withOpacity(0.3),
            offset: const Offset(120, -40),
            size: 280 + 40 * progress,
          ),
          _GlowingOrb(
            alignment: Alignment.bottomLeft,
            color: const Color(0xFFFF8A80).withOpacity(0.35),
            offset: const Offset(-100, 140),
            size: 220 + 60 * progress,
          ),
          _GlowingOrb(
            alignment: Alignment.centerRight,
            color: const Color(0xFF7C4DFF).withOpacity(0.2),
            offset: const Offset(80, 40),
            size: 160 + 40 * (1 - progress),
          ),
        ],
      ),
    );
  }
}

class _GlowingOrb extends StatelessWidget {
  const _GlowingOrb({
    required this.alignment,
    required this.color,
    required this.offset,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final Offset offset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 120,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IllustrationPanel extends StatefulWidget {
  const _IllustrationPanel({
    super.key,
    required this.isLogin,
    this.compact = false,
  });

  final bool isLogin;
  final bool compact;

  @override
  State<_IllustrationPanel> createState() => _IllustrationPanelState();
}

class _HeroSlideData {
  const _HeroSlideData({
    required this.icon,
    required this.title,
    required this.caption,
  });

  final IconData icon;
  final String title;
  final String caption;
}

const List<_HeroSlideData> _loginSlides = [
  _HeroSlideData(
    icon: Icons.auto_graph_outlined,
    title: 'Track your progress',
    caption: 'Review insights from your recent activity at a glance.',
  ),
  _HeroSlideData(
    icon: Icons.bolt_outlined,
    title: 'Quick actions',
    caption: 'Jump right back into drafts, favourites, and saved sessions.',
  ),
  _HeroSlideData(
    icon: Icons.chat_bubble_outline,
    title: 'Real-time support',
    caption: 'Get assistance instantly with in-app messaging and tips.',
  ),
];

const List<_HeroSlideData> _registerSlides = [
  _HeroSlideData(
    icon: Icons.rocket_launch_outlined,
    title: 'Launch your journey',
    caption: 'Create an account to unlock personalised recommendations.',
  ),
  _HeroSlideData(
    icon: Icons.group_outlined,
    title: 'Join the community',
    caption: 'Collaborate with peers and share progress with your team.',
  ),
  _HeroSlideData(
    icon: Icons.lock_reset_outlined,
    title: 'Stay secure',
    caption: 'Your data is protected with multi-layer authentication.',
  ),
];

class _IllustrationPanelState extends State<_IllustrationPanel> {
  late final PageController _pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  List<_HeroSlideData> get _slides => widget.isLogin ? _loginSlides : _registerSlides;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant _IllustrationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLogin != widget.isLogin) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });
      }
      _restartTimer();
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_slides.length < 2) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      final nextIndex = (_currentIndex + 1) % _slides.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;
    final heroColor = widget.isLogin ? palette.primary : palette.tertiary;
    final title = widget.isLogin ? 'Welcome Back' : 'Create Account';
    final subtitle = widget.isLogin
        ? 'Access your personalised dashboard and stay on top of your goals.'
        : 'Join the community to save favourites, sync across devices, and more.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          widget.compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuad,
          height: widget.compact ? 220 : 280,
          decoration: BoxDecoration(
            color: heroColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _TopoPainter(color: heroColor.withOpacity(0.25)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _currentIndex = index;
                    });
                    _restartTimer();
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.compact ? 24 : 32,
                        vertical: widget.compact ? 24 : 32,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            slide.icon,
                            color: heroColor,
                            size: widget.compact ? 96 : 140,
                          ),
                          SizedBox(height: widget.compact ? 18 : 24),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            slide.caption,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 6,
                        width: widget.compact ? 24 : 32,
                        decoration: BoxDecoration(
                          color: heroColor.withOpacity(
                            index == _currentIndex ? 0.9 : 0.25,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: palette.primary,
            fontWeight: FontWeight.w700,
          ),
          textAlign: widget.compact ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: palette.onSurface.withOpacity(0.7),
          ),
          textAlign: widget.compact ? TextAlign.center : TextAlign.start,
        ),
      ],
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.isLogin,
    required this.loginFormKey,
    required this.registerFormKey,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.confirmPasswordController,
    required this.onSubmit,
    required this.onToggle,
    required this.isSubmitting,
  });

  final bool isLogin;
  final GlobalKey<FormState> loginFormKey;
  final GlobalKey<FormState> registerFormKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onToggle;
  final Future<void> Function() onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: isLogin ? loginFormKey : registerFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: isLogin
                ? const SizedBox.shrink()
                : Column(
                    key: const ValueKey('register-name-field'),
                    children: [
                      TextFormField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
          TextFormField(
            controller: emailController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address.';
              }
              final text = value.trim();
              if (!text.contains('@') || !text.contains('.')) {
                return 'Enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            textInputAction: isLogin ? TextInputAction.done : TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password.';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters long.';
              }
              return null;
            },
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: isLogin
                ? const SizedBox.shrink()
                : Column(
                    key: const ValueKey('register-confirm-field'),
                    children: [
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_person_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password.';
                          }
                          if (value != passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: isSubmitting ? null : onSubmit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(isLogin ? 'Sign in' : 'Create account'),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: isSubmitting ? null : onToggle,
              child: Text(
                isLogin
                    ? 'New here? Create an account'
                    : 'Already have an account? Sign in',
              ),
            ),
          ),
        ],
      ),
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      clipBehavior: Clip.none,
      child: form,
    );
  }
}

class _TopoPainter extends CustomPainter {
  _TopoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final wavePath = Path();
    const layerCount = 4;
    for (var i = 0; i < layerCount; i++) {
      final offset = i * 20.0;
      wavePath
        ..moveTo(0, size.height * 0.2 + offset)
        ..cubicTo(
          size.width * 0.25,
          size.height * 0.1 + offset,
          size.width * 0.4,
          size.height * 0.4 + offset,
          size.width * 0.65,
          size.height * 0.35 + offset,
        )
        ..cubicTo(
          size.width * 0.8,
          size.height * 0.3 + offset,
          size.width * 0.9,
          size.height * 0.6 + offset,
          size.width,
          size.height * 0.55 + offset,
        );
      canvas.drawPath(wavePath, paint..color = color.withOpacity(1 - (i * 0.18)));
      wavePath.reset();
    }
  }

  @override
  bool shouldRepaint(covariant _TopoPainter oldDelegate) => oldDelegate.color != color;
}

class ApiConfig {
  const ApiConfig._();

  static String get authBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/auth';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api/auth';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:8000/api/auth';
    }
  }
}

class AuthService {
  static String get baseUrl => ApiConfig.authBaseUrl;

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Future<String> login({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = _decodeResponse(response);
    if (response.statusCode == 200) {
      return data['token'] as String;
    }
    throw AuthException(message: data['detail']?.toString() ?? 'Unable to login');
  }

  static Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
      }),
    );

    final data = _decodeResponse(response);
    if (response.statusCode == 201) {
      return;
    }
    throw AuthException(message: data['detail']?.toString() ?? 'Unable to register');
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return {'detail': 'Unexpected server response (${response.statusCode})'};
    }
  }
}

class AuthException implements Exception {
  const AuthException({required this.message});

  final String message;

  @override
  String toString() => 'AuthException($message)';
}
