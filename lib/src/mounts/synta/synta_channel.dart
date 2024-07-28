import 'package:meta/meta.dart';

@immutable
final class SyntaChannel {
  const SyntaChannel._(this._);

  final String _;

  static const one = SyntaChannel._('1');
  static const two = SyntaChannel._('2');
  static const both = SyntaChannel._('3');

  @override
  String toString() => _;
}
