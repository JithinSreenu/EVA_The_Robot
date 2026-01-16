// ============================================================================
// IMPORTS SECTION
// ============================================================================
import 'ble_service.dart';
import 'quiz_questions.dart';
import 'dart:async';
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:confetti/confetti.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

bool bleReady = false;

final BleService bleService = BleService.instance;

// ============================================================================
// MAIN APPLICATION ENTRY POINT
// ============================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const EvaEyesApp());
}

Future<void> requestBlePermissions() async {
  await [
    Permission.location,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.microphone,
  ].request();
}

// ============================================================================
// ROOT APPLICATION WIDGET
// ============================================================================
class EvaEyesApp extends StatelessWidget {
  const EvaEyesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050507),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Roboto', color: Colors.white),
        ),
      ),
      home: const EvaScreen(),
    );
  }
}

// ============================================================================
// EVA EYES SCREEN
// ============================================================================
class EvaScreen extends StatefulWidget {
  const EvaScreen({super.key});

  @override
  State<EvaScreen> createState() => _EvaScreenState();
}

class _EvaScreenState extends State<EvaScreen> with TickerProviderStateMixin {
  late Ticker _ticker;
  final Offset _mousePos = Offset.zero;
  Offset _lookPos = Offset.zero;
  Offset _velocity = Offset.zero;
  double _blink = 1.0;
  double _blinkTgt = 0.0;
  double _glitch = 0;
  bool _booted = false;

