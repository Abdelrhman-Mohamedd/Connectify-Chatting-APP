import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_messaging_app/features/users/domain/usecases/search_users_usecase.dart';
import 'package:flutter_messaging_app/features/users/presentation/bloc/user_event.dart';
import 'package:flutter_messaging_app/features/users/presentation/bloc/user_state.dart';
import 'package:rxdart/rxdart.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final SearchUsersUseCase searchUsersUseCase;

  UserBloc({required this.searchUsersUseCase}) : super(UserInitial()) {
    on<SearchUsers>(_onSearchUsers, transformer: (events, mapper) {
      return events.debounceTime(const Duration(milliseconds: 300)).asyncExpand(mapper);
    });
  }

  Future<void> _onSearchUsers(SearchUsers event, Emitter<UserState> emit) async {
    if (event.query.isEmpty) {
      emit(UserInitial());
      return;
    }
    emit(UserLoading());
    final result = await searchUsersUseCase(event.query);
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (users) => emit(UserLoaded(users)),
    );
  }
}
