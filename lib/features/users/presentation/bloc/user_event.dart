import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object> get props => [];
}

class SearchUsers extends UserEvent {
  final String query;
  const SearchUsers(this.query);
  @override
  List<Object> get props => [query];
}
