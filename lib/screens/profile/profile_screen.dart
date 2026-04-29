import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../history/history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploadingPhoto = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoSourceSheet(),
    );
    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId == null) return;

      final url = await StorageService().uploadProfileImage(
        userId: userId,
        imageFile: File(picked.path),
      );
      if (!mounted) return;
      await context.read<UserProvider>().updateProfile(
            userId: userId,
            photoURL: url,
          );
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf yüklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final clothing = context.watch<ClothingProvider>();
    final outfits  = context.watch<OutfitProvider>();
    final name     = auth.user?.displayName ?? auth.user?.email ?? 'Kullanıcı';
    final email    = auth.user?.email ?? '';
    final initial  = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final photoURL = auth.user?.photoURL;

    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      body: CustomScrollView(
        slivers: [
          // ─── Header ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Profil',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.darkRose, AppTheme.primaryRose,
                        Color(0xFFE8A0BB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      GestureDetector(
                        onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                        child: Stack(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(30),
                                border: Border.all(
                                    color: Colors.white.withAlpha(150),
                                    width: 2),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _uploadingPhoto
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : photoURL != null
                                      ? CachedNetworkImage(
                                          imageUrl: photoURL,
                                          fit: BoxFit.cover,
                                          width: 84,
                                          height: 84,
                                          placeholder: (_, _) => Center(
                                            child: Text(initial,
                                                style:
                                                    GoogleFonts.playfairDisplay(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                )),
                                          ),
                                          errorWidget: (_, _, _) => Center(
                                            child: Text(initial,
                                                style:
                                                    GoogleFonts.playfairDisplay(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                )),
                                          ),
                                        )
                                      : Center(
                                          child: Text(initial,
                                              style:
                                                  GoogleFonts.playfairDisplay(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              )),
                                        ),
                            ),
                            // Kamera ikonu rozeti
                            if (!_uploadingPhoto)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: AppTheme.primaryRose,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      Text(
                        email,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withAlpha(180)),
                      ),
                    ],
                  ),
                ),
              ),
              titlePadding: EdgeInsets.zero,
            ),
          ),

          // ─── Body ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                _StatsRow(
                  clothingCount: clothing.items.length,
                  outfitCount: outfits.outfits.length,
                ),
                const SizedBox(height: 20),

                // Settings section
                _SectionLabel('Hesap'),
                const SizedBox(height: 8),
                _SettingTile(
                  icon: Icons.history_rounded,
                  label: 'Giyim Geçmişi',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HistoryScreen()),
                  ),
                ),
                _SettingTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil Bilgileri',
                  onTap: () {},
                ),
                _SettingTile(
                  icon: Icons.notifications_outlined,
                  label: 'Bildirimler',
                  onTap: () {},
                ),
                _SettingTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'Şifre Değiştir',
                  onTap: () {},
                ),
                const SizedBox(height: 16),

                _SectionLabel('Tercihler'),
                const SizedBox(height: 8),
                _SettingTile(
                  icon: Icons.palette_outlined,
                  label: 'Stil Tercihleri',
                  onTap: () {},
                ),
                _SettingTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Yardım & Destek',
                  onTap: () {},
                ),
                const SizedBox(height: 24),

                // Sign out button
                GestureDetector(
                  onTap: auth.isLoading
                      ? null
                      : () => context.read<AuthProvider>().signOut(),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (auth.isLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.errorRed),
                          )
                        else ...[
                          const Icon(Icons.logout_rounded,
                              color: AppTheme.errorRed, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Çıkış Yap',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ───────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int clothingCount;
  final int outfitCount;
  const _StatsRow({required this.clothingCount, required this.outfitCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(value: '$clothingCount', label: 'Kıyafet')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(value: '$outfitCount', label: 'Kombin')),
        const SizedBox(width: 12),
        const Expanded(child: _StatCard(value: '✓', label: 'Ajanda')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryRose),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppTheme.textLight,
        letterSpacing: 1,
      ),
    );
  }
}

// ─── Setting Tile ─────────────────────────────────────────────────────────────
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.lightRose,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: AppTheme.primaryRose),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textDark),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textLight, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Fotoğraf Kaynak Seçici ───────────────────────────────────────────────────
class _PhotoSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Profil Fotoğrafı',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          const SizedBox(height: 16),
          _SourceTile(
            icon: Icons.camera_alt_rounded,
            label: 'Kamera',
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 8),
          _SourceTile(
            icon: Icons.photo_library_rounded,
            label: 'Galeri',
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgStart,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.lightRose,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppTheme.primaryRose),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark)),
          ],
        ),
      ),
    );
  }
}
