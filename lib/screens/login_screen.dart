import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  void _showForgotPasswordDialog() {
    final forgotEmailController = TextEditingController();
    final forgotFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('የይለፍ ቃል እረሱ?'),
        content: Form(
          key: forgotFormKey,
          child: TextFormField(
            controller: forgotEmailController,
            decoration: const InputDecoration(
              labelText: 'ኢሜይል',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'እባክዎ ኢሜይልዎን ያስገቡ';
              }
              if (!value.contains('@')) {
                return 'እባክዎ ትክክለኛ ኢሜይል ያስገቡ';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ተመለስ'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (forgotFormKey.currentState!.validate()) {
                try {
                  await context
                      .read<AuthProvider>()
                      .resetPassword(forgotEmailController.text);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('የይለፍ ቃል ማስተካከያ ወደ ኢሜይልዎ ተልኳል'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('ላክ'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (_isLogin) {
          await context.read<AuthProvider>().signInWithEmailAndPassword(
                _emailController.text,
                _passwordController.text,
              );
        } else {
          await context.read<AuthProvider>().registerWithEmailAndPassword(
                _emailController.text,
                _passwordController.text,
                _emailController.text.split('@')[0],
              );
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'የኢትዮጵያ የግብይት መተግበሪያ',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'ኢሜይል',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'እባክዎ ኢሜይልዎን ያስገቡ';
                      }
                      if (!value.contains('@')) {
                        return 'እባክዎ ትክክለኛ ኢሜይል ያስገቡ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'የይለፍ ቃል',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'እባክዎ የይለፍ ቃልዎን ያስገቡ';
                      }
                      if (value.length < 6) {
                        return 'የይለፍ ቃሉ ቢያንስ 6 ፊደላት መሆን አለበት';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(_isLogin ? 'ግባ' : 'ተመዝገብ'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? 'አዲስ ተጠቃሚ ነዎት? ተመዝገቡ' : 'አባል ነዎት? ይግቡ',
                    ),
                  ),
                  if (_isLogin) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text('የይለፍ ቃልዎን ረሱት?'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
