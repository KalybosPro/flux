// **************************************************************************
// Flugx GetX API Generator - File Upload/Download Support
// **************************************************************************

// ignore_for_file: unnecessary_null_comparison

import 'dart:io' as io;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Type de fichier supporté
enum FileType {
  image,
  document,
  video,
  audio,
  archive,
  custom,
}

/// Configuration d'upload
class UploadConfig {
  final int maxFileSize;
  final List<String> allowedExtensions;
  final List<String> allowedMimeTypes;
  final bool enableCompression;
  final int maxConcurrentUploads;
  final Duration timeout;
  final Map<String, String>? additionalHeaders;

  const UploadConfig({
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.allowedExtensions = const [],
    this.allowedMimeTypes = const [],
    this.enableCompression = false,
    this.maxConcurrentUploads = 3,
    this.timeout = const Duration(minutes: 5),
    this.additionalHeaders,
  });
}

/// Configuration de téléchargement
class DownloadConfig {
  final String downloadDirectory;
  final bool enableResume;
  final int chunkSize;
  final Duration timeout;
  final Map<String, String>? additionalHeaders;

  const DownloadConfig({
    this.downloadDirectory = 'downloads',
    this.enableResume = true,
    this.chunkSize = 1024 * 1024, // 1MB
    this.timeout = const Duration(minutes: 10),
    this.additionalHeaders,
  });
}

/// Requête d'upload
class UploadRequest {
  final String filePath;
  final String uploadUrl;
  final String fieldName;
  final Map<String, String>? formData;
  final Map<String, String>? headers;
  final FileType fileType;

  UploadRequest({
    required this.filePath,
    required this.uploadUrl,
    this.fieldName = 'file',
    this.formData,
    this.headers,
    this.fileType = FileType.custom,
  });
}

/// Statut d'upload/téléchargement
enum TransferStatus {
  pending,
  uploading,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// État de transfert
class TransferState {
  final String id;
  final TransferStatus status;
  final double progress;
  final int bytesTransferred;
  final int totalBytes;
  final String? error;
  final DateTime startTime;
  final DateTime? endTime;

  TransferState({
    required this.id,
    this.status = TransferStatus.pending,
    this.progress = 0.0,
    this.bytesTransferred = 0,
    this.totalBytes = 0,
    this.error,
    DateTime? startTime,
    this.endTime,
  }) : this.startTime = startTime ?? DateTime.now();

