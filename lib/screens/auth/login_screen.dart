import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../tech_admin/tech_admin_home.dart';
import '../viewer_admin/viewer_admin_home.dart';
import '../unit/unit_home.dart';
import '../personnel/personnel_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return Scaffold(
      body: isMobile
          ? SingleChildScrollView(
              child: Column(
                children: [
                  // Image + overlay
                  Stack(
                    children: [
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 0, 29, 71),
                          image: DecorationImage(
                            image: AssetImage("assets/images/calabrz.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TEAM-PRO4A",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Activity, Conference & Task Information Operations Network",
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: _buildForm(),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                // Left image panel
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 0, 29, 71),
                      image: DecorationImage(
                        image: AssetImage("assets/images/calabrz.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Right login panel
                Expanded(
                  flex: 4,
                  child: Container(
                    color: const Color(0xFFE6E8EB),
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ACTION",
                              style: TextStyle(
                                fontSize: 50,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D3557),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Activity, Conference & Task Information Operations Network",
                              style: TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(height: 40),
                            _buildForm(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Login",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        const Text(
          "Please enter your details",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 30),

        // Email
        const Text("Email Address"),
        const SizedBox(height: 10),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "Enter your email address...",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Password
        const Text("Password"),
        const SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "Enter your password...",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Forgot password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text("Forgot Password?"),
          ),
        ),

        // Error message
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),

        const SizedBox(height: 10),

        // Login button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D3557),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "LOGIN",
                    style: TextStyle(fontSize: 16, letterSpacing: 1.2),
                  ),
          ),
        ),
      ],
    );
  }

  void _login() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    final result = await AuthService().login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      final String role = result['role'];

      Widget home;
      if (role == 'tech_admin') {
        home = const TechAdminHome();
      } else if (role == 'viewer_admin') {
        home = const ViewerAdminHome();
      } else if (role == 'unit') {
        home = const UnitHome();
      } else if (role == 'personnel') {
        home = const PersonnelHome();
      } else {
        setState(() => _errorMessage = 'Unknown role. Contact your administrator.');
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => home),
      );
    } else {
      setState(() => _errorMessage = result['message']);
    }
  }
}