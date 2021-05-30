class FirestoreData {
  final double dx;
  final double dy;
  final String color;
  final double strokeWidth;

  FirestoreData({this.dx, this.dy, this.color, this.strokeWidth});

  FirestoreData.fromJson(Map<String, Object> json)
      : this(
            dx: json['dx'] as double,
            dy: json['dy'] as double,
            color: json['color'] as String,
            strokeWidth: json['width'] as double);

  Map<String, Object> toJson() {
    return {'dx': dx, 'dy': dy, 'color': color, 'width': strokeWidth};
  }
}
