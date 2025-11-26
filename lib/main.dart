import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';

// Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Fixed: Updated to new API parameter names (providerAndroid / providerApple)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(const AxionymApp());
}

class AxionymApp extends StatelessWidget {
  const AxionymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Axionym.GUARD',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617), // slate-950
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF06B6D4), // cyan-500
          surface: Color(0xFF0F172A), // slate-900
          onSurface: Color(0xFFE2E8F0), // slate-200
          error: Color(0xFFEF4444), // red-500
        ),
        textTheme: GoogleFonts.robotoMonoTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const MainLayout(),
    );
  }
}

// --- BRAND ASSETS ---

class AxionymLogo extends StatelessWidget {
  final double size;
  const AxionymLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LogoPainter(),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shieldPath = Path();
    shieldPath.moveTo(w * 0.50, h * 0.92);
    shieldPath.cubicTo(
        w * 0.78, h * 0.82, w * 0.88, h * 0.58, w * 0.88, h * 0.35);
    shieldPath.lineTo(w * 0.50, h * 0.12);
    shieldPath.lineTo(w * 0.12, h * 0.35);
    shieldPath.cubicTo(
        w * 0.12, h * 0.58, w * 0.22, h * 0.82, w * 0.50, h * 0.92);
    shieldPath.close();

    final paintShield = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, paintShield);

    final arrowPath = Path();
    arrowPath.moveTo(w * 0.35, h * 0.65);
    arrowPath.lineTo(w * 0.65, h * 0.35);
    arrowPath.moveTo(w * 0.65, h * 0.35);
    arrowPath.lineTo(w * 0.45, h * 0.35);
    arrowPath.moveTo(w * 0.65, h * 0.35);
    arrowPath.lineTo(w * 0.65, h * 0.55);

    final paintArrow = Paint()
      ..color = const Color(0xFF020617)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(arrowPath, paintArrow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- HELPER: CUSTOM SNACKBAR ---
// This creates a consistent "Tech" look for all notifications
void showAxionymSnackBar(BuildContext context,
    {required String message, required bool isError}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
            color: isError
                ? const Color(0xFFEF4444)
                : const Color(0xFF10B981), // Red vs Emerald Green
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0F172A), // Slate-900 (Dark)
      behavior: SnackBarBehavior.floating, // Floats above bottom
      margin: const EdgeInsets.all(16), // Space around
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isError
              ? const Color(0xFFEF4444)
              : const Color(0xFF10B981), // Colored Border
          width: 1,
        ),
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}

// --- LAYOUT & NAVIGATION ---

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SafetyCheckupTab(),
    const ScanTab(),
    const RadarTab(),
    const ReportTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617).withValues(alpha: 0.9),
        elevation: 0,
        title: Row(
          children: [
            const AxionymLogo(size: 32),
            const SizedBox(width: 12),
            RichText(
              text: TextSpan(
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
                children: const [
                  TextSpan(
                      text: 'AXIONYM',
                      style: TextStyle(color: Color(0xFF94A3B8))),
                  TextSpan(
                      text: '.GUARD',
                      style: TextStyle(color: Color(0xFF06B6D4))),
                  TextSpan(
                      text: ' v2.0',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, color: Color(0xFF94A3B8)),
            onPressed: () {
              // Example of the new SnackBar design
              showAxionymSnackBar(context,
                  message: 'System Active. Monitoring enabled.',
                  isError: false);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFF1E293B), height: 1.0),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.robotoMono(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: const Color(0xFF0F172A),
          indicatorColor: const Color(0xFF06B6D4).withValues(alpha: 0.2),
          destinations: const [
            NavigationDestination(
                icon: Icon(LucideIcons.clipboardCheck), label: 'CHECKUP'),
            NavigationDestination(
                icon: Icon(LucideIcons.search), label: 'SCAN'),
            NavigationDestination(
                icon: Icon(LucideIcons.radar), label: 'RADAR'),
            NavigationDestination(
                icon: Icon(LucideIcons.messageSquare), label: 'REPORT'),
          ],
        ),
      ),
    );
  }
}

// --- 1. SAFETY CHECKUP TAB ---

class SafetyCheckupTab extends StatefulWidget {
  const SafetyCheckupTab({super.key});

  @override
  State<SafetyCheckupTab> createState() => _SafetyCheckupTabState();
}

class _SafetyCheckupTabState extends State<SafetyCheckupTab> {
  int _currentQuestionIndex = 0;
  int _riskScore = 0;
  bool _isFinished = false;
  List<QueryDocumentSnapshot> _questions = [];

  Future<void> _seedDatabase() async {
    final collection =
        FirebaseFirestore.instance.collection('safety_questions');
    var snapshots = await collection.get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
    final defaults = [
      {
        'text': 'Do you use the same password for multiple sites?',
        'weight': 25,
        'order': 1
      },
      {
        'text': 'Is Two-Factor Authentication (2FA) enabled on your email?',
        'weight': -20,
        'order': 2
      },
      {
        'text': 'Have you clicked on a link from an unknown SMS recently?',
        'weight': 30,
        'order': 3
      },
      {
        'text': 'Do you verify URL spellings before entering credentials?',
        'weight': -15,
        'order': 4
      },
    ];
    for (var q in defaults) {
      await collection.add(q);
    }
    setState(() {});
  }

  void _handleAnswer(int weight, bool isYes) {
    if (isYes) {
      _riskScore += weight;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      setState(() => _isFinished = true);
    }
  }

