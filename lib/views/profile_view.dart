import 'package:chat_app/controllers/profile_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        final user = controller.currentUser;
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        return Stack(
          children: [
            // 1. Curved Gradient Header Background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 260,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      Color(0xFF8C7AE6), // Lighter violet
                      AppTheme.secondaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),
            ),

            // 2. Custom App Bar on Top of Gradient
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Profile",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Obx(
                        () => TextButton(
                          onPressed: controller.toggleEditing,
                          child: Text(
                            controller.isEditing ? 'Cancel' : "Edit",
                            style: TextStyle(
                              color: controller.isEditing
                                  ? Colors.red.shade200
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Scrollable Content Layer
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 56,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // 4. Overlapping Profile Details Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Beautiful Avatar with border
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor,
                                        AppTheme.accentColor,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 56,
                                      backgroundColor: AppTheme.primaryColor,
                                      child: user.photoURL.isNotEmpty
                                          ? ClipOval(
                                              child: Image.network(
                                                user.photoURL,
                                                width: 112,
                                                height: 112,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return _buildDefaultAvatar(user);
                                                },
                                              ),
                                            )
                                          : _buildDefaultAvatar(user),
                                    ),
                                  ),
                                ),
                                if (controller.isEditing)
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Material(
                                      elevation: 4,
                                      shape: const CircleBorder(),
                                      color: AppTheme.primaryColor,
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () {
                                          Get.snackbar(
                                            "Info",
                                            "Profile pictures can be uploaded soon!",
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: AppTheme.cardColor,
                                            colorText: AppTheme.textPrimaryColor,
                                          );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // User Profile Text Details
                            Text(
                              user.displayName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 12),

                            // Glowing Online Indicator Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: user.isOnline
                                    ? AppTheme.successColor.withOpacity(0.12)
                                    : AppTheme.textSecondaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: user.isOnline
                                      ? AppTheme.successColor.withOpacity(0.25)
                                      : AppTheme.textSecondaryColor.withOpacity(0.15),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 8,
                                    width: 8,
                                    decoration: BoxDecoration(
                                      color: user.isOnline
                                          ? AppTheme.successColor
                                          : AppTheme.textSecondaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: user.isOnline
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.successColor.withOpacity(0.6),
                                                blurRadius: 6,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : [],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    user.isOnline ? "Online" : "Offline",
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: user.isOnline
                                              ? AppTheme.successColor
                                              : AppTheme.textSecondaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Joined Date Badge
                            Text(
                              controller.getJoinedData(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                            ),

                            // Display Editable Fields inside the Details Card
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: AppTheme.borderColor, height: 1),
                            ),

                            TextFormField(
                              controller: controller.displayNameController,
                              enabled: controller.isEditing,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              decoration: const InputDecoration(
                                labelText: "Display Name",
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: controller.emailController,
                              enabled: false,
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                labelText: "Email Address",
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                helperText: "Email can't be changed",
                              ),
                            ),

                            // Save Changes Button (When Editing)
                            if (controller.isEditing) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: controller.isLoading
                                      ? null
                                      : controller.updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                                    elevation: 4,
                                  ),
                                  child: controller.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text("Save Changes"),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 5. Settings Card (Quick Actions)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 8),
                            child: Text(
                              "Account & Settings",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          _buildActionTile(
                            context: context,
                            icon: Icons.security_rounded,
                            iconColor: AppTheme.primaryColor,
                            tileTitle: "Change Password",
                            onTap: () => Get.toNamed('/change-password'),
                          ),
                          _buildDivider(),
                          _buildActionTile(
                            context: context,
                            icon: Icons.delete_outline_rounded,
                            iconColor: AppTheme.errorColor,
                            tileTitle: "Delete Account",
                            titleColor: AppTheme.errorColor,
                            onTap: controller.deleteAccount,
                          ),
                          _buildDivider(),
                          _buildActionTile(
                            context: context,
                            icon: Icons.logout_rounded,
                            iconColor: AppTheme.errorColor,
                            tileTitle: "Sign Out",
                            titleColor: AppTheme.errorColor,
                            onTap: controller.signOut,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 6. App Version Info
                    Text(
                      "Chat App v1.0.0",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDefaultAvatar(dynamic user) {
    return Text(
      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 36,
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String tileTitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
      title: Text(
        tileTitle,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: titleColor ?? AppTheme.textPrimaryColor,
            ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppTheme.textSecondaryColor,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: AppTheme.borderColor, height: 1),
    );
  }
}
