import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _st = FirebaseStorage.instance;

  Future<String> uploadBytes({
    required Uint8List bytes,
    required String path,
    String? contentType,
  }) async {
    final ref = _st.ref().child(path);
    final meta = SettableMetadata(contentType: contentType);
    await ref.putData(bytes, meta);
    return await ref.getDownloadURL();
  }

  Future<void> deleteByUrl(String url) async {
    await _st.refFromURL(url).delete();
  }
}
