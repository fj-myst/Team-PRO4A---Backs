import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../auth/login_screen.dart';

class PersonnelBugReportScreen extends StatefulWidget {
  const PersonnelBugReportScreen({super.key});

  @override
  State<PersonnelBugReportScreen> createState() =>
      _PersonnelBugReportScreenState();
}

class _PersonnelBugReportScreenState
    extends State<PersonnelBugReportScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'UI / Display';
  bool _isSubmitting = false;

  Map<String, dynamic>? _userData;

  late Timer _clockTimer;
  late DateTime _now;

  final List<String> _categories = [
    'UI / Display',
    'Data / Content',
    'Performance',
    'Authentication',
    'Notifications',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _loadUserData();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Step 1: Get user document
    final doc = await _firestore.collection('users').doc(uid).get();
    final userData = doc.data() as Map<String, dynamic>?;
    final unitId = userData?['unitId'] ?? '';

    // Step 2: Get unit name
    String unitName = '';
    if (unitId.isNotEmpty) {
      final unitDoc = await _firestore
          .collection('units')
          .doc(unitId)
          .get();
      unitName = unitDoc.data()?['name'] ?? '';
    }

    // Step 3: Merge unitName into userData
    if (mounted) {
      setState(() => _userData = {
        ...?userData,
        'unitName': unitName,
      });
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF0A1A3A), width: 2),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CONFIRM LOGOUT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0A1A3A),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1A3A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'YES',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6080),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'NO',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _submitReport() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final uid = _auth.currentUser?.uid;
      await _firestore.collection('bug_reports').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'submittedBy': uid,
        'submittedByName': _userData?['name'] ?? 'Unknown',
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _titleController.clear();
      _descController.clear();
      setState(() => _selectedCategory = 'UI / Display');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bug report submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildHeader() {
    final name = (_userData?['name'] ?? '')
        .toString()
        .toUpperCase();
    final unitName = _userData?['unitName'] ?? '';
    final position = _userData?['position'] ?? '';
    final subtitle = [unitName, position]
        .where((s) => s.isNotEmpty)
        .join(' - ');

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1A3A),
        image: DecorationImage(
          image: AssetImage('assets/images/calabrz.png'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          opacity: 0.15,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // TOP ROW: TEAM-PRO4A + logout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TEAM-PRO4A',
                    style: TextStyle(
                      color: Color.fromARGB(200, 255, 255, 255),
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    onPressed: _confirmLogout,
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white70,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // PROFILE ROW: PNP seal + name + subtitle
              Row(
                children: [
                  Image.asset(
                    'assets/images/PNP-logo.png',
                    width: 52,
                    height: 52,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [

          _buildHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    'BUG REPORT',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A1A3A),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Report an issue or problem you encountered',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  _fieldLabel('CATEGORY'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Color(0xFF0A1A3A)),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c,
                                      style: const TextStyle(
                                          fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _fieldLabel('TITLE'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _titleController,
                    hint: 'Brief title of the issue',
                    maxLines: 1,
                  ),
                  const SizedBox(height: 20),

                  _fieldLabel('DESCRIPTION'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _descController,
                    hint: 'Describe the issue in detail — what happened, '
                        'when it occurred, and steps to reproduce it.',
                    maxLines: 6,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1A3A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SUBMIT REPORT',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0A1A3A),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}