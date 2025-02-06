import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        children: const [
          ListTile(
            title: Text('item 1'),
          ),
          ListTile(
            title: Text('item 2'),
          ),
        ],
      ),
    );
  }
}