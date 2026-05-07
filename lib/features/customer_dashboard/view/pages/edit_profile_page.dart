import 'package:flutter/material.dart';
import 'package:lamsa/core/model/user_model.dart';
import 'package:lamsa/features/auth/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {

  final AuthService _authService = AuthService();

  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _authService.getUserData();
  }

  void _refreshUserData() {
    setState(() {
      _userFuture = _authService.getUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تعديل الملف الشخصي"),
      ),

      body: FutureBuilder<UserModel?>(
        future: _userFuture,

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text("لا توجد بيانات"),
            );
          }

          final userData = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text('الايميل'),
                        subtitle: Text(userData.email),
                      ),
                    ),
                  ],
                ),

                const Divider(),

                _buildEditableRow(
                  context: context,
                  icon: Icons.person,
                  title: "الاسم",
                  value: userData.name,
                  fieldName: "name",
                  dialogTitle: "تعديل الاسم",
                ),

                // const Divider(),

                // _buildEditableRow(
                //   context: context,
                //   icon: Icons.phone,
                //   title: "رقم الجوال",
                //   value: userData.phone,
                //   fieldName: "phone",
                //   dialogTitle: "تعديل رقم الجوال",
                //   keyboardType: TextInputType.phone,
                // ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditableRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required String fieldName,
    required String dialogTitle,
    TextInputType keyboardType = TextInputType.text,
  }) {

    return Row(
      children: [

        Expanded(
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(value),
          ),
        ),

        IconButton(
          icon: const Icon(Icons.edit),

          onPressed: () {
            _showEditDialog(
              context: context,
              fieldName: fieldName,
              currentValue: value,
              dialogTitle: dialogTitle,
              keyboardType: keyboardType,
            );
          },
        ),
      ],
    );
  }

  void _showEditDialog({
    required BuildContext context,
    required String fieldName,
    required String currentValue,
    required String dialogTitle,
    required TextInputType keyboardType,
  }) {

    final controller = TextEditingController(
      text: currentValue,
    );

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(

          title: Text(dialogTitle),

          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("إلغاء"),
            ),

            ElevatedButton(
              onPressed: () async {

                await _authService.updateUserField(
                  fieldName,
                  controller.text.trim(),
                );

                if (!context.mounted) return;

                Navigator.pop(context);

                _refreshUserData();
              },

              child: const Text("حفظ"),
            ),
          ],
        );
      },
    );
  }
}