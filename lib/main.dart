// ============================================================================
// IMPORTS SECTION
// ============================================================================
import 'ble_service.dart'; // BLE communication service
import 'dart:async'; // For Timer and async operations
import 'dart:math' as math; // Mathematical operations
import 'dart:math' show Random; // Random number generation for blink effects
import 'package:flutter/material.dart'; // Core Flutter widgets
import 'package:flutter/services.dart'; // System UI controls (fullscreen mode)
import 'package:flutter/scheduler.dart'; // Ticker for smooth animations
import 'package:flutter_tts/flutter_tts.dart'; // Text-to-Speech functionality
import 'package:vibration/vibration.dart'; // Device vibration for wrong answers
import 'package:confetti/confetti.dart'; // Confetti animation for correct answers
import 'package:permission_handler/permission_handler.dart';


final BleService bleService = BleService();

// ============================================================================
// MAIN APPLICATION ENTRY POINT
// ============================================================================
void main() {
  // Initialize Flutter binding before running the app
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable immersive fullscreen mode (hides status bar and navigation bar)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // Launch the application
  runApp(const EvaEyesApp());
}

Future<void> requestBlePermissions() async {
  await [
    Permission.location,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
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
      // Remove debug banner from top-right corner
      debugShowCheckedModeBanner: false,
      
      // Configure dark theme with custom background color
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050507), // Deep black background
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Roboto', color: Colors.white),
        ),
      ),
      
      // Set initial screen to Eva's animated eyes
      home: const EvaScreen(),
    );
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

/// Model class representing a single quiz question
/// Contains question text, multiple choice options, and the correct answer index
class QuizQuestion {
  final String question; // Question text in Malayalam
  final List<String> options; // Four answer options
  final int correctIndex; // Index of correct option (0-3)

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

// ============================================================================
// EVA EYES SCREEN - ANIMATED ROBOT EYES (SPLASH SCREEN)
// ============================================================================

/// Displays animated robot eyes that follow cursor/touch input
/// Swipe down to navigate to quiz welcome screen
class EvaScreen extends StatefulWidget {
  const EvaScreen({super.key});

  @override
  State<EvaScreen> createState() => _EvaScreenState();
}

class _EvaScreenState extends State<EvaScreen> with TickerProviderStateMixin {
  // Animation ticker for smooth 60fps eye movement
  late Ticker _ticker;
  
  // Position tracking variables
  Offset _mousePos = Offset.zero; // Target position (user touch/mouse)
  Offset _lookPos = Offset.zero; // Current eye position
  Offset _velocity = Offset.zero; // Movement velocity for smooth physics
  
