import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/role_redirect.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'student';
  bool _loading = false;
  String? _error;


  
  Future<void> _signInWithGoogle() async {
  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      setState(() => _loading = false); // User canceled
      return;
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    // Check if user exists in Firestore, else create
    final uid = userCredential.user!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('user').doc(uid).get();

    if (!userDoc.exists) {
      await FirebaseFirestore.instance.collection('user').doc(uid).set({
        'email': userCredential.user!.email,
        'role': 'student', // default role for Google sign-in
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await redirectBasedOnRole(context);
  } on FirebaseAuthException catch (e) {
    setState(() {
      _error = e.message;
    });
  } finally {
    setState(() {
      _loading = false;
    });
  }
}

  Future<void> _signup() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text);

      // Save role in Firestore
      await FirebaseFirestore.instance
          .collection('user')
          .doc(userCredential.user!.uid)
          .set({
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate or show success (can be customized)
      await redirectBasedOnRole(context); // back to login
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
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
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: ['student', 'driver', 'admin']
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedRole = val!),
              decoration: const InputDecoration(labelText: 'Select Role'),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _signup,
                    child: const Text('Sign Up'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text("Already have an account? Login"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Image.asset(
                      'assets/google_logo.png', // Add a Google logo here
                      height: 24,
                      width: 24,
                    ),
                    label: const Text("Continue with Google"),
                    onPressed: _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),


          ],
        ),
      ),
    );
  }
}