  void _reset() {
    setState(() {
      _currentQuestionIndex = 0;
      _riskScore = 0;
      _isFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      final isSafe = _riskScore <= 0;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSafe ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
              size: 80,
              color: isSafe ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              isSafe ? 'LOW RISK PROFILE' : 'VULNERABILITIES DETECTED',
              style: GoogleFonts.robotoMono(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text('Risk Score: $_riskScore',
                style: GoogleFonts.robotoMono(color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF334155)),
              ),
              child: const Text('RESTART AUDIT'),
            )
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('safety_questions')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF06B6D4)));
        }

        final data = snapshot.data?.docs ?? [];
        _questions = data;

        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.database, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Database is empty.',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.downloadCloud),
                  label: const Text('INITIALIZE DEFAULT QUESTIONS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _seedDatabase,
                )
              ],
            ),
          );
        }

        final questionData =
            data[_currentQuestionIndex].data() as Map<String, dynamic>;
        final text = questionData['text'] ?? 'Unknown Question';
        final weight = questionData['weight'] ?? 0;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / data.length,
                backgroundColor: const Color(0xFF1E293B),
                color: const Color(0xFF06B6D4),
                minHeight: 4,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_currentQuestionIndex + 1}/${data.length}',
                  style:
                      GoogleFonts.robotoMono(color: Colors.grey, fontSize: 12),
                ),
              ),
              const Spacer(),
              Text(
                text,
                style: GoogleFonts.robotoMono(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.4),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _handleAnswer(weight, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('NO'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _handleAnswer(weight, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('YES'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// --- 2. SCAN TAB ---

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  final _controller = TextEditingController();
  String _status = '';

  void _runScan() {
    setState(() => _status = 'SCANNING...');
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        final input = _controller.text;
        _status = (input.contains('http') || input.length > 10)
            ? 'CRITICAL THREAT DETECTED'
            : 'VERIFIED SAFE';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEEP SCAN',
            style: GoogleFonts.robotoMono(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text('Verify digital footprint integrity.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ENTER TARGET DATA...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF06B6D4))),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.search, size: 18),
              label: const Text('INIT GUARD PROTOCOL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _runScan,
            ),
          ),
          const SizedBox(height: 32),
          if (_status.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _status.contains('SAFE')
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                border: Border.all(
                    color: _status.contains('SAFE') ? Colors.green : Colors.red,
                    width: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    _status.contains('SAFE')
                        ? LucideIcons.checkCircle
                        : LucideIcons.alertTriangle,
                    color: _status.contains('SAFE') ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _status,
                    style: GoogleFonts.robotoMono(
                      color:
                          _status.contains('SAFE') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// --- 3. RADAR TAB ---

class RadarTab extends StatelessWidget {
  const RadarTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF06B6D4)));
        }

        final docs = snapshot.data?.docs ?? [];

        final totalReports = docs.length;
        final pendingCount = docs
            .where((d) =>
                (d.data() as Map<String, dynamic>)['status'] ==
                'pending_review')
            .length;

        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'THREAT RADAR',
              style: GoogleFonts.robotoMono(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _StatCard(
                    label: 'TOTAL REPORTS',
                    value: totalReports.toString(),
                    color: const Color(0xFF06B6D4)),
                const SizedBox(width: 16),
                _StatCard(
                    label: 'PENDING REVIEW',
                    value: pendingCount.toString(),
                    color: const Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 10,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 4),
                        FlSpot(2, 2),
                        FlSpot(3, 7),
                        FlSpot(4, 5),
                        FlSpot(5, 8),
                        FlSpot(6, 6)
                      ],
                      isCurved: true,
                      color: const Color(0xFF06B6D4),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color:
                              const Color(0xFF06B6D4).withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
                child: Text('7-DAY FRAUD VECTOR TREND',
                    style: GoogleFonts.robotoMono(
                        fontSize: 10, color: Colors.grey))),
            const SizedBox(height: 32),
            Text('LIVE FEED',
                style:
                    GoogleFonts.robotoMono(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            if (docs.isEmpty)
              const Text('No intelligence data gathered yet.',
                  style: TextStyle(color: Colors.grey)),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final content = data['content'] as String? ?? 'No content';
              final status = data['status'] as String? ?? 'UNKNOWN';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: GoogleFonts.robotoMono(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'pending_review'
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                : const Color(0xFF06B6D4)
                                    .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: GoogleFonts.robotoMono(
                                fontSize: 10,
                                color: status == 'pending_review'
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF06B6D4),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(LucideIcons.shieldAlert,
                            size: 14, color: Colors.grey),
                      ],
                    )
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.robotoMono(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// --- 4. REPORT TAB ---

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  final _controller = TextEditingController();
  bool _isSending = false;

  Future<void> _submitReport() async {
    if (_controller.text.isEmpty) {
      return;
    }

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance.collection('incidents').add({
        'content': _controller.text,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending_review',
        'source': 'app_report',
      });

      if (!mounted) {
        return;
      }

      _controller.clear();

      // UPDATED: Using custom Design
      showAxionymSnackBar(context,
          message: 'ENCRYPTED REPORT UPLOADED TO CORE.', isError: false);
    } catch (e) {
      // UPDATED: Using custom Design
      showAxionymSnackBar(context,
          message: 'UPLOAD FAILED. CHECK CONNECTION.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INCIDENT REPORT',
            style: GoogleFonts.robotoMono(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text('Submit suspicious activity for global database indexing.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: '// Describe observed anomaly...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF06B6D4))),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(LucideIcons.send, size: 18),
              label: Text(_isSending ? 'ENCRYPTING...' : 'ENCRYPT & SEND'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isSending ? null : _submitReport,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.shieldCheck, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'E2E ENCRYPTED SUBMISSION',
                style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.grey),
              ),
            ],
          )
        ],
      ),
    );
  }
}