  // Eye animation states
  double _blink = 1.0; // Current blink state (1 = open, 0 = closed)
  double _blinkTgt = 0.0; // Target blink state
  double _glitch = 0; // Glitch effect intensity
  bool _booted = false; // Boot animation completed flag

   
        @override
    void initState() {
      super.initState();

      requestBlePermissions().then((_) {
        bleService.connect();
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


    
  /*  // Start physics ticker for smooth eye movement
    _ticker = createTicker(_onTick)..start();
    
    // Trigger boot animation after 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _booted = true; // Show eyes with fade-in
          _triggerBlink(); // Initial blink
        });
      }
    });
  }*/

  /// Physics simulation for eye movement (called every frame)
  /// Uses spring physics for natural, smooth eye tracking
  void _onTick(Duration elapsed) {
    // Spring physics constants
    const double k = 0.08; // Spring stiffness
    const double d = 0.82; // Damping factor
    
    // Calculate spring force towards target position
    double ax = (_mousePos.dx - _lookPos.dx) * k;
    double ay = (_mousePos.dy - _lookPos.dy) * k;
    
    // Update velocity with acceleration and apply damping
    _velocity = Offset((_velocity.dx + ax) * d, (_velocity.dy + ay) * d);
    
    // Update eye position based on velocity
    _lookPos += _velocity;

    // Random automatic blinking (0.8% chance per frame)
    if (Random().nextDouble() < 0.008) _triggerBlink();
    
    // Smoothly interpolate blink animation
    // Faster closing (0.25) than opening (0.12) for realistic blink
    _blink = _lerp(_blink, _blinkTgt, (_blinkTgt == 1) ? 0.25 : 0.12);
    
    // Reset blink target when fully open
    if (_blink > 0.99 && _blinkTgt == 1) _blinkTgt = 0;

    // Decay glitch effect over time
    _glitch *= 0.8;
    
    // Update UI with new animation state
    if (mounted) setState(() {});
  }

  /// Linear interpolation helper function
  /// Smoothly transitions between start and end values
  double _lerp(double s, double e, double a) => s + (e - s) * a;
  
  /// Triggers a blink animation by setting target to closed (1.0)
  void _triggerBlink() => _blinkTgt = 1.0;

  @override
  void dispose() {
    _ticker.dispose(); // Clean up ticker to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // Detect downward swipe to navigate to welcome screen
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
              // Fade in eyes after boot animation
              child: AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: _booted ? 1.0 : 0.0,
                child: CustomPaint(
                  // Custom painter draws the animated eyes
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
// WELCOME SCREEN - QUIZ INTRODUCTION
// ============================================================================

/// Welcome screen with animated title and start button
/// Displays quiz branding and instructions in Malayalam
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  // Animation controller for pulsing effects
  late AnimationController _uiController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Create repeating pulse animation (1.5 seconds, reversing)
    _uiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Define pulse scale range (100% to 104%)
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _uiController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _uiController.dispose(); // Clean up animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600; // Detect tablet for responsive design

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Radial gradient background for depth effect
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF0D1B2A), Color(0xFF050507)],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    
                    // Animated title with pulsing effect
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Text(
                        'QuizBot Challenge',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 55 : 36, // Larger on tablets
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00D2FF),
                          // Glowing shadow effects
                          shadows: [
                            Shadow(blurRadius: 20.0, color: const Color(0xFF00D2FF).withOpacity(0.8)),
                            const Shadow(blurRadius: 40.0, color: Colors.blueAccent),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Instructions in Malayalam
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 60),
                      child: Text(
                        'ഈ ചോദ്യങ്ങൾക്ക് ഉത്തരം നൽകി നിങ്ങളുടെ\nഅറിവ് തെളിയിക്കൂ',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
                      ),
                    ),
                    
                    const Spacer(),

                    // 🤖 ROBOT CONTROL BUTTONS
                    RobotActionButton(
                      icon: Icons.waving_hand,
                      label: 'SAY HI',
                      onTap: () {
                        //debugPrint('SAY_HI command triggered'); // For debugging
                        bleService.sendCommand("SAY_HI");
                        // Future: send BLE command -> SAY_HI
                      },
                    ),

                    RobotActionButton(
                      icon: Icons.handshake,
                      label: 'SHAKE HAND',
                      onTap: () {
                       // debugPrint('SHAKE_HAND command triggered');// For debugging
                        bleService.sendCommand("SHAKE_HAND");
                        // Future: send BLE command -> SHAKE_HAND
                      },
                    ),

                    const SizedBox(height: 30),

                    
                    // Animated START button with glow effect
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const QuizPage())
                        ),
                        child: Container(
                          width: screenSize.width * 0.8,
                          height: 65,
                          decoration: BoxDecoration(
                            // Gradient button background
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00B4DB), Color(0xFF00D2FF)]
                            ),
                            borderRadius: BorderRadius.circular(40),
                            // Glowing shadow effect
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D2FF).withOpacity(0.6),
                                blurRadius: 30,
                                spreadRadius: 5
                              )
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'START QUIZ',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00334E),
                                letterSpacing: 2
                              )
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 120),
                  ],
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
// ROBOT ACTION BUTTON (Reusable)
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
// QUIZ PAGE - MAIN QUIZ FUNCTIONALITY
// ============================================================================

