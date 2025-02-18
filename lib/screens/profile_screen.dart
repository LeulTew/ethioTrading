import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = generateMockUserProfile();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(userProfile.profilePictureUrl),
          ),
          const SizedBox(height: 16),
          Text(
            userProfile.username,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            userProfile.email,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}