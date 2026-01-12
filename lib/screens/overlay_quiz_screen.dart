import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OverlayQuizScreen extends StatefulWidget {
  const OverlayQuizScreen({super.key});

  @override
  State<OverlayQuizScreen> createState() => _OverlayQuizScreenState();
}

class _OverlayQuizScreenState extends State<OverlayQuizScreen> {
  bool _isLoading = true;
  bool _isSubmitted = false;
  bool _isCorrect = false;
  
  // Quiz flow state
  int _currentQuestionIndex = 1; // 1-based
  final int _totalQuestions = 3;

  Map<String, dynamic>? _questionData;
  String? _errorMessage;
  String? _selectedOption; // Menyimpan jawaban yang dipilih user sementara

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _isLoading = true;
      _isSubmitted = false;
      _isCorrect = false;
      _selectedOption = null;
      _errorMessage = null;
    });

    try {
      final dbHelper = DatabaseHelper();
      final question = await dbHelper.getRandomQuestion();

      setState(() {
        _questionData = question;
        _isLoading = false;
        if (question == null) {
          _errorMessage = 'No questions available.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _handleSubmit() async {
    if (_selectedOption == null || _questionData == null) return;

    final correctAnswer = _questionData!['correct_answer'] as String;
    final questionId = _questionData!['id'] as int;

    setState(() {
      _isSubmitted = true;
    });

    if (_selectedOption == correctAnswer) {
      // JAWABAN BENAR
      setState(() {
        _isCorrect = true;
      });

      // Tandai di database
      final dbHelper = DatabaseHelper();
      await dbHelper.markQuestionAsSolved(questionId);

      // Jika ini adalah soal terakhir, berikan reward dan tampilkan layar sukses
      if (_currentQuestionIndex >= _totalQuestions) {
        await _grantRewardTime();
        // biarkan state _isSubmitted && _isCorrect untuk menampilkan layar sukses
      } else {
        // Tampilkan feedback singkat lalu lanjut ke soal berikutnya
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        setState(() {
          _currentQuestionIndex += 1;
        });
        await _loadQuestion();
      }
    } else {
      // JAWABAN SALAH
      setState(() {
        _isCorrect = false;
      });

      // Delay sebentar lalu load pertanyaan baru untuk indeks yang sama (hukuman)
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _loadQuestion();
        }
      });
    }
  }

  Future<void> _grantRewardTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final packageName = prefs.getString('current_blocked_app');
      if (packageName != null && packageName.isNotEmpty) {
        final expiryTime = DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch; // Reward 10 menit
        await prefs.setInt('unlock_expiry_$packageName', expiryTime);
      }
    } catch (e) {
      debugPrint('Error granting reward: $e');
    }
  }

  void _closeOverlay() {
    FlutterOverlayWindow.closeOverlay();
  }

  List<String> _getOptions() {
    if (_questionData == null) return [];
    final options = <String>[];
    if (_questionData!['option_a'] != null) options.add(_questionData!['option_a']);
    if (_questionData!['option_b'] != null) options.add(_questionData!['option_b']);
    if (_questionData!['option_c'] != null) options.add(_questionData!['option_c']);
    if (_questionData!['option_d'] != null) options.add(_questionData!['option_d']);
    return options; // Di aplikasi nyata, sebaiknya di-shuffle jika perlu
  }

  @override
  Widget build(BuildContext context) {
    // Jika sudah submit dan benar, tampilkan layar Success (Hijau)
    if (_isSubmitted && _isCorrect) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        color: Colors.transparent,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: Colors.transparent,
        ),
        home: _buildSuccessScreen(),
      );
    }

    // Tampilan Quiz Utama (Merah/Putih) dalam kotak 3:4 yang tidak fullscreen
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.white,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                    : _errorMessage != null
                        ? Center(child: Text(_errorMessage!))
                        : Column(
                            children: [
                              _buildHeader(),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      _buildQuestionCard(),
                                      const SizedBox(height: 20),
                                      _buildOptionsList(),
                                      const SizedBox(height: 30),
                                    ],
                                  ),
                                ),
                              ),
                              _buildFooterButtons(),
                            ],
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS UI UTAMA ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30), // Top padding untuk status bar
      decoration: const BoxDecoration(
        color: Color(0xFFEF5350), // Warna Merah sesuai desain
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const Text(
            "Focus Interruption!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Answer this quiz to continue",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          // Progress Bar Dummy (dinamis)
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: _currentQuestionIndex / _totalQuestions,
                    backgroundColor: Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text("$_currentQuestionIndex/$_totalQuestions", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: const [
                Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                SizedBox(width: 5),
                Text("30s", style: TextStyle(color: Colors.white)),
              ]),
              Row(children: const [
                Icon(Icons.emoji_events_outlined, color: Colors.white, size: 20),
                SizedBox(width: 5),
                Text("Score: 0", style: TextStyle(color: Colors.white)),
              ]),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Biru Muda
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Question $_currentQuestionIndex",
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _questionData!['question'] ?? "",
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsList() {
    final options = _getOptions();
    final letters = ['A', 'B', 'C', 'D'];

    return Column(
      children: List.generate(options.length, (index) {
        final optionText = options[index];
        final letter = letters[index];
        final isSelected = _selectedOption == optionText;

        // Logic warna jika sudah submit (Salah = Merah, tapi di sini kita reset soal kalau salah)
        // Jadi kita hanya fokus ke state "Selected" saja.
        
        Color borderColor = Colors.grey.shade300;
        Color bgColor = Colors.white;
        Color letterBg = Colors.grey.shade200;
        Color letterColor = Colors.black87;

        if (isSelected) {
          borderColor = const Color(0xFF2196F3);
          bgColor = const Color(0xFFF5FAFF); // Biru sangat muda
          letterBg = Colors.black87; // Style baru: badge hitam saat selected? Atau biru?
          // Sesuai desain image: Badge jadi Hitam/Gelap, Text jadi tebal
        }

        if (_isSubmitted && !isSelected) {
           // Disable tampilan opsi lain jika perlu
           borderColor = Colors.grey.shade200;
        }
        
        // Tampilan Error pada opsi yang dipilih (sebelum refresh)
        if (_isSubmitted && !_isCorrect && isSelected) {
           borderColor = Colors.red;
           bgColor = Colors.red.shade50;
        }

        return GestureDetector(
          onTap: _isSubmitted ? null : () {
            setState(() {
              _selectedOption = optionText;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            child: Row(
              children: [
                // Badge Huruf (A, B, C, D)
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black87 : const Color(0xFFEEEEEE),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    optionText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFooterButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            flex: 4,
            child: ElevatedButton(
              onPressed: () {
                // Di real app, tombol cancel mungkin tidak boleh menutup overlay
                // Tapi untuk UX yang baik, mungkin meminimalkan atau keluar dari app yang diblokir
                FlutterOverlayWindow.closeOverlay(); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0E0E0),
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          // Submit Button
          Expanded(
            flex: 6,
            child: ElevatedButton(
              onPressed: _isSubmitted || _selectedOption == null ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4), // Google Blue
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Submit Answer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAMPILAN SUKSES (HIJAU) ---

  Widget _buildSuccessScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Header Hijau
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50), // Hijau Sukses
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                      ),
                      width: double.infinity,
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.white, size: 60),
                          const SizedBox(height: 10),
                          const Text(
                            "Correct!",
                            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Great job! Keep it up!",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          // Progress Full
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: const LinearProgressIndicator(
                              value: 1.0,
                              backgroundColor: Colors.black12,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/success_badge.png', // Pastikan punya placeholder atau ganti Icon
                              height: 150,
                              errorBuilder: (c, o, s) => const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "You answered correctly!",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "You can now continue using the app for 10 minutes.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _closeOverlay,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  "Continue to App",
                                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}