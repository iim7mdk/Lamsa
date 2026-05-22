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

  final _salonNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _workingHoursController = TextEditingController();

  final AuthService _authService = AuthService();

  String selectedRole = 'customer';
  bool isLoading = false;
  bool _isObscure = true;

  Future<void> register() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة البيانات الأساسية')),
      );
      return;
    }

    if (selectedRole == 'owner' &&
        (_salonNameController.text.trim().isEmpty ||
            _phoneController.text.trim().isEmpty ||
            _locationController.text.trim().isEmpty ||
            _workingHoursController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة بيانات الصالون')),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      if (selectedRole == 'owner') {
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
      } else {
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
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _salonNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إنشاء حساب'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor:
                      theme.colorScheme.primary.withOpacity(0.12),
                      child: Icon(
                        Icons.spa,
                        size: 42,
                        color: theme.colorScheme.primary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'انضم إلى لمسة',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      selectedRole == 'owner'
                          ? 'أنشئ حساب مالك صالون وسيتم مراجعته من الأدمن'
                          : 'أنشئ حسابك واحجز خدمات الصوالين بسهولة',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 26),

                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'نوع الحساب',
                        prefixIcon: Icon(Icons.manage_accounts_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'customer',
                          child: Text('عميل'),
                        ),
                        DropdownMenuItem(
                          value: 'owner',
                          child: Text('مالك صالون'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedRole = value;
                        });
                      },
                    ),

                    if (selectedRole == 'owner') ...[
                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'بيانات الصالون',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _salonNameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم الصالون',
                          prefixIcon: Icon(Icons.store_outlined),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'رقم الجوال',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'الموقع',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _workingHoursController,
                        decoration: const InputDecoration(
                          labelText: 'ساعات العمل',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : register,
                        child: isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text('إنشاء الحساب'),
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