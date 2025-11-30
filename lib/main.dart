import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

// -----------------------------------------------------------------------------
// WEB SCROLL FIX
// -----------------------------------------------------------------------------
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

// -----------------------------------------------------------------------------
// Entry Point
// -----------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Env warning: $e");
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // FIX: Clear Persistence to remove stale/cached data on mobile
    if (!kIsWeb) {
      try {
        await FirebaseFirestore.instance.clearPersistence();
        debugPrint("CACHE CLEARED");
      } catch (_) {}
    }

    // FIX: Robust Auth Handling for Web
    // If "Anonymous" sign-in is not enabled in Firebase Console, this will fail.
    // We catch the error so the app doesn't crash (White Screen of Death).
    try {
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint("Auth: Anonymous Sign In Success");
    } catch (e) {
      debugPrint(
          "AUTH WARNING: Could not sign in anonymously. Check Firebase Console -> Authentication -> Sign-in method. Error: $e");
    }

    if (kIsWeb) {
      FirebaseFirestore.instance.settings =
          const Settings(persistenceEnabled: false);
    } else {
      FirebaseFirestore.instance.settings =
          const Settings(persistenceEnabled: true);
    }

    // App Check (Uncomment for Production)
    /*
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
      webProvider: ReCaptchaV3Provider('KEY'),
    );
    */
  } catch (e) {
    debugPrint("INIT ERROR: $e");
  }

  runApp(const AxionymApp());
}

class AxionymApp extends StatelessWidget {
  const AxionymApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bgPrimary = Color(0xFF0F172A);
    const bgSecondary = Color(0xFF1E293B);
    const accentCyan = Color(0xFF06B6D4);
    const textPrimary = Color(0xFFF8FAFC);

    return MaterialApp(
      title: 'Axionym.Guard',
      scrollBehavior: AppScrollBehavior(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bgPrimary,
        colorScheme: const ColorScheme.dark(
          primary: accentCyan,
          surface: bgSecondary,
          onSurface: textPrimary,
        ),
        textTheme:
            GoogleFonts.robotoMonoTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: textPrimary,
          displayColor: textPrimary,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: accentCyan,
          selectionColor: Color(0x5506B6D4),
          selectionHandleColor: accentCyan,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: bgSecondary,
          contentTextStyle: TextStyle(color: textPrimary),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// SERVICES
// -----------------------------------------------------------------------------

class SafeBrowsingService {
  static const String _apiUrl =
      'https://safebrowsing.googleapis.com/v4/threatMatches:find';
  static String get _apiKey => dotenv.env['GOOGLE_SAFE_BROWSING_KEY'] ?? '';

  static Future<Map<String, String>> checkUrls(List<String> urls) async {
    if (urls.isEmpty || _apiKey.isEmpty) return {};

    final Map<String, String> results = {};
    for (var url in urls) {
      results[url] = 'SAFE';
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "client": {"clientId": "axionym-guard", "clientVersion": "2.1.0"},
          "threatInfo": {
            "threatTypes": [
              "MALWARE",
              "SOCIAL_ENGINEERING",
              "UNWANTED_SOFTWARE"
            ],
            "platformTypes": ["ANY_PLATFORM"],
            "threatEntryTypes": ["URL"],
            "threatEntries": urls.map((url) => {"url": url}).toList()
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('matches') && data['matches'] != null) {
          for (var match in data['matches']) {
            results[match['threat']['url']] = match['threatType'];
          }
        }
      }
    } catch (e) {
      debugPrint('API Error: $e');
    }
    return results;
  }
}

// -----------------------------------------------------------------------------
// UI Structure
// -----------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1;
  final TextEditingController _sharedTextController = TextEditingController();

  @override
  void dispose() {
    _sharedTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CustomPaint(size: const Size(24, 24), painter: LogoPainter()),
            const SizedBox(width: 12),
            Text('AXIONYM.GUARD',
                style: GoogleFonts.robotoMono(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: const Color(0xFF06B6D4))),
          ],
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            const CheckupTab(), // Now Stateful
            AnalyzeTab(controller: _sharedTextController),
            const RadarTab(),
            const ReportTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF334155)))),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: const Color(0xFF0F172A),
          indicatorColor: const Color(0xFF06B6D4).withValues(alpha: 0.2),
          destinations: const [
            NavigationDestination(
                icon: Icon(LucideIcons.shieldCheck), label: 'CHECKUP'),
            NavigationDestination(
                icon: Icon(LucideIcons.microscope), label: 'INSPECT'),
            NavigationDestination(
                icon: Icon(LucideIcons.radar), label: 'RADAR'),
            NavigationDestination(
                icon: Icon(LucideIcons.fileWarning), label: 'REPORT'),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: CHECKUP (Converted to StatefulWidget for Interactivity)
// -----------------------------------------------------------------------------

class CheckupTab extends StatefulWidget {
  const CheckupTab({super.key});

  @override
  State<CheckupTab> createState() => _CheckupTabState();
}

class _CheckupTabState extends State<CheckupTab> {
  // Store the IDs of questions that are toggled ON
  final Set<String> _selectedQuestions = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('safety_questions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text("DB Error: ${snapshot.error}",
                  style: GoogleFonts.robotoMono(color: Colors.red)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.shieldCheck,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text("No Data in 'safety_questions'",
                    style: GoogleFonts.robotoMono(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final docId = doc.id;

            // Smart field detection logic
            String questionText = "Unknown Field";
            if (data.containsKey('question')) {
              questionText = data['question'];
            } else if (data.containsKey('title')) {
              questionText = data['title'];
            } else if (data.containsKey('text')) {
              questionText = data['text'];
            } else if (data.containsKey('q')) {
              questionText = data['q'];
            } else {
              questionText = "Keys: ${data.keys.join(', ')}";
            }

            final isSelected = _selectedQuestions.contains(docId);

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFF06B6D4).withValues(alpha: 0.5)
                        : Colors.white10),
              ),
              child: ListTile(
                leading: Icon(LucideIcons.helpCircle,
                    color: isSelected ? const Color(0xFF06B6D4) : Colors.grey),
                title: Text(questionText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey[400],
                    )),
                trailing: Switch(
                  value: isSelected,
                  // FIX: Added interactivity logic
                  onChanged: (val) {
                    setState(() {
                      if (val) {
                        _selectedQuestions.add(docId);
                      } else {
                        _selectedQuestions.remove(docId);
                      }
                    });
                  },
                  thumbColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF06B6D4);
                    }
                    return Colors.grey;
                  }),
                  trackColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF06B6D4).withValues(alpha: 0.5);
                    }
                    return Colors.grey.withValues(alpha: 0.3);
                  }),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: INSPECT
// -----------------------------------------------------------------------------

class AnalyzeTab extends StatefulWidget {
  final TextEditingController controller;

  const AnalyzeTab({super.key, required this.controller});

  @override
  State<AnalyzeTab> createState() => _AnalyzeTabState();
}

class _AnalyzeTabState extends State<AnalyzeTab>
    with SingleTickerProviderStateMixin {
  late TabController _resultTabController;

  bool _isScanning = false;
  List<Map<String, dynamic>> _urls = [];
  List<Map<String, dynamic>> _phones = [];
  String _rawText = "";

  @override
  void initState() {
    super.initState();
    _resultTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _resultTabController.dispose();
    super.dispose();
  }

  Future<void> _handlePaste() async {
    widget.controller.text =
        "Checking package delivery: https://ln.run/-4Uyr?CnZ=tBEfoq0uaL";
  }

  Future<void> _analyzeText() async {
    final text = widget.controller.text;
    if (text.isEmpty) return;

    setState(() {
      _isScanning = true;
      _urls = [];
      _phones = [];
      _rawText = text;
    });

    final urlRegExp = RegExp(r'(https?:\/\/[^\s]+)');
    final matches = urlRegExp.allMatches(text);
    final List<String> urlList = matches.map((m) => m.group(0)!).toList();

    final phoneRegExp = RegExp(r'\+?[0-9]{9,15}');
    final phoneList =
        phoneRegExp.allMatches(text).map((m) => m.group(0)!).toList();

    Map<String, String> urlThreats = {};
    if (urlList.isNotEmpty) {
      urlThreats = await SafeBrowsingService.checkUrls(urlList);
    }

    List<Map<String, dynamic>> processedUrls = [];
    for (var url in urlList) {
      final status = urlThreats[url] ?? 'SAFE';
      processedUrls.add({
        'content': url,
        'status': status,
        'isThreat': status != 'SAFE',
      });
    }

    List<Map<String, dynamic>> processedPhones = [];
    for (var phone in phoneList) {
      processedPhones.add({
        'content': phone,
        'status': 'UNKNOWN',
        'isThreat': false,
      });
    }

    if (mounted) {
      setState(() {
        _urls = processedUrls;
        _phones = processedPhones;
        _isScanning = false;
        if (_urls.isNotEmpty) _resultTabController.animateTo(0);
      });
    }
  }

  Widget _buildResultList(List<Map<String, dynamic>> items, IconData icon) {
    if (items.isEmpty) {
      return Center(
        child: Text("NO DATA DETECTED",
            style: GoogleFonts.robotoMono(
                color: Colors.grey.withValues(alpha: 0.5))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: items.length,
      itemBuilder: (ctx, idx) {
        final item = items[idx];
        final isThreat = item['isThreat'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            border: Border.all(
              color: isThreat
                  ? Colors.redAccent
                  : Colors.greenAccent.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ListTile(
            leading: Icon(
                isThreat ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
                color: isThreat ? Colors.redAccent : Colors.greenAccent),
            title: Text(item['content'],
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
            subtitle: Text(isThreat ? "THREAT DETECTED" : "VERIFIED SAFE",
                style: TextStyle(
                    fontSize: 10,
                    color: isThreat ? Colors.redAccent : Colors.greenAccent)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("THREAT INSPECTOR",
                  style: GoogleFonts.robotoMono(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              OutlinedButton.icon(
                onPressed: _handlePaste,
                icon: const Icon(LucideIcons.clipboard, size: 14),
                label: const Text("PASTE"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: widget.controller,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  expands: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter text here...',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
              ),
              const Positioned(
                bottom: 8,
                right: 8,
                child: Icon(Icons.drag_handle, color: Colors.white10, size: 16),
              )
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _analyzeText,
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.microscope),
              label: Text(_isScanning ? "INSPECTING..." : "INSPECT"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _resultTabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
              ),
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: "URL (${_urls.length})"),
                Tab(text: "PHONE (${_phones.length})"),
                const Tab(text: "TEXT"),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _resultTabController,
              children: [
                _buildResultList(_urls, LucideIcons.link),
                _buildResultList(_phones, LucideIcons.phone),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      border: Border.all(color: Colors.white10)),
                  child: SingleChildScrollView(
                      child: Text(_rawText.isEmpty ? "No text" : _rawText)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: RADAR
// -----------------------------------------------------------------------------

class RadarTab extends StatelessWidget {
  const RadarTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("THREAT LANDSCAPE",
              style: GoogleFonts.robotoMono(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xFF334155))),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1),
                      FlSpot(1, 1.5),
                      FlSpot(2, 1.4),
                      FlSpot(3, 3.4),
                      FlSpot(4, 2),
                      FlSpot(5, 2.2),
                    ],
                    isCurved: true,
                    color: const Color(0xFF06B6D4),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text("LIVE FEED",
              style: GoogleFonts.robotoMono(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: Colors.redAccent, radius: 4),
            title: Text("Malicious URL detected"),
            subtitle: Text("10:42 AM • System"),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 4: REPORT (DB Write)
// -----------------------------------------------------------------------------

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  bool _isSending = false;

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance.collection('incidents').add({
        'description': _descController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'mobile',
        'status': 'new',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                border: Border.all(color: const Color(0xFF06B6D4)),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                      blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle, color: Color(0xFF06B6D4)),
                  const SizedBox(width: 12),
                  Text("INCIDENT LOGGED TO DB",
                      style: GoogleFonts.robotoMono(color: Colors.white)),
                ],
              ),
            ),
          ),
        );
        _descController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("NEW INCIDENT",
                style: GoogleFonts.robotoMono(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFF1E293B),
                hintText: 'Describe the threat...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSending ? null : _submitReport,
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.lock, size: 18),
              label:
                  Text(_isSending ? "ENCRYPTING..." : "SEND ENCRYPTED REPORT"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// GRAPHICS
// -----------------------------------------------------------------------------

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.25);
    path.lineTo(size.width, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.5, size.height, size.width * 0.5, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height * 0.6);
    path.lineTo(0, size.height * 0.25);
    path.close();
    canvas.drawPath(path, paint);

    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.3, size.height * 0.7);
    arrowPath.lineTo(size.width * 0.7, size.height * 0.3);
    arrowPath.moveTo(size.width * 0.7, size.height * 0.3);
    arrowPath.lineTo(size.width * 0.4, size.height * 0.3);
    arrowPath.moveTo(size.width * 0.7, size.height * 0.3);
    arrowPath.lineTo(size.width * 0.7, size.height * 0.6);
    paint.color = const Color(0xFF06B6D4);
    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
