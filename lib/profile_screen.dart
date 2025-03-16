import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'locale_provider.dart'; // Import LocaleProvider
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userProfile = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userProfile.exists) {
        setState(() {
          _nameController.text = userProfile['name'] ?? '';
          _emailController.text = user.email ?? '';
          _phoneController.text = userProfile['phone'] ?? '';
          _profileImageUrl = userProfile['profileImageUrl'];
        });
      } else {
        String randomProfileImageUrl = _getRandomProfileImageUrl();
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': '',
          'phone': '',
          'profileImageUrl': randomProfileImageUrl,
        });
        setState(() {
          _emailController.text = user.email ?? '';
          _profileImageUrl = randomProfileImageUrl;
        });
      }
    }
  }

  Future<void> _updateUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'profileImageUrl': _profileImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  String _getRandomProfileImageUrl() {
    final random = Random();
    final imageUrlList = [
      'https://randomuser.me/api/portraits/men/1.jpg',
      'https://randomuser.me/api/portraits/men/2.jpg',
      'https://randomuser.me/api/portraits/men/3.jpg',
      'https://randomuser.me/api/portraits/women/1.jpg',
      'https://randomuser.me/api/portraits/women/2.jpg',
      'https://randomuser.me/api/portraits/women/3.jpg',
    ];
    return imageUrlList[random.nextInt(imageUrlList.length)];
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.black), // เปลี่ยนสีฟอนต์เป็นสีดำ
        ),
        backgroundColor: Colors.white, // เปลี่ยนสีพื้นหลังเป็นสีขาว
        iconTheme: IconThemeData(color: Colors.black), // เปลี่ยนสีไอคอนเป็นสีดำ
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _profileImageUrl != null
                ? CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(_profileImageUrl!),
                  )
                : CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50, color: Colors.black),
                    backgroundColor: Colors.grey.shade300,
                  ),
            SizedBox(height: 20),
            Material(
              elevation: 2,
              shadowColor: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.person, color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                style: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(height: 10),
            Material(
              elevation: 2,
              shadowColor: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.email, color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                readOnly: true,
                style: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(height: 10),
            Material(
              elevation: 2,
              shadowColor: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
              child: TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.phone, color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                style: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: localeProvider.selectedCurrency,
              items: localeProvider.availableCurrencies.map((currency) {
                return DropdownMenuItem(value: currency, child: Text(currency));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  localeProvider.setCurrency(value);
                }
              },
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity, // ทำให้ปุ่มกว้างเต็มที่
              child: ElevatedButton(
                onPressed: _updateUserProfile,
                child: Text(
                  'Update Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // เปลี่ยนสีพื้นหลังปุ่มเป็นสีดำ
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                  shadowColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}