import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure([this.message = 'Terjadi kesalahan tak terduga']);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class GenerativeAIFailure extends Failure {
  const GenerativeAIFailure(super.message);
}
