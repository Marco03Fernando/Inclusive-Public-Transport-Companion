import 'package:image_picker/image_picker.dart';

/// Where the user chose to source the photo from.
enum PhotoSource { camera, gallery }

/// Thin wrapper around `image_picker` for taking a photo with the camera
/// or choosing one from the gallery.
class PhotoService {
  final ImagePicker _picker;

  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Returns the picked file's on-device path, or null if the user
  /// cancelled the picker. Throws a [PhotoServiceException] with a
  /// friendly message on failure (e.g. permission denied).
  Future<String?> pickPhoto(PhotoSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      return xFile?.path;
    } catch (_) {
      throw PhotoServiceException(
        source == PhotoSource.camera
            ? 'Could not open the camera. Check camera permissions and try again.'
            : 'Could not open the gallery. Check photo permissions and try again.',
      );
    }
  }
}

class PhotoServiceException implements Exception {
  final String message;
  PhotoServiceException(this.message);

  @override
  String toString() => message;
}