/// Main quiz screen with timer, TTS, and interactive questions
/// Features include: Malayalam TTS, confetti effects, vibration feedback, and shake animations
class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // ========== SERVICES ==========
  final FlutterTts _tts = FlutterTts(); // Text-to-Speech engine
  late ConfettiController _confettiController; // Confetti animation controller
  
  // ========== UI STATE ==========
  bool _isTtsEnabled = true; // TTS on/off toggle
  double _shakeOffset = 0.0; // Horizontal shake effect for wrong answers
  
  // ========== QUIZ DATA ==========
  final List<QuizQuestion> _questions = [
    QuizQuestion(
      question: "കേരളത്തിലെ ഏറ്റവും നീളം കൂടിയ നദി ഏതാണ്?",
      options: ["പെരിയാർ", "ഭാരതപ്പുഴ", "പമ്പ", "ചാലിയാർ"],
      correctIndex: 0
    ),
    QuizQuestion(
      question: "ഇന്ത്യയുടെ ആദ്യത്തെ പ്രധാനമന്ത്രി ആരാണ്?",
      options: ["ഗാന്ധിജി", "നെഹ്‌റു", "പട്ടേൽ", "അംബേദ്കർ"],
      correctIndex: 1
    ),
    QuizQuestion(
      question: "ലോകത്തിലെ ഏറ്റവും വലിയ സമുദ്രം ഏതാണ്?",
      options: ["അറ്റ്ലാന്റിക്", "പസഫിക്", "ഇന്ത്യൻ", "ആർട്ടിക്"],
      correctIndex: 1
    ),
    QuizQuestion(
      question: "മലയാള സിനിമയിലെ ആദ്യത്തെ ശബ്ദചിത്രം ഏത്?",
      options: ["വിഗതകുമാരൻ", "ബാലൻ", "നീലക്കുയിൽ", "മാർത്താണ്ഡവർമ്മ"],
      correctIndex: 1
    ),
  ];
  
  // ========== QUIZ STATE ==========
  int _currentIndex = 0; // Current question index
  int? _selectedIndex; // User's selected answer index
  bool _revealed = false; // Whether answer has been revealed
  double _timeLeft = 60.0; // Countdown timer in seconds
  Timer? _timer; // Timer object for countdown

  @override
  void initState() {
    super.initState();
    
    // Initialize confetti controller with 2-second burst duration
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // Randomize question order for variety
    _questions.shuffle();
    
    // Start countdown timer
    _startTimer();
    
    // Speak question and options in Malayalam
    _speakCurrentQuestionAndOptions();
  }

  /// Starts or restarts the 60-second countdown timer
  /// Timer updates every 100ms for smooth progress bar animation
  void _startTimer() {
    _timer?.cancel(); // Cancel existing timer if any
    _timeLeft = 60.0; // Reset to 60 seconds
    
    // Create repeating timer that ticks every 100ms
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft -= 0.1; // Decrease by 0.1 seconds
          } else {
            // Time's up - auto-submit with no selection
            _timer?.cancel();
            _handleOption(-1); // -1 indicates timeout
          }
        });
      }
    });
  }

  /// Speaks current question and all options using Malayalam TTS
  /// Uses sequential await to speak each item with pauses between
  Future<void> _speakCurrentQuestionAndOptions() async {
    if (!_isTtsEnabled) return; // Skip if TTS is disabled

    var q = _questions[_currentIndex];
    
    // Configure TTS for Malayalam
    await _tts.setLanguage("ml-IN");
    await _tts.setPitch(1.3); // Slightly higher pitch for clarity

    /// Helper function to speak text and wait for completion
    Future<void> speakAndWait(String text) async {
      Completer completer = Completer();
      // Set completion handler to resolve when speech finishes
      _tts.setCompletionHandler(() {
        if (!completer.isCompleted) completer.complete();
      });
      await _tts.speak(text);
      return completer.future; // Wait for speech to complete
    }

    // Speak question first
    if (!_revealed && mounted && _isTtsEnabled) {
      await speakAndWait(q.question);
    }
    
    // Brief pause between question and options
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Speak each option with "Option 1:", "Option 2:", etc.
    for (int i = 0; i < q.options.length; i++) {
      // Stop if answer revealed or TTS disabled mid-speech
      if (_revealed || !mounted || !_isTtsEnabled) break;
      
      String optionText = "ഓപ്ഷൻ ${i + 1}: ${q.options[i]}";
      await speakAndWait(optionText);
      
      // Short pause between options
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  /// Handles user's option selection or timeout
  /// index: selected option index (-1 for timeout)
  void _handleOption(int index) {
    if (_revealed) return; // Prevent multiple submissions
    
    _tts.stop(); // Stop any ongoing speech
    _timer?.cancel(); // Stop countdown timer
    
    setState(() {
      _selectedIndex = index;
      _revealed = true; // Show correct/wrong indicators
      
      // Check if answer is correct
      if (index == _questions[_currentIndex].correctIndex) {
        // ========== CORRECT ANSWER ==========
         bleService.sendCommand("CORRECT"); // Send BLE command for correct answer
        _confettiController.play(); // Trigger confetti burst
        
        // Happy voice confirmation (high pitch)
        _tts.setPitch(2.0);
        _tts.speak("ശരിയാണ്!"); // "Correct!" in Malayalam
        
      } else {
        // ========== WRONG ANSWER ==========
        _triggerShakeEffect(); // Shake screen horizontally
        
        bleService.sendCommand("WRONG"); // Send BLE command for wrong answer
        // Buzzer-like voice (low pitch)
        _tts.setPitch(0.5);
        _tts.speak("തെറ്റാണ്"); // "Wrong!" in Malayalam
        
        // Vibration pattern: pause, buzz, pause, buzz, pause, long buzz
        Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 200]);
      }
    });
  }

  /// Creates horizontal shake animation for wrong answers
  /// Oscillates screen left and right 10 times over 500ms
  void _triggerShakeEffect() {
    double count = 0;
    
    // Timer ticks every 50ms for 10 iterations
    Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() {
        // Alternate between +10px and -10px offset
        _shakeOffset = (count % 2 == 0) ? 10.0 : -10.0;
        count++;
      });
      
      // Stop after 10 shakes
      if (count > 10) {
        t.cancel();
        setState(() => _shakeOffset = 0.0); // Reset to center
      }
    });
  }

  @override
  void dispose() {
    // Clean up resources to prevent memory leaks
    _timer?.cancel();
    _tts.stop();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var q = _questions[_currentIndex]; // Current question data
    
    // Check if user selected wrong answer
    bool isWrong = _revealed && _selectedIndex != q.correctIndex;

    return Scaffold(
      // Change background to dark red on wrong answer
      backgroundColor: isWrong ? const Color(0xFF2D0A0A) : const Color(0xFF050507),
      
      // AppBar with TTS toggle button
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Volume icon toggles TTS on/off
          IconButton(
            icon: Icon(
              _isTtsEnabled ? Icons.volume_up : Icons.volume_off,
              color: Colors.cyanAccent
            ),
            onPressed: () => setState(() => _isTtsEnabled = !_isTtsEnabled),
          ),
        ],
      ),
      
      // Apply shake effect to entire body
      body: Transform.translate(
        offset: Offset(_shakeOffset, 0), // Horizontal shake only
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti overlay (invisible until triggered)
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive, // Explode in all directions
              colors: const [Colors.cyan, Colors.pink, Colors.yellow, Colors.blue],
            ),
            
            // Main quiz content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ========== COUNTDOWN TIMER ==========
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular progress indicator
                      SizedBox(
                        width: 90, height: 90,
                        child: CircularProgressIndicator(
                          value: _timeLeft / 60, // Progress from 1.0 to 0.0
                          strokeWidth: 6,
                          // Turn red when less than 10 seconds remain
                          color: _timeLeft < 10 ? Colors.red : Colors.cyanAccent,
                          backgroundColor: Colors.white10,
                        ),
                      ),
                      // Countdown number in center
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
                  
                  // ========== QUESTION TEXT ==========
                  Text(
                    q.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.4 // Line spacing
                    )
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // ========== ANSWER OPTIONS ==========
                  // Generate 4 option buttons
                  ...List.generate(4, (i) {
                    // Default styling (unanswered state)
                    Color borderCol = Colors.white12;
                    Color bgCol = Colors.white.withOpacity(0.05);
                    
                    // Update styling after answer revealed
                    if (_revealed) {
                      if (i == q.correctIndex) {
                        // Correct answer: green highlight
                        borderCol = Colors.greenAccent;
                        bgCol = Colors.green.withOpacity(0.2);
                      } else if (i == _selectedIndex) {
                        // User's wrong selection: red highlight
                        borderCol = Colors.redAccent;
                        bgCol = Colors.red.withOpacity(0.2);
                      }
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _handleOption(i), // Handle option selection
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
                  
                  // ========== NEXT BUTTON ==========
                  // Only visible after answer revealed
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
                          // Check if more questions remain
                          if (_currentIndex < _questions.length - 1) {
                            // Move to next question
                            setState(() {
                              _currentIndex++; // Increment question index
                              _revealed = false; // Hide answer indicators
                              _selectedIndex = null; // Clear selection
                              _startTimer(); // Restart 60-second timer
                              _speakCurrentQuestionAndOptions(); // Speak new question
                            });
                          } else {
                            // Quiz complete - return to previous screen
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
// CUSTOM PAINTER - EVA'S ANIMATED EYES
// ============================================================================

/// Custom painter that draws two animated robot eyes with glow effects
/// Eyes follow the lookPos and respond to blink animations
class EvaEyePainter extends CustomPainter {
  final Offset lookPos; // Eye tracking position
  final double blink; // Blink state (0 = closed, 1 = open)
  final double glitch; // Glitch effect intensity (currently unused)
  
  EvaEyePainter({
    required this.lookPos,
    required this.blink,
    required this.glitch
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw left eye (side = -1)
    _drawEye(canvas, size, -1);
    
    // Draw right eye (side = 1)
    _drawEye(canvas, size, 1);
  }

  /// Draws a single eye with glow effect
  /// side: -1 for left eye, 1 for right eye
  void _drawEye(Canvas canvas, Size size, int side) {
    // Calculate eye center position
    double cx = size.width / 2 // Screen center X
        + (side * 140) // Offset left/right by 140px
        + (lookPos.dx * 60); // Add tracking offset (scaled)
    
    double cy = size.height / 2 // Screen center Y
        + (lookPos.dy * 40); // Add tracking offset (scaled)
    
    // Calculate eye height based on blink state
    double dh = 150 * (1 - blink); // Height: 0 (closed) to 150 (open)
    
    // Don't draw if almost fully closed (optimization)
    if (blink > 0.95) return;
    
    // ========== PAINT STYLES ==========
    
    // Outer glow effect (cyan with blur)
    Paint glow = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    
    // Solid core color (bright cyan)
    Paint core = Paint()
      ..color = const Color(0xFF00E5FF);
    
    // Create rounded rectangle for eye shape
    RRect eyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: 150, // Fixed width
        height: dh // Variable height for blink
      ),
      const Radius.circular(35) // Rounded corners
    );
    
    // Draw glow layer first (behind)
    canvas.drawRRect(eyeRect, glow);
    
    // Draw solid core on top
    canvas.drawRRect(eyeRect, core);
  }

  @override
  bool shouldRepaint(oldDelegate) => true; // Always repaint for smooth animation
}
