class TaskItem {
  String imageUrl;
  String remark;
  bool isUploading;
  TaskItem({
    required this.imageUrl,
    required this.remark,
    this.isUploading = false
  });

  Map<String, dynamic> toMap() => {
    'imageUrl': imageUrl,
    'remark': remark,

  };

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      imageUrl: map['imageUrl'],
      remark: map['remark'],
    );
  }
}
