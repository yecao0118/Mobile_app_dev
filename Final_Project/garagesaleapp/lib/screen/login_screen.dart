import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController            = TextEditingController();
  final _passwordController         = TextEditingController();
  final _confirmPasswordController  = TextEditingController();  // ← new
  final _formKey                    = GlobalKey<FormState>();
  bool _isLoading   = false;
  bool _isRegistering = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();  // ← dispose it
    super.dispose();
  }

  Future<void> _submitAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isRegistering) {
        // extra safety check
        if (_passwordController.text.trim() !=
            _confirmPasswordController.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Passwords do not match')),
          );
          setState(() => _isLoading = false);
          return;
        }

        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email:    _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful!')),
        );
        Navigator.pop(context, true);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email:    _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_isRegistering ? 'Register' : 'Hyper Garage Sales Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter email';
                  if (!v.contains('@')) return 'Please enter a valid email';
                  return null;
                },
              ),

              SizedBox(height: 12),

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter password';
                  if (v.length < 6)   return 'Password must be at least 6 characters';
                  return null;
                },
              ),

              // Confirm Password only when registering
              if (_isRegistering) ...[
                SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v.trim() != _passwordController.text.trim())
                      return 'Passwords do not match';
                    return null;
                  },
                ),
              ],

              SizedBox(height: 20),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitAuth,
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isRegistering ? 'Register' : 'Login'),
              ),

              // Toggle register/login
              TextButton(
                onPressed: () => setState(() => _isRegistering = !_isRegistering),
                child: Text(_isRegistering
                    ? 'Already have an account? Login'
                    : 'Need an account? Register'),
              ),

              // Forgot password only when logging in
              if (!_isRegistering) ...[
                SizedBox(height: 12),
                TextButton(
                  onPressed: _sendPasswordReset,
                  child: Text('Forgot password?'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset email')),
      );
    }
  }
}
