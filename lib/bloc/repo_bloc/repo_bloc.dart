import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vsdroid/utils/functions.dart';

part 'repo_event.dart';
part 'repo_state.dart';

class RepoStatusBloc extends Bloc<RepoStatusEvent, RepoStatusState> {
  RepoStatusBloc() : super(const RepoStatusInitial()) {
    on<LoadRepoStatus>(_onLoad);
    on<LoadCommitGraph>(_onLoadCommitGraph);
  }

  Future<void> _onLoad(LoadRepoStatus event, Emitter<RepoStatusState> emit) async {
    emit(const RepoStatusLoading());
    try {
      final res = await getRepoStatus(event.workspace);
      final stdout = (res.stdout ?? '').toString();
      final lines = stdout.trimRight().isEmpty ? <String>[] : stdout.trimRight().split('\n');

      final staged = lines.where((val) {
        if (val.length < 2) return false;
        final x = val[0];
        return x != ' ' && x != '?';
      }).toList();

      final unstaged = lines.where((val) {
        if (val.length < 2) return false;
        final y = val[1];
        return y != ' ';
      }).toList();
      emit(RepoStatusLoaded(staged: staged, unstaged: unstaged, rawOutput: stdout));
    } catch (e) {
      emit(RepoStatusError(message: e.toString()));
    }
  }

  Future<void> _onLoadCommitGraph(LoadCommitGraph event, Emitter<RepoStatusState> emit) async {
    final currentState = state;
    if (currentState is RepoStatusLoaded) {
      emit(RepoStatusLoaded(
        staged: currentState.staged,
        unstaged: currentState.unstaged,
        rawOutput: currentState.rawOutput,
        commits: null, 
      ));
    } else {
      emit(const RepoStatusLoading());
    }

    try {
      final commits = await getGraph(event.workspace);
      if (state is RepoStatusLoaded) {
        final currentState = state as RepoStatusLoaded;
        emit(RepoStatusLoaded(
          staged: currentState.staged,
          unstaged: currentState.unstaged,
          rawOutput: currentState.rawOutput,
          commits: commits,
        ));
      } else {
        emit(RepoStatusLoaded(
          staged: [],
          unstaged: [],
          rawOutput: '',
          commits: commits,
        ));
      }
    } catch (e) {
      if (state is RepoStatusLoaded) {
        final currentState = state as RepoStatusLoaded;
        emit(RepoStatusLoaded(
          staged: currentState.staged,
          unstaged: currentState.unstaged,
          rawOutput: currentState.rawOutput,
          commits: [],
        ));
      } else {
        emit(RepoStatusError(message: e.toString()));
      }
    }
  }
}