import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/screens/login_screen.dart';
import '../providers/ecommerce_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_image_placeholder.dart';
import '../widgets/product_section.dart';
import 'bag_screen.dart';
import 'product_management_screen.dart';
import 'transactions_screen.dart';

class EcommerceHomeScreen extends ConsumerWidget {
  const EcommerceHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeProductsAsync = ref.watch(homeProductsProvider);
    final carouselIndex = ref.watch(homeCarouselIndexProvider);
    final bottomIndex = ref.watch(selectedBottomNavIndexProvider);
    final bannersAsync = ref.watch(bannersProvider);

    return Scaffold(
      backgroundColor: Colors.white,

      body: bottomIndex == 2
          ? const TransactionsScreen()
          : bottomIndex == 3
          ? const _ProfileSection()
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _HomeHeader(),
                    const SizedBox(height: 12),

                    // Banner principal
                    SizedBox(
                      height: 150,
                      child: bannersAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (urls) => PageView.builder(
                          itemCount: urls.length,
                          onPageChanged: (index) {
                            ref.read(homeCarouselIndexProvider.notifier).state =
                                index;
                          },
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  urls[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  loadingBuilder: (_, child, progress) =>
                                      progress == null
                                      ? child
                                      : const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Puntitos del carrusel
                    bannersAsync.maybeWhen(
                      data: (urls) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(urls.length, (index) {
                          final isActive = carouselIndex == index;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 6,
                            width: isActive ? 8 : 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF0A7CFF)
                                  : const Color(0xFFD6E5F7),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    homeProductsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Error al cargar productos: $e',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      data: (homeProducts) => Column(
                        children: [
                          ProductSection(
                            title: 'Perfect for you',
                            products: homeProducts.recommended,
                          ),
                          const SizedBox(height: 18),
                          ProductSection(
                            title: 'For this summer',
                            products: homeProducts.summer,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0A7CFF),
        unselectedItemColor: const Color(0xFFC7CDD6),
        onTap: (index) {
          ref.read(selectedBottomNavIndexProvider.notifier).state = index;
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          const Icon(Icons.search, size: 26),
          const Spacer(),
          const Icon(Icons.favorite_border, size: 26),
          const SizedBox(width: 18),

          // Bolsa con contador
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BagScreen()),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 26),
                if (cartCount > 0)
                  Positioned(
                    right: -6,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0A7CFF),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sección de perfil ────────────────────────────────────────────────────────

class _ProfileSection extends ConsumerWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + nombre ──────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFD6E5F7),
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A7CFF),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ── Opciones ─────────────────────────────────────────────────────
            if (user?.isAdmin == true) ...[
              _ProfileOption(
                icon: Icons.inventory_2_outlined,
                label: 'Administrar productos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductManagementScreen(),
                  ),
                ),
              ),
              const Divider(height: 1),
            ],

            _ProfileOption(
              icon: Icons.logout,
              label: 'Cerrar sesión',
              color: Colors.red,
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                ref.read(selectedBottomNavIndexProvider.notifier).state = 0;
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF1C1C1E);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: effectiveColor),
      title: Text(
        label,
        style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w500),
      ),
      trailing: color == null
          ? const Icon(Icons.chevron_right, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
}
