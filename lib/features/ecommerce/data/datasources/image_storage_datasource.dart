import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageStorageDatasource {
  final FirebaseStorage _storage;
  static const _folder = 'products';

  ImageStorageDatasource(this._storage);

  /// Sube [xfile] a Storage y retorna la URL de descarga pública.
  /// Usa XFile para compatibilidad con web y móvil.
  Future<String> uploadProductImage({
    required XFile xfile,
    required String productId,
  }) async {
    final ext = xfile.name.split('.').last;
    final ref = _storage.ref('$_folder/$productId.$ext');
    final bytes = await xfile.readAsBytes();
    await ref.putData(bytes, SettableMetadata(contentType: xfile.mimeType));
    return ref.getDownloadURL();
  }

  /// Elimina la imagen de un producto si existe en Storage.
  Future<void> deleteProductImage(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } catch (_) {
      // Ignora si la imagen no existe en Storage
    }
  }
}