  @override
  void initState() {
    super.initState();

    requestBlePermissions().then((_) async {
      await bleService.connect();
    });

    bleService.readyStream.listen((ready) {
      if (!mounted) return;
      setState(() {
        bleReady = ready;
      });
    });

    _ticker = createTicker(_onTick)..start();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _booted = true;
        _triggerBlink();
      });
    });
  }

  void _onTick(Duration elapsed) {
    const double k = 0.08;
    const double d = 0.82;
    
    double ax = (_mousePos.dx - _lookPos.dx) * k;
    double ay = (_mousePos.dy - _lookPos.dy) * k;
    
    _velocity = Offset((_velocity.dx + ax) * d, (_velocity.dy + ay) * d);
    _lookPos += _velocity;

    if (Random().nextDouble() < 0.008) _triggerBlink();
    
    _blink = _lerp(_blink, _blinkTgt, (_blinkTgt == 1) ? 0.25 : 0.12);
    
    if (_blink > 0.99 && _blinkTgt == 1) _blinkTgt = 0;

    _glitch *= 0.8;
    
    if (mounted) setState(() {});
  }

  double _lerp(double s, double e, double a) => s + (e - s) * a;
  
  void _triggerBlink() => _blinkTgt = 1.0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 10) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          }
        },
        child: Stack(
          children: [
            Center(
              child: AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: _booted ? 1.0 : 0.0,
                child: CustomPaint(
                  painter: EvaEyePainter(
                    lookPos: _lookPos,
                    blink: _blink,
                    glitch: _glitch,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WELCOME SCREEN
// ============================================================================
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _uiController;
  late Animation<double> _pulseAnimation;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    
    _speech = stt.SpeechToText();

    _uiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _uiController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _speech.stop(); 
    _uiController.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (!bleReady) return;
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
    );

    if (!available) return;

    setState(() => _isListening = true);

    _speech.listen(
      localeId: 'en_US',
      onResult: (result) {
        String spoken = result.recognizedWords.toLowerCase();
        debugPrint("Heard: $spoken");

        if (spoken.contains('hi') || spoken.contains('hello')) {
          bleService.sendCommand("SAY_HI");
        }

        if (spoken.contains('shake')) {
          bleService.sendCommand("SHAKE_HAND");
        }

        _speech.stop();
        setState(() => _isListening = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF0D1B2A), Color(0xFF050507)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 80),
                
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Text(
                    'QuizBot Challenge',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 55 : 36,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00D2FF),
                      shadows: [
                        Shadow(blurRadius: 20.0, color: const Color(0xFF00D2FF).withOpacity(0.8)),
                        const Shadow(blurRadius: 40.0, color: Colors.blueAccent),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 60),
                  child: Text(
                    'ഈ ചോദ്യങ്ങൾക്ക് ഉത്തരം നൽകി നിങ്ങളുടെ\nഅറിവ് തെളിയിക്കൂ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
                  ),
                ),
                
                Expanded(
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const QuizPage()),
                            ),
                            child: Container(
                              width: screenSize.width * 0.65,
                              height: 65,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00B4DB), Color(0xFF00D2FF)],
                                ),
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D2FF).withOpacity(0.6),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'START QUIZ',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00334E),
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 32,
                        bottom: 32,
                        child: RobotActionButton(
                          icon: Icons.waving_hand,
                          label: 'SAY HI',
                          onTap: () => bleService.sendCommand("SAY_HI"),
                        ),
                      ),

                      Positioned(
                        bottom: 32,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _toggleMic,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening ? Colors.redAccent : Colors.cyanAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.6),
                                    blurRadius: 20,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isListening ? Icons.mic_off : Icons.mic,
                                size: 34,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        right: 32,
                        bottom: 32,
                        child: RobotActionButton(
                          icon: Icons.handshake,
                          label: 'SHAKE HAND',
                          onTap: () => bleService.sendCommand("SHAKE_HAND"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ROBOT ACTION BUTTON
// ============================================================================
class RobotActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const RobotActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        height: 55,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF00B4DB), Color(0xFF00D2FF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D2FF).withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00334E),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// QUIZ PAGE
// ============================================================================
class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final FlutterTts _tts = FlutterTts();
  late ConfettiController _confettiController;
  
  bool _isTtsEnabled = true;
  double _shakeOffset = 0.0;
  
  late List<QuizQuestion> _questions;
  
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _revealed = false;
  double _timeLeft = 60.0;
  Timer? _timer;

  // ✅ CONVERT NUMBERS TO MALAYALAM
  String _convertNumbersToMalayalam(String text) {
    final Map<String, String> numberMap = {
      '0': 'പൂജ്യം', '1': 'ഒന്ന്', '2': 'രണ്ട്', '3': 'മൂന്ന്', '4': 'നാല്',
      '5': 'അഞ്ച്', '6': 'ആറ്', '7': 'ഏഴ്', '8': 'എട്ട്', '9': 'ഒമ്പത്',
      '10': 'പത്ത്', '11': 'പതിനൊന്ന്', '12': 'പന്ത്രണ്ട്', '13': 'പതിമൂന്ന്', '14': 'പതിനാല്',
      '15': 'പതിനഞ്ച്', '16': 'പതിനാറ്', '17': 'പതിനേഴ്', '18': 'പതിനെട്ട്', '19': 'പത്തൊമ്പത്',
      '20': 'ഇരുപത്', '26': 'ഇരുപത്തിയാറ്', '365': 'മുന്നൂറ്റി അറുപത്തിയഞ്ച്',
    };

    String result = text;
    numberMap.forEach((number, malayalam) {
      result = result.replaceAll(RegExp('^$number\\b'), malayalam);
      result = result.replaceAll(RegExp('^$number\$'), malayalam);
    });
    return result;
  }

  @override
  void initState() {
    super.initState();
    
    _questions = List.from(quizQuestions)..shuffle();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _startTimer();
    _speakCurrentQuestionAndOptions();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 60.0;
    
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft -= 0.1;
          } else {
            _timer?.cancel();
            _handleOption(-1);
          }
        });
      }
    });
  }

  Future<void> _speakCurrentQuestionAndOptions() async {
  if (!_isTtsEnabled) return;

  var q = _questions[_currentIndex];
  
  await _tts.setLanguage("ml-IN");
  await _tts.setPitch(1.3);

  Future<void> speakAndWait(String text) async {
    Completer completer = Completer();
    _tts.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
    });
    
    String processedText = _convertNumbersToMalayalam(text);
    
    // ✅ START FACE ANIMATION
    bleService.sendCommand("SPEAK_START");
    
    await _tts.speak(processedText);
    
    // ✅ STOP FACE ANIMATION
    bleService.sendCommand("SPEAK_STOP");
    
    return completer.future;
  }

  if (!_revealed && mounted && _isTtsEnabled) {
    await speakAndWait(q.question);
  }
  
  await Future.delayed(const Duration(milliseconds: 500));
  
  for (int i = 0; i < q.options.length; i++) {
    if (_revealed || !mounted || !_isTtsEnabled) break;
    
    String optionText = "ഓപ്ഷൻ ${i + 1} ${q.options[i]}";
    await speakAndWait(optionText);
    
    await Future.delayed(const Duration(milliseconds: 300));
  }
}



  /*Future<void> _speakCurrentQuestionAndOptions() async {
    if (!_isTtsEnabled) return;

    var q = _questions[_currentIndex];
    
    await _tts.setLanguage("ml-IN");
    await _tts.setPitch(1.3);

    Future<void> speakAndWait(String text) async {
      Completer completer = Completer();
      _tts.setCompletionHandler(() {
        if (!completer.isCompleted) completer.complete();
      });
      
      String processedText = _convertNumbersToMalayalam(text);
      await _tts.speak(processedText);
      return completer.future;
    }

    if (!_revealed && mounted && _isTtsEnabled) {
      await speakAndWait(q.question);
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    for (int i = 0; i < q.options.length; i++) {
      if (_revealed || !mounted || !_isTtsEnabled) break;
      
      String optionText = "ഓപ്ഷൻ ${i + 1} ${q.options[i]}";
      await speakAndWait(optionText);
      
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }*/

  void _handleOption(int index) {
    if (_revealed) return;
    
    _tts.stop();
    _timer?.cancel();
    
    setState(() {
      _selectedIndex = index;
      _revealed = true;
      
      if (index == _questions[_currentIndex].correctIndex) {
        bleService.sendCommand("CORRECT");
        _confettiController.play();
        _tts.setPitch(2.0);
        _tts.speak("ശരിയാണ്!");
      } else {
        _triggerShakeEffect();
        bleService.sendCommand("WRONG");
        _tts.setPitch(0.5);
        _tts.speak("തെറ്റാണ്");
        Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 200]);
      }
    });
  }

  void _triggerShakeEffect() {
    double count = 0;
    
    Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() {
        _shakeOffset = (count % 2 == 0) ? 10.0 : -10.0;
        count++;
      });
      
      if (count > 10) {
        t.cancel();
        setState(() => _shakeOffset = 0.0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var q = _questions[_currentIndex];
    bool isWrong = _revealed && _selectedIndex != q.correctIndex;

    return Scaffold(
      backgroundColor: isWrong ? const Color(0xFF2D0A0A) : const Color(0xFF050507),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isTtsEnabled ? Icons.volume_up : Icons.volume_off,
              color: Colors.cyanAccent
            ),
            onPressed: () => setState(() => _isTtsEnabled = !_isTtsEnabled),
          ),
        ],
      ),
      body: Transform.translate(
        offset: Offset(_shakeOffset, 0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.cyan, Colors.pink, Colors.yellow, Colors.blue],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90, height: 90,
                        child: CircularProgressIndicator(
                          value: _timeLeft / 60,
                          strokeWidth: 6,
                          color: _timeLeft < 10 ? Colors.red : Colors.cyanAccent,
                          backgroundColor: Colors.white10,
                        ),
                      ),
                      Text(
                        "${_timeLeft.toInt()}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Text(
                    q.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.4
                    )
                  ),
                  const SizedBox(height: 40),
                  ...List.generate(4, (i) {
                    Color borderCol = Colors.white12;
                    Color bgCol = Colors.white.withOpacity(0.05);
                    
                    if (_revealed) {
                      if (i == q.correctIndex) {
                        borderCol = Colors.greenAccent;
                        bgCol = Colors.green.withOpacity(0.2);
                      } else if (i == _selectedIndex) {
                        borderCol = Colors.redAccent;
                        bgCol = Colors.red.withOpacity(0.2);
                      }
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _handleOption(i),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: bgCol,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: borderCol, width: 2)
                          ),
                          child: Text(
                            q.options[i],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18)
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_revealed)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15
                          )
                        ),
                        onPressed: () {
                          if (_currentIndex < _questions.length - 1) {
                            setState(() {
                              _currentIndex++;
                              _revealed = false;
                              _selectedIndex = null;
                              _startTimer();
                              _speakCurrentQuestionAndOptions();
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("NEXT QUESTION"),
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER - EVA'S EYES
// ============================================================================
class EvaEyePainter extends CustomPainter {
  final Offset lookPos;
  final double blink;
  final double glitch;
  
  EvaEyePainter({
    required this.lookPos,
    required this.blink,
    required this.glitch
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawEye(canvas, size, -1);
    _drawEye(canvas, size, 1);
  }

  void _drawEye(Canvas canvas, Size size, int side) {
    double cx = size.width / 2 + (side * 140) + (lookPos.dx * 60);
    double cy = size.height / 2 + (lookPos.dy * 40);
    double dh = 150 * (1 - blink);
    
    if (blink > 0.95) return;
    
    Paint glow = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    
    Paint core = Paint()
      ..color = const Color(0xFF00E5FF);
    
    RRect eyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: 150,
        height: dh
      ),
      const Radius.circular(35)
    );
    
    canvas.drawRRect(eyeRect, glow);
    canvas.drawRRect(eyeRect, core);
  }

  @override
  bool shouldRepaint(oldDelegate) => true;
}
