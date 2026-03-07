// features/profile/data/profile_datasource.dart
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/services/api_service.dart';

class ProfileDatasource {
  ProfileDatasource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    try {
      final res = await _dio.get(ApiEndpoints.userPublicProfile(userId));
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> updatePhoto(String userId, String fotoUrl) async {
    try {
      await _dio.put(
        ApiEndpoints.userPhoto(userId),
        data: {'fotoUrl': fotoUrl},
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> updateSocialLinks(
      String userId, Map<String, String> links) async {
    try {
      await _dio.put(
        ApiEndpoints.userSocialLinks(userId),
        data: links,
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Sube un archivo al storage y devuelve la URL pública.
  Future<String> uploadFile({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
      });
      final res = await _dio.post(
        ApiEndpoints.storageUpload,
        data: formData,
      );
      final data = res.data as Map<String, dynamic>;
      return data['url'] as String? ?? data['fileUrl'] as String? ?? '';
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
