import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../history/history_screen.dart';
import '../stats/stats_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploadingPhoto = false;

  // ── Profil fotoğrafı ──────────────────────────────────────────────
  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoSourceSheet(),
    );
    if (source == null) return;

    final picked = await ImagePicker()
        .pickImage(source: source, imageQuality: 85);
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
      await context
          .read<UserProvider>()
          .updateProfile(userId: userId, photoURL: url);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
    } catch (e) {
      if (mounted) {
        _snack('Fotoğraf yüklenemedi: $e');
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ── Profil bilgileri (ad) ─────────────────────────────────────────
  Future<void> _editDisplayName() async {
    final auth = context.read<AuthProvider>();
    final ctrl = TextEditingController(
        text: auth.user?.displayName ?? '');
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TextFieldSheet(
        title: 'Profil Bilgileri',
        label: 'Ad Soyad',
        controller: ctrl,
        hint: 'Adın nasıl görünsün?',
      ),
    );
    if (saved == null || !mounted) return;
    final userId = auth.user?.id;
    if (userId == null) return;
    final ok = await context
        .read<UserProvider>()
        .updateProfile(userId: userId, displayName: saved);
    if (!mounted) return;
    if (ok) {
      await context.read<AuthProvider>().refreshUser();
    } else {
      _snack('Güncellenemedi.');
    }
  }

  // ── Şifre değiştir (reset e-postası) ─────────────────────────────
  Future<void> _changePassword() async {
    final auth = context.read<AuthProvider>();
    final email = auth.user?.email ?? '';
    if (email.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Şifre Sıfırla',
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
          '$email adresine şifre sıfırlama bağlantısı gönderilecek.',
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppTheme.textMedium, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('İptal',
                  style:
                      GoogleFonts.poppins(color: AppTheme.textLight))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Gönder',
                  style: GoogleFonts.poppins(
                      color: AppTheme.primaryRose,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context
        .read<AuthProvider>()
        .resetPassword(email);
    if (!mounted) return;
    _snack(ok
        ? 'Sıfırlama bağlantısı e-postana gönderildi.'
        : 'Gönderilemedi. Daha sonra tekrar dene.');
  }

  // ── Stil tercihleri ───────────────────────────────────────────────
  Future<void> _editStyleProfile() async {
    final auth = context.read<AuthProvider>();
    final current =
        context.read<UserProvider>().styleProfile ?? '';
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StylePickerSheet(current: current),
    );
    if (selected == null || !mounted) return;
    final userId = auth.user?.id;
    if (userId == null) return;
    await context
        .read<UserProvider>()
        .updateProfile(userId: userId, styleProfile: selected);
    if (mounted) _snack('Stil tercihin güncellendi.');
  }

  // ── Bildirimler ───────────────────────────────────────────────────
  Future<void> _showNotifications() async {
    final granted =
        await NotificationService().requestPermission();
    if (!mounted) return;
    if (!granted) {
      _snack('Bildirim izni verilmedi. Ayarlardan etkinleştir.');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationSheet(),
    );
  }

  // ── Yardım & Destek ───────────────────────────────────────────────
  void _showHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _HelpSheet(),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final clothing = context.watch<ClothingProvider>();
    final outfits = context.watch<OutfitProvider>();
    final userProv = context.watch<UserProvider>();
    final planner = context.watch<PlannerProvider>();
    final name =
        auth.user?.displayName ?? auth.user?.email ?? 'Kullanıcı';
    final email = auth.user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final photoURL = auth.user?.photoURL;
    final styleProfile = userProv.styleProfile;

    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      body: CustomScrollView(
        slivers: [
          // ─── Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text('Profil',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.darkRose,
                      AppTheme.primaryRose,
                      Color(0xFFE8A0BB)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: _uploadingPhoto
                            ? null
                            : _pickAndUploadPhoto,
                        child: Stack(children: [
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
                                                style: GoogleFonts
                                                    .playfairDisplay(
                                                  fontSize: 36,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: Colors.white,
                                                ))),
                                        errorWidget: (_, _, _) => Center(
                                            child: Text(initial,
                                                style: GoogleFonts
                                                    .playfairDisplay(
                                                  fontSize: 36,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: Colors.white,
                                                ))),
                                      )
                                    : Center(
                                        child: Text(initial,
                                            style: GoogleFonts
                                                .playfairDisplay(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ))),
                          ),
                          if (!_uploadingPhoto)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: AppTheme.primaryRose),
                              ),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      Text(name,
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(email,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withAlpha(180))),
                    ],
                  ),
                ),
              ),
              titlePadding: EdgeInsets.zero,
            ),
          ),

          // ─── Body ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StatsRow(
                  clothingCount: clothing.items.length,
                  outfitCount: outfits.outfits.length,
                  plannedDays: planner.filledDaysCount,
                ),
                const SizedBox(height: 20),

                _SectionLabel('Hesap'),
                const SizedBox(height: 8),
                _SettingTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'İstatistikler',
                  subtitle: 'Gardırop & kombin analitiği',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const StatsScreen())),
                ),
                _SettingTile(
                  icon: Icons.history_rounded,
                  label: 'Giyim Geçmişi',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const HistoryScreen())),
                ),
                _SettingTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil Bilgileri',
                  subtitle: name,
                  onTap: _editDisplayName,
                ),
                _SettingTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'Şifre Değiştir',
                  subtitle: 'E-posta ile sıfırlama',
                  onTap: _changePassword,
                ),
                _SettingTile(
                  icon: Icons.notifications_outlined,
                  label: 'Bildirimler',
                  subtitle: 'Günlük & haftalık hatırlatıcılar',
                  onTap: _showNotifications,
                ),
                const SizedBox(height: 16),

                _SectionLabel('Tercihler'),
                const SizedBox(height: 8),
                _SettingTile(
                  icon: Icons.palette_outlined,
                  label: 'Stil Tercihleri',
                  subtitle: styleProfile?.isNotEmpty == true
                      ? styleProfile
                      : 'Seçilmedi',
                  onTap: _editStyleProfile,
                ),
                _SettingTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Yardım & Destek',
                  onTap: _showHelp,
                ),
                const SizedBox(height: 24),

                // Çıkış
                GestureDetector(
                  onTap: auth.isLoading
                      ? null
                      : () =>
                          context.read<AuthProvider>().signOut(),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: const Color(0xFFFFCDD2)),
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
                          Text('Çıkış Yap',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.errorRed)),
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

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int clothingCount;
  final int outfitCount;
  final int plannedDays;
  const _StatsRow({
    required this.clothingCount,
    required this.outfitCount,
    required this.plannedDays,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child:
                _StatCard(value: '$clothingCount', label: 'Kıyafet')),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(value: '$outfitCount', label: 'Kombin')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(value: '$plannedDays/7', label: 'Ajanda')),
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
          Text(value,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryRose)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppTheme.textMedium)),
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
    return Text(text.toUpperCase(),
        style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight,
            letterSpacing: 1));
  }
}