  /// Met à jour l'état
  TransferState copyWith({
    TransferStatus? status,
    double? progress,
    int? bytesTransferred,
    int? totalBytes,
    String? error,
    DateTime? endTime,
  }) {
    return TransferState(
      id: id,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error ?? this.error,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  /// Calcule la vitesse en bytes/seconde
  double getSpeed() {
    if (endTime == null || startTime == null) return 0.0;
    final duration = endTime!.difference(startTime).inSeconds;
    return duration > 0 ? bytesTransferred / duration : 0.0;
  }
}

/// Gestionnaire de fichiers
class FileManager {
  final UploadConfig uploadConfig;
  final DownloadConfig downloadConfig;

  final Map<String, TransferState> _transfers = {};

  FileManager({
    required this.uploadConfig,
    required this.downloadConfig,
  });

  /// Upload un fichier
  Future<String?> uploadFile(UploadRequest request) async {
    final file = io.File(request.filePath);
    if (!await file.exists()) {
      throw Exception('File not found: ${request.filePath}');
    }

    // Validation
    await _validateFile(file, request.fileType);

    final transferId = _generateTransferId();
    _transfers[transferId] = TransferState(id: transferId);

    try {
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();

      final multipartRequest = http.MultipartRequest('POST', Uri.parse(request.uploadUrl));

      // Ajout des headers
      if (request.headers != null) {
        multipartRequest.headers.addAll(request.headers!);
      }
      if (uploadConfig.additionalHeaders != null) {
        multipartRequest.headers.addAll(uploadConfig.additionalHeaders!);
      }

      // Ajout du fichier
      final multipartFile = http.MultipartFile(
        request.fieldName,
        stream,
        length,
        filename: path.basename(file.path),
      );
      multipartRequest.files.add(multipartFile);

      // Ajout des données de formulaire
      if (request.formData != null) {
        request.formData!.forEach((key, value) {
          multipartRequest.fields[key] = value;
        });
      }

      // Mise à jour du statut
      _transfers[transferId] = _transfers[transferId]!.copyWith(
        status: TransferStatus.uploading,
        totalBytes: length,
      );

      // Envoi de la requête
      final streamedResponse = await multipartRequest.send().timeout(uploadConfig.timeout);

      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        final responseBody = await streamedResponse.stream.bytesToString();
        _transfers[transferId] = _transfers[transferId]!.copyWith(
          status: TransferStatus.completed,
          progress: 1.0,
          bytesTransferred: length,
          endTime: DateTime.now(),
        );
        return responseBody;
      } else {
        throw http.ClientException(
          'Upload failed: ${streamedResponse.statusCode}',
          Uri.parse(request.uploadUrl),
        );
      }
    } catch (e) {
      _transfers[transferId] = _transfers[transferId]!.copyWith(
        status: TransferStatus.failed,
        error: e.toString(),
        endTime: DateTime.now(),
      );
      rethrow;
    }
  }

  /// Télécharge un fichier
  Future<String?> downloadFile(String url, String filename, {
    Map<String, String>? headers,
    void Function(double)? onProgress,
    bool enableResume = true,
  }) async {
    final transferId = _generateTransferId();
    _transfers[transferId] = TransferState(id: transferId);

    try {
      final uri = Uri.parse(url);
      final client = http.Client();

      final requestHeaders = {
        ...?headers,
        ...?downloadConfig.additionalHeaders,
      };

      // Vérifie si on peut reprendre le téléchargement
      String localPath = path.join(downloadConfig.downloadDirectory, filename);
      io.File? existingFile;
      int startByte = 0;

      if (enableResume && downloadConfig.enableResume) {
        existingFile = io.File(localPath);
        if (await existingFile.exists()) {
          startByte = await existingFile.length();
          requestHeaders['Range'] = 'bytes=$startByte-';
        }
      }

      final request = http.Request('GET', uri)..headers.addAll(requestHeaders);
      final response = await client.send(request).timeout(downloadConfig.timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw http.ClientException(
          'Download failed: ${response.statusCode}',
          uri,
        );
      }

      final contentLength = response.contentLength ?? 0;
      final totalBytes = contentLength + startByte;

      _transfers[transferId] = _transfers[transferId]!.copyWith(
        status: TransferStatus.downloading,
        totalBytes: totalBytes,
        bytesTransferred: startByte,
      );

      final file = existingFile ?? io.File(localPath);
      await file.parent.create(recursive: true);

      final sink = file.openWrite(mode: startByte > 0 ? io.FileMode.append : io.FileMode.write);
      int receivedBytes = startByte;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        final progress = totalBytes > 0 ? receivedBytes / totalBytes : 0.0;
        _transfers[transferId] = _transfers[transferId]!.copyWith(
          progress: progress,
          bytesTransferred: receivedBytes,
        );

        onProgress?.call(progress);
      }

      await sink.close();
      client.close();

      _transfers[transferId] = _transfers[transferId]!.copyWith(
        status: TransferStatus.completed,
        progress: 1.0,
        endTime: DateTime.now(),
      );

      return localPath;

    } catch (e) {
      _transfers[transferId] = _transfers[transferId]!.copyWith(
        status: TransferStatus.failed,
        error: e.toString(),
        endTime: DateTime.now(),
      );
      rethrow;
    }
  }

