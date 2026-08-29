import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/image_storage_datasource.dart';
import '../../data/datasources/product_firestore_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/get_home_products_usecase.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final storageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final imageStorageDatasourceProvider = Provider<ImageStorageDatasource>((ref) {
  return ImageStorageDatasource(ref.watch(storageProvider));
});

final productDatasourceProvider = Provider<ProductFirestoreDatasource>((ref) {
  return ProductFirestoreDatasource(ref.watch(firestoreProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(productDatasourceProvider));
});

final getHomeProductsUseCaseProvider = Provider<GetHomeProductsUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetHomeProductsUseCase(repository);
});

final homeProductsProvider = StreamProvider<HomeProducts>((ref) {
  final useCase = ref.watch(getHomeProductsUseCaseProvider);
  return useCase.callAsStream();
});

final homeCarouselIndexProvider = StateProvider<int>((ref) => 0);

final selectedBottomNavIndexProvider = StateProvider<int>((ref) => 0);

final bannersProvider = FutureProvider<List<String>>((ref) async {
  final storage = ref.read(storageProvider);
  const banners = ['banner1.jpg', 'banner2.jpg', 'banner3.jpg'];
  return Future.wait(
    banners.map((name) => storage.ref('products/$name').getDownloadURL()),
  );
});
