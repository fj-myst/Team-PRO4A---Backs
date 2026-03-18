import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
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
                              "Task & Event Activity Management",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 30,
                    ),
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

                // Right panel
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
                              "TEAM-PRO4A",
                              style: TextStyle(
                                fontSize: 50,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D3557),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Task & Event Activity Management",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
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
          "Forgot Password",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        const Text(
          "Enter your email and we'll send you a reset link.",
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
        const SizedBox(height: 30),

        // Send reset link button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              // TODO: hook up Firebase password reset
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D3557),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "SEND RESET LINK",
              style: TextStyle(fontSize: 16, letterSpacing: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Back to login
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Back to Login",
              style: TextStyle(color: Color(0xFF1D3557)),
            ),
          ),
        ),
      ],
    );
  }
}