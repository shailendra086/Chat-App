import 'package:chat_app/controllers/forgot_password_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final controller = Get.put(ForgotPasswordController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: controller.goBackToLogin,
                      icon: Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Forgot Password",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Enter your email address and we'll send you a link to reset your password.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.lock_person_rounded,
                      size: 50,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Obx(() {
                  if (controller.emailSent) {
                    return _buildEmailSentContent(controller);
                  } else {
                    return _builEmailForm(controller);
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _builEmailForm(ForgotPasswordController controller) {
    return Column(
      children: [
        TextFormField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Email",
            hintText: 'Enter Your Email Address',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: controller.validateEmail,
        ),
        SizedBox(height: 32),
        Obx(
          () => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading
                  ? null
                  : controller.sendPasswordResetEmail,
              icon: controller.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.send_outlined),
              label: Text(
                controller.isLoading ? "Sending..." : "Send Reset Link",
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Remember your password?",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: controller.goBackToLogin,
              child: Text(
                "Sign In",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailSentContent(ForgotPasswordController controller) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 40,
                color: AppTheme.successColor,
              ),
              SizedBox(height: 8),
              Text(
                "Email Sent",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.successColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "We have sent you an email with a link to reset your password.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                controller.emailController.text,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                "Check your email and follow the instructions to reset your password.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.resendEmail,

            icon: Icon(Icons.refresh_outlined),
            label: Text("Resend Email"),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.goBackToLogin,

            icon: Icon(Icons.arrow_back_ios_new_rounded),
            label: Text("Back to Login"),
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: AppTheme.secondaryColor,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  textAlign: TextAlign.justify,
                  "If you haven't received an email, check your spam folder or try again later.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
