import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.displayName ?? auth.user?.email ?? 'Kullanıcı';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stilya'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merhaba, $name 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bugün nasıl bir stil yaratmak istersin?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 32),
              // Yakında gelecek özellik kartları
              _FeatureCard(
                icon: Icons.wb_sunny_outlined,
                title: 'Günün Kombini',
                subtitle: 'Hava ve moduna göre AI öneri',
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.casino_outlined,
                title: 'Zarları At',
                subtitle: 'Telefonu salla, sürpriz kombin keşfet',
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.recycling_outlined,
                title: 'Kör Nokta Analizi',
                subtitle: '30 gündür giymediğin kıyafetler',
                color: Theme.of(context).colorScheme.tertiaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