// ─── Setting Tile ─────────────────────────────────────────────────────────────
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child:
                  Icon(icon, size: 16, color: AppTheme.primaryRose),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textDark)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
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

// ─── Fotoğraf Kaynak Sheet ────────────────────────────────────────────────────
class _PhotoSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title: 'Profil Fotoğrafı',
      child: Column(
        children: [
          _SheetTile(
            icon: Icons.camera_alt_rounded,
            label: 'Kamera',
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 8),
          _SheetTile(
            icon: Icons.photo_library_rounded,
            label: 'Galeri',
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

// ─── Metin Düzenleme Sheet ────────────────────────────────────────────────────
class _TextFieldSheet extends StatelessWidget {
  final String title;
  final String label;
  final String hint;
  final TextEditingController controller;

  const _TextFieldSheet({
    required this.title,
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMedium)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textLight),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final val = controller.text.trim();
                if (val.isNotEmpty) Navigator.pop(context, val);
              },
              child: Text('Kaydet',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stil Tercihi Sheet ───────────────────────────────────────────────────────
class _StylePickerSheet extends StatefulWidget {
  final String current;
  const _StylePickerSheet({required this.current});

  @override
  State<_StylePickerSheet> createState() => _StylePickerSheetState();
}

class _StylePickerSheetState extends State<_StylePickerSheet> {
  static const _styles = [
    ('👗', 'Şık & Zarif'),
    ('👖', 'Günlük & Rahat'),
    ('🏃', 'Spor & Aktif'),
    ('🖤', 'Minimalist'),
    ('🌸', 'Feminen & Romantik'),
    ('🎨', 'Yaratıcı & Bohem'),
    ('💼', 'Profesyonel & İş'),
    ('✨', 'Trend & Modern'),
  ];

  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title: 'Stil Tercihleri',
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _styles.map((s) {
              final (emoji, label) = s;
              final sel = _selected == label;
              return GestureDetector(
                onTap: () => setState(() => _selected = label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppTheme.primaryRose.withAlpha(15)
                        : AppTheme.bgStart,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel
                          ? AppTheme.primaryRose
                          : AppTheme.dividerColor,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(label,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: sel
                                ? AppTheme.primaryRose
                                : AppTheme.textDark,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, _selected),
              child: Text('Kaydet',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Yardım & Destek Sheet ────────────────────────────────────────────────────
class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title: 'Yardım & Destek',
      child: Column(
        children: [
          _HelpItem(
            icon: Icons.email_outlined,
            title: 'E-posta Desteği',
            subtitle: 'destek@stilya.app',
            onTap: () => _launch('mailto:destek@stilya.app?subject=Stilya%20Destek'),
          ),
          const SizedBox(height: 8),
          _HelpItem(
            icon: Icons.info_outline_rounded,
            title: 'Uygulama Hakkında',
            subtitle: 'Stilya v1.0.0 — AI Destekli Stil Asistanı',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Stilya',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2025 Stilya',
            ),
          ),
          const SizedBox(height: 8),
          _HelpItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik Politikası',
            subtitle: 'Verilerinin nasıl kullanıldığını öğren',
            onTap: () => _launch('https://stilya.app/privacy'),
          ),
          const SizedBox(height: 8),
          _HelpItem(
            icon: Icons.star_outline_rounded,
            title: 'Uygulamayı Değerlendir',
            subtitle: 'Google Play',
            onTap: () => _launch('https://play.google.com/store/apps/details?id=com.stilya.app'),
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              child: Icon(icon, size: 17, color: AppTheme.primaryRose),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.textLight)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textLight, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Ortak Sheet Çerçevesi ────────────────────────────────────────────────────
class _BaseSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _BaseSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(title,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Sheet İçindeki Tile ──────────────────────────────────────────────────────
class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              child:
                  Icon(icon, size: 18, color: AppTheme.primaryRose),
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

// ─── Bildirim Ayarları Sheet ──────────────────────────────────────────────────
class _NotificationSheet extends StatefulWidget {
  const _NotificationSheet();

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  bool _daily = false;
  bool _weekly = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await NotificationService().getPreferences();
    if (mounted) {
      setState(() {
        _daily = prefs['notif_daily'] ?? false;
        _weekly = prefs['notif_weekly'] ?? false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title: 'Bildirimler',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryRose))
          : Column(
              children: [
                _NotifToggle(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Günlük Hatırlatıcı',
                  subtitle: 'Her sabah 08:00\'de kombin önerisi',
                  value: _daily,
                  onChanged: (v) async {
                    setState(() => _daily = v);
                    await NotificationService()
                        .scheduleDailyReminder(v);
                  },
                ),
                const SizedBox(height: 12),
                _NotifToggle(
                  icon: Icons.calendar_month_outlined,
                  title: 'Haftalık Ajanda',
                  subtitle: 'Her Pazar 20:00\'de hafta planı hatırlatması',
                  value: _weekly,
                  onChanged: (v) async {
                    setState(() => _weekly = v);
                    await NotificationService()
                        .scheduleWeeklyReminder(v);
                  },
                ),
                const SizedBox(height: 16),
                if (_daily || _weekly)
                  TextButton(
                    onPressed: () async {
                      await NotificationService().cancelAll();
                      if (mounted) {
                        setState(() {
                          _daily = false;
                          _weekly = false;
                        });
                      }
                    },
                    child: Text(
                      'Tüm bildirimleri kapat',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppTheme.textLight),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value
            ? AppTheme.primaryRose.withAlpha(10)
            : AppTheme.bgStart,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              value ? AppTheme.primaryRose.withAlpha(80) : AppTheme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: value ? AppTheme.primaryRose.withAlpha(20) : AppTheme.lightRose,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 17,
                color: value ? AppTheme.primaryRose : AppTheme.textLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppTheme.textLight)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryRose,
            activeTrackColor: AppTheme.primaryRose.withAlpha(100),
          ),
        ],
      ),
    );
  }
}
