import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../theme/app_theme.dart';
import '../history/history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final clothing = context.watch<ClothingProvider>();
    final outfits  = context.watch<OutfitProvider>();
    final name     = auth.user?.displayName ?? auth.user?.email ?? 'Kullanıcı';
    final email    = auth.user?.email ?? '';
    final initial  = name.isNotEmpty ? name[0].toUpperCase() : '?';

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
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(30),
                          border: Border.all(
                              color: Colors.white.withAlpha(150), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
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
