import 'package:image_picker/image_picker.dart';

class PhotoService {
  final _picker = ImagePicker();

  /// Opens the camera and returns the captured image path, or null if cancelled.
  Future<String?> capturePhoto() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    return file?.path;
  }

  /// Opens the gallery and returns the picked image path, or null if cancelled.
  Future<String?> pickFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    return file?.path;
  }
}
