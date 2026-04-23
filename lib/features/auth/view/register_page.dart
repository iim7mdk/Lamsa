import 'package:flutter/material.dart';
import '../auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _salonNameController = TextEditingController();  // لاسم الصالون
  final _phoneController = TextEditingController();      // لرقم الهاتف
  final _locationController = TextEditingController();   // للموقع
  final _workingHoursController = TextEditingController(); // لساعات العمل

  final AuthService _authService = AuthService();

  String selectedRole = 'customer';
  bool isLoading = false;

  Future<void> register() async {
    try {
      setState(() => isLoading = true);

      switch (selectedRole) {
        case 'owner':
          await _authService.ownerSignUp(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            salonName: _salonNameController.text.trim(),
            phone: _phoneController.text.trim(),
            location: _locationController.text.trim(),
            workingHours: _workingHoursController.text.trim(),
            services: [],
            bankAccounts: [],
          );
          break;

        case 'customer':
        default:
          await _authService.customerSignUp(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/decide');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(
                    value: 'customer',
                    child: Text('Customer'),
                  ),
                  DropdownMenuItem(
                    value: 'owner',
                    child: Text('Owner'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Choose Role'),
              ),

              if (selectedRole == 'owner') ...[
                const SizedBox(height: 16),

                TextField(
                  controller: _salonNameController,
                  decoration: const InputDecoration(labelText: 'Salon Name'),
                ),

                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),

                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),

                TextField(
                  controller: _workingHoursController,
                  decoration: const InputDecoration(labelText: 'Working Hours'),
                ),
              ],

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: isLoading ? null : register,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

