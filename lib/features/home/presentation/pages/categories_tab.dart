import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/pexels_provider.dart';
import '../../../../features/home/presentation/pages/category_wallpapers_page.dart';
import '../../../../core/services/pexels_api_service.dart';
import '../../../../core/providers/firestore_wallpaper_provider.dart';
import '../../../../core/services/firestore_service.dart';

class CategoriesTab extends ConsumerStatefulWidget {
  const CategoriesTab({super.key});

  @override
  ConsumerState<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends ConsumerState<CategoriesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Map<String, Future<String?>> _imageFutures = {};
  final Map<String, Future<String?>> _firebaseCategoryImageFutures = {};

  Future<String?> _getDailyCategoryImage(String categoryName, String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = 'category_bg_${categoryId}_${today.year}${today.month}${today.day}';
    final cachedUrl = prefs.getString(key);
    if (cachedUrl != null) return cachedUrl;
    final api = PexelsApiService();
    final url = await api.fetchDailyCategoryImageUrl(category: categoryName, date: today);
    if (url != null) {
      await prefs.setString(key, url);
    }
    return url;
  }

  Future<String?> _getFirebaseCategoryWallpaperUrl(String categoryId) async {
    // Fetch one wallpaper for this Firebase category
    final wallpapers = await FirestoreService().getWallpapersByCategory(categoryId, limit: 1);
    if (wallpapers.isNotEmpty) {
      return wallpapers.first.originalUrl ?? wallpapers.first.imageUrl ?? wallpapers.first.thumbnailUrl;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final theme = Theme.of(context);
    final pexelsCategoriesState = ref.watch(pexelsCategoriesProvider);
    final firestoreCategoriesState = ref.watch(firestoreCategoriesProvider);

    // Debug prints
    print('Firestore state: ' + firestoreCategoriesState.toString());
    print('Firestore value: ' + firestoreCategoriesState.value.toString());
    print('Firestore error: ' + firestoreCategoriesState.error.toString());
    print('Pexels state: ' + pexelsCategoriesState.toString());
    print('Pexels value: ' + pexelsCategoriesState.categories.toString());
    print('Pexels error: ' + pexelsCategoriesState.error.toString());

    if (pexelsCategoriesState.isLoading || firestoreCategoriesState.isLoading) {
      return Container(
        color: theme.scaffoldBackgroundColor,
        child: const CategorySkeletonLoader(),
      );
    }
    
    if (pexelsCategoriesState.error != null || firestoreCategoriesState.error != null) {
      return Container(
        color: theme.scaffoldBackgroundColor,
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Text("Error: \\${pexelsCategoriesState.error ?? firestoreCategoriesState.error}"),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () {
                  ref.read(pexelsCategoriesProvider.notifier).loadCategories();
                  ref.read(firestoreCategoriesProvider.notifier).loadCategories();
                },
              child: const Text("Retry"),
            ),
          ],
          ),
        ),
      );
    }
    
    final pexelsCategories = pexelsCategoriesState.categories;
    final firestoreCategories = firestoreCategoriesState.value ?? [];

    // Combine both category lists
    final allCategories = [...firestoreCategories, ...pexelsCategories];

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: ListView.builder(
        itemCount: allCategories.length,
      itemBuilder: (context, index) {
          final category = allCategories[index];
          final isFirebaseCategory = index < firestoreCategories.length;
        // Use a memoized future per category per day
          if (isFirebaseCategory) {
            _firebaseCategoryImageFutures[category.id] ??= _getFirebaseCategoryWallpaperUrl(category.id);
          } else {
        _imageFutures[category.id] ??= _getDailyCategoryImage(category.name, category.id);
          }
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => CategoryWallpapersPage(
                      category: category,
                      isFirebaseCategory: isFirebaseCategory,
                    ),
                ),
              );
            },
            child: Stack(
              children: [
                  isFirebaseCategory
                    ? FutureBuilder<String?>(
                        future: _firebaseCategoryImageFutures[category.id],
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: Colors.grey[700]!,
                              child: Container(
                                height: MediaQuery.of(context).size.height * 0.2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.grey[800],
                                ),
                              ),
                            );
                          }
                          final imageUrl = snapshot.data;
                          if (imageUrl == null) {
                            // fallback to gradient if no image
                            return Container(
                              height: MediaQuery.of(context).size.height * 0.2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(int.parse(category.color.replaceFirst('#', '0xff'))),
                                    Color(int.parse(category.color.replaceFirst('#', '0xff'))).withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            );
                          }
                          return CachedNetworkImage(
                            imageUrl: imageUrl,
                            imageBuilder: (context, imageProvider) => Container(
                              height: MediaQuery.of(context).size.height * 0.2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: Colors.grey[700]!,
                              child: Container(
                                height: MediaQuery.of(context).size.height * 0.2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: MediaQuery.of(context).size.height * 0.2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey[900],
                              ),
                              child: const Icon(Icons.broken_image, color: Colors.white),
                            ),
                            fadeInDuration: const Duration(milliseconds: 400),
                          );
                        },
                      )
                    : FutureBuilder<String?>(
                  future: _imageFutures[category.id],
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey[800]!,
                        highlightColor: Colors.grey[700]!,
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.grey[800],
                          ),
                        ),
                      );
                    }
                    final imageUrl = snapshot.data;
                    if (imageUrl == null) {
                      // fallback to gradient if no image
                      return Container(
                        height: MediaQuery.of(context).size.height * 0.2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Color(int.parse(category.color.replaceFirst('#', '0xff'))),
                              Color(int.parse(category.color.replaceFirst('#', '0xff'))).withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      );
                    }
                    return CachedNetworkImage(
                      imageUrl: imageUrl,
                      imageBuilder: (context, imageProvider) => Container(
                        height: MediaQuery.of(context).size.height * 0.2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[800]!,
                        highlightColor: Colors.grey[700]!,
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: MediaQuery.of(context).size.height * 0.2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.grey[900],
                        ),
                        child: const Icon(Icons.broken_image, color: Colors.white),
                      ),
                      fadeInDuration: const Duration(milliseconds: 400),
                    );
                  },
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.2,
                  width: MediaQuery.of(context).size.width * 0.7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  height: MediaQuery.of(context).size.height * 0.2,
                  child: Center(
                    child: Text(
                      category.name.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Raleway',
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CategorySkeletonLoader extends StatelessWidget {
  const CategorySkeletonLoader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Shimmer.fromColors(
            baseColor: theme.cardColor,
            highlightColor: theme.colorScheme.surface,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: theme.cardColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