  /// Télécharge avec support du streaming/chunking
  Future<String?> downloadFileChunked(String url, String filename, {
    Map<String, String>? headers,
    void Function(double)? onProgress,
    int? chunkSize,
  }) async {
    final effectiveChunkSize = chunkSize ?? downloadConfig.chunkSize;
    final transferId = _generateTransferId();
    _transfers[transferId] = TransferState(id: transferId);

    try {
      final uri = Uri.parse(url);
      final client = http.Client();

      // D'abord, récupère la taille du fichier
      final headRequest = http.Request('HEAD', uri);
      if (headers != null) headRequest.headers.addAll(headers);
      if (downloadConfig.additionalHeaders != null) {
        headRequest.headers.addAll(downloadConfig.additionalHeaders!);
      }

      final headResponse = await client.send(headRequest);
      final contentLength = int.tryParse(
        headResponse.headers['content-length'] ?? '0'
      ) ?? 0;

      _transfers[transferId] = _transfers[transferId]!.copyWith(
        status: TransferStatus.downloading,
        totalBytes: contentLength,
      );

      final localPath = path.join(downloadConfig.downloadDirectory, filename);
      final file = io.File(localPath);
      await file.parent.create(recursive: true);

      final sink = file.openWrite();

      int downloadedBytes = 0;

      // Télécharge par chunks
      while (downloadedBytes < contentLength) {
        final endByte = (downloadedBytes + effectiveChunkSize - 1).clamp(0, contentLength - 1);

        final rangeRequest = http.Request('GET', uri);
        rangeRequest.headers.addAll({
          ...?headers,
          ...?downloadConfig.additionalHeaders,
          'Range': 'bytes=$downloadedBytes-$endByte',
        });

        final response = await client.send(rangeRequest);

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw http.ClientException(
            'Chunk download failed: ${response.statusCode}',
            uri,
          );
        }

        final chunk = await response.stream.fold<Uint8List>(
          Uint8List(0),
          (previous, element) => Uint8List.fromList([...previous, ...element]),
        );

        sink.add(chunk);
        downloadedBytes += chunk.length;

        final progress = contentLength > 0 ? downloadedBytes / contentLength : 0.0;
        _transfers[transferId] = _transfers[transferId]!.copyWith(
          progress: progress,
          bytesTransferred: downloadedBytes,
        );

        onProgress?.call(progress);
      }

      await sink.close();
      client.close();

      _transfers[transferId] = _transfers[transferId]!.copyWith(
        status: TransferStatus.completed,
        progress: 1.0,
        endTime: DateTime.now(),
      );

      return localPath;

    } catch (e) {
      _transfers[transferId] = _transfers[transferId]!.copyWith(
        status: TransferStatus.failed,
        error: e.toString(),
        endTime: DateTime.now(),
      );
      rethrow;
    }
  }

  /// Obtient l'état d'un transfert
  TransferState? getTransferState(String transferId) {
    return _transfers[transferId];
  }

  /// Annule un transfert
  void cancelTransfer(String transferId) {
    final state = _transfers[transferId];
    if (state != null && state.status != TransferStatus.completed) {
      _transfers[transferId] = state.copyWith(
        status: TransferStatus.cancelled,
        endTime: DateTime.now(),
      );
    }
  }

  /// Valide un fichier avant upload
  Future<void> _validateFile(io.File file, FileType fileType) async {
    final stat = await file.stat();
    final fileSize = stat.size;

    // Vérification de la taille
    if (fileSize > uploadConfig.maxFileSize) {
      throw ArgumentError('File size exceeds maximum allowed size');
    }

    // Validation des extensions
    if (uploadConfig.allowedExtensions.isNotEmpty) {
      final extension = path.extension(file.path).toLowerCase().substring(1);
      if (!uploadConfig.allowedExtensions.contains(extension)) {
        throw ArgumentError('File extension not allowed: $extension');
      }
    }

    // Validation des types MIME (si disponible)
    if (uploadConfig.allowedMimeTypes.isNotEmpty) {
      // Note: Dans un environnement Flutter, on utiliserait une vraie validation MIME
      final mimeType = _guessMimeType(file.path);
      if (!uploadConfig.allowedMimeTypes.contains(mimeType)) {
        throw ArgumentError('MIME type not allowed: $mimeType');
      }
    }
  }

  /// Devine le type MIME à partir de l'extension
  String _guessMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.zip':
        return 'application/zip';
      case '.txt':
        return 'text/plain';
      case '.json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  String _generateTransferId() {
    return 'transfer_${DateTime.now().millisecondsSinceEpoch}_${_transfers.length}';
  }

  /// Nettoie les transferts terminés
  void cleanupCompletedTransfers({Duration? maxAge}) {
    final cutoff = DateTime.now().subtract(maxAge ?? const Duration(hours: 1));

    _transfers.removeWhere((id, state) {
      return state.status == TransferStatus.completed &&
             state.endTime != null &&
             state.endTime!.isBefore(cutoff);
    });
  }
}
