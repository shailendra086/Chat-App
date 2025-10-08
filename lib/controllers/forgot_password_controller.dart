import 'package:chat_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordController extends GetxController {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxBool _emailSent = false.obs;

  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get emailSent => _emailSent.value;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> sendPasswordResetEmail() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    try {
      _isLoading.value = true;
      _error.value = '';
      await _authService.sendPasswordResetEmail(emailController.text.trim());
      _emailSent.value = true;
      Get.snackbar(
        "Success",
        "Password reset email sent to ${emailController.text}",
        colorText: Colors.green,
        backgroundColor: Colors.green.shade100,
        duration: Duration(seconds: 4),
      );
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar(
        "Success",
        "Password reset email sent to ${e.toString()}",
        colorText: Colors.red,
        backgroundColor: Colors.red.shade100,
        duration: Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void goBackToLogin() {
    Get.back();
  }

  void resendEmail() {
    _emailSent.value = false;
    sendPasswordResetEmail();
  }

  String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value!)) {
      return "Please enter a valid email";
    }
    return null;
  }

  void _clearError() {
    _error.value = '';
  }
}
