
import 'package:image_picker/image_picker.dart';

class ImageGroup {
  List<XFile> images;
  String remark;

  ImageGroup({required this.images, this.remark = ""});
}
