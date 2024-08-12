class Size<T extends num> {
  Size(this.width, this.height);

  factory Size.square(T dimension) => Size(dimension, dimension);

  final T width;
  final T height;

  Size operator -(covariant Size other) =>
      Size(width - other.width, height - other.height);
}
