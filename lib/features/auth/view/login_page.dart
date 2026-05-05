import 'package:flutter/material.dart';
import 'package:lamsa/features/auth/view/register_page.dart';
import '../auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  @override
  void initState() {
    super.initState();
    loadSavedEmail();
  }

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;
  final AuthService _authService = AuthService();

  bool isLoading = false;

  Future<void> login() async {
    try {
      setState(() {
        isLoading = true;
      });

      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'saved_email',
        _emailController.text.trim(),
      );

      if (!mounted) return; // من باب الامان( اذا كانت الصفحة غير مفتوحه )
      Navigator.pushReplacementNamed(context, '/decide');
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),

            TextField(
              controller: _passwordController,
              obscureText: _isObscure,
              decoration: InputDecoration(
                  labelText: 'Password',

                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),

              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : login,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login'),
            ),

            const SizedBox(height: 12),



            const SizedBox(height: 12),

            TextButton(
              onPressed: () async {

                final email = _emailController.text.trim();

                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your email first'),
                    ),
                  );
                  return;
                }

                try {

                  await _authService.sendPasswordResetEmail(
                    _emailController.text.trim(),
                  );

                  print('SUCCESS');

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password reset email sent. Check your inbox.',
                      ),
                    ),
                  );

                } catch (e) {

                  print('ERROR: $e');

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                    ),
                  );

                }
              },

              child: const Text('Forgot Password'),
            ),

            const SizedBox(height: 6),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterPage(),
                  ),
                );
              },
              child: const Text('Create Account'),
            ),

          ],
        ),
      ),
    );
  }

  Future<void> loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString('saved_email');

    if (savedEmail != null) {
      _emailController.text = savedEmail;
    }
  }
}
