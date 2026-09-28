import 'dart:math';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool showCaptcha = false;
  bool captchaVerified = false;

  String captchaCode = '';
  final TextEditingController captchaController = TextEditingController();

  void generateCaptcha() {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();

    setState(() {
      captchaCode = List.generate(
        5,
            (index) => characters[random.nextInt(characters.length)],
      ).join();

      showCaptcha = true;
      captchaVerified = false;
      captchaController.clear();
    });
  }

  void verifyCaptcha() {
    if (captchaController.text.trim().toUpperCase() == captchaCode) {
      setState(() {
        captchaVerified = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CAPTCHA verified'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect CAPTCHA. Try again.'),
        ),
      );

      generateCaptcha();
    }
  }

  @override
  void dispose() {
    captchaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),

            child: Column(
              children: [

                // NarcoX logo
                Image(
                  image: const AssetImage('assets/image/sih_logo.jpeg'),
                  height: 150,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Field Drug Testing & Evidence Management',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 45),

                // User ID
                TextField(
                  decoration: InputDecoration(
                    labelText: 'User ID / Email',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Password
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // CAPTCHA checkbox
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Row(
                    children: [
                      Checkbox(
                        value: captchaVerified,
                        onChanged: captchaVerified
                            ? null
                            : (value) {
                          if (value == true) {
                            generateCaptcha();
                          }
                        },
                      ),

                      const Expanded(
                        child: Text(
                          "I'm not a robot",
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.verified_user_outlined,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 12),
                    ],
                  ),
                ),

                // CAPTCHA challenge
                if (showCaptcha && !captchaVerified) ...[
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Column(
                      children: [

                        const Text(
                          'Security Verification',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // CAPTCHA code
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),

                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF2F5),
                            borderRadius: BorderRadius.circular(8),
                          ),

                          child: Center(
                            child: Text(
                              captchaCode,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: captchaController,
                          textCapitalization:
                          TextCapitalization.characters,

                          decoration: InputDecoration(
                            labelText: 'Enter CAPTCHA',
                            prefixIcon:
                            const Icon(Icons.security_outlined),

                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 45,

                          child: ElevatedButton(
                            onPressed: verifyCaptcha,

                            child: const Text(
                              'VERIFY',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        TextButton(
                          onPressed: generateCaptcha,
                          child: const Text(
                            'Generate New CAPTCHA',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: () {},

                    child: const Text(
                      'Forgot Password?',
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: ElevatedButton(
                    onPressed: captchaVerified
                        ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Login functionality coming soon',
                          ),
                        ),
                      );
                    }
                        : null,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF123B5D),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      Colors.grey.shade300,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    child: const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'VERITRA • Secure Evidence Management',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 15),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Homepage (Testing)',
                    style: TextStyle(
                      fontSize: 13,
                    ),
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