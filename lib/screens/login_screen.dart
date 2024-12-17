import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      print('Giriş denemesi başlatılıyor...');
      print('Kullanıcı adı: ${_usernameController.text.trim()}');
      
      final user = await authService.signInWithUsername(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      print('Giriş başarılı: ${user.name}, Rol: ${user.role}');

      if (!mounted) return;
      
      // Başarılı giriş bildirimi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hoş geldiniz, ${user.name}!'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Kullanıcı rolüne göre yönlendirme
      if (user.role == 'admin') {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/admin-dashboard-screen');
        }
      } else {
        // TODO: Çalışan dashboard'u daha sonra eklenecek
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çalışan paneli henüz hazır değil.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Giriş hatası: $e');
      if (!mounted) return;
      
      String errorMessage = e.toString();
      if (errorMessage.contains('Kullanıcı bulunamadı')) {
        errorMessage = 'Kullanıcı adı veya şifre hatalı';
      } else if (errorMessage.contains('Yanlış şifre')) {
        errorMessage = 'Kullanıcı adı veya şifre hatalı';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage.replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'HAN Holding',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'İş Takip Sistemi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _usernameController,
                  labelText: 'Kullanıcı Adı',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kullanıcı adı gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Şifre',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre gerekli';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Giriş Yap',
                  onPressed: _isLoading ? null : _login,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text('Hesabınız yok mu? Kayıt olun'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
