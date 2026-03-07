// features/profile/data/profile_remote_datasource.dart — Datasource de perfil
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/services/api_service.dart';

final profileRemoteDatasourceProvider = Provider<ProfileRemoteDatasource>(
  (ref) => ProfileRemoteDatasource(ref.watch(dioProvider)),
);

class ProfileRemoteDatasource {
  ProfileRemoteDatasource(this._dio);

  final Dio _dio;

  /// Sube una imagen al storage de Supabase y retorna la URL pública.
  Future<String> uploadImage(XFile file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    final response = await _dio.post(
      '${ApiEndpoints.storageUpload}?folder=avatars',
      data: formData,
    );
    return response.data['url'] as String;
  }

  /// Actualiza la foto de perfil del usuario en el backend.
  Future<void> updatePhoto(String uid, String photoUrl) async {
    await _dio.put(
      ApiEndpoints.userPhoto(uid),
      data: {'fotoUrl': photoUrl},
    );
  }

  /// Actualiza las redes sociales del usuario en el backend.
  /// [links] puede contener claves: 'linkedin', 'github', 'website'.
  Future<void> updateSocial(String uid, Map<String, String> links) async {
    await _dio.put(
      ApiEndpoints.userSocialLinks(uid),
      data: {'redesSociales': links},
    );
  }
}
