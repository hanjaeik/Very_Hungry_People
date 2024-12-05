import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InfoForm extends StatefulWidget {
  @override
  _InfoFormState createState() => _InfoFormState();
}

class _InfoFormState extends State<InfoForm> {
  final _formKey = GlobalKey<FormState>();

  // Variables to store form data
  String name = '';
  String phoneNumber = '';
  String age = '';
  String gender = '';
  XFile? pickedImage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      pickedImage = pickedFile != null ? XFile(pickedFile.path) : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '내 프로필을 입력하세요',
          style: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.black26,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputBox(
                labelText: '이름',
                hintText: '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
                onSaved: (value) {
                  name = value!;
                },
              ),
              _buildInputBox(
                labelText: '전화번호',
                hintText: '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '전화번호를 입력해주세요';
                  }
                  return null;
                },
                onSaved: (value) {
                  phoneNumber = value!;
                },
              ),
              _buildInputBox(
                labelText: '나이',
                hintText: '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '나이를 입력해주세요';
                  }
                  return null;
                },
                onSaved: (value) {
                  age = value!;
                },
              ),
              _buildInputBox(
                labelText: '성별',
                hintText: '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '성별을 입력해주세요';
                  }
                  return null;
                },
                onSaved: (value) {
                  gender = value!;
                },
              ),
              // Image picker
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('사진 첨부', style: TextStyle(fontFamily: 'NanumGothic', color: Colors.black)),
              ),
              if (pickedImage != null)
                Image.file(
                  File(pickedImage!.path),
                  height: 100,
                  width: 100,
                ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    // Get current user
                    final currentUser = _auth.currentUser;
                    if (currentUser == null) {
                      // Handle the case where no user is signed in
                      return;
                    }

                    // Save data to Cloud Firestore under 'userpf' collection
                    await _firestore.collection('userpf').doc(currentUser.email).set({
                      'name': name,
                      'phoneNumber': phoneNumber,
                      'age': age,
                      'gender': gender,
                      'image': pickedImage?.path, // Store image path in Firestore
                    });

                    // Process the form data, for example, show a success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('저장 완료!', style: TextStyle(fontFamily: 'NanumGothic', color: Colors.white)),
                      ),
                    );
                  }
                },
                child: Text('저장', style: TextStyle(fontFamily: 'NanumGothic', color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBox({
    required String labelText,
    required String hintText,
    required String? Function(String?)? validator,
    required void Function(String?)? onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        style: TextStyle(color: Colors.white), // 텍스트 색상을 흰색으로 변경
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white), // 힌트 텍스트 색상을 흰색으로 변경
          labelStyle: TextStyle(color: Colors.white), // 레이블 텍스트 색상을 흰색으로 변경
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white), // 텍스트 필드 비활성 상태의 경계선 색상을 흰색으로 변경
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white), // 텍스트 필드 활성 상태의 경계선 색상을 흰색으로 변경
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}