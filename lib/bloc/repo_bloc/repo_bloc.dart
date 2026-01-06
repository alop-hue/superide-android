import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vsdroid/utils/functions.dart';

part 'repo_event.dart';
part 'repo_state.dart';

class RepoStatusBloc extends Bloc<RepoStatusEvent, RepoStatusState> {
  RepoStatusBloc() : super(const RepoStatusInitial()) {
    on<LoadRepoStatus>(_onLoad);
    on<LoadCommitGraph>(_onLoadCommitGraph);
    on<LoadGitExtendedStatus>(_onLoadExtendedStatus);
    on<RefreshRemoteStatus>(_onRefreshRemoteStatus);
  }

  Future<void> _onLoad(
    LoadRepoStatus event,
    Emitter<RepoStatusState> emit,
  ) async {
    emit(const RepoStatusLoading());
    try {
      final res = await getRepoStatus(event.workspace);
      final stdout = (res.stdout ?? '').toString();
      final lines = stdout.trimRight().isEmpty
          ? <String>[]
          : stdout.trimRight().split('\n');

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

      final currentBranch = await gitCurrentBranch(event.workspace);
      final branches = await gitListBranches(event.workspace);
      final remoteBranches = await gitListBranches(
        event.workspace,
        remote: true,
      );
      final stashes = await gitListStashes(event.workspace);
      final tags = await gitListTags(event.workspace);
      final remotes = await gitListRemotes(event.workspace);
      final hasRemoteVal = remotes.isNotEmpty;
      final hasUpstreamVal = await hasUpstream(event.workspace);
      final unpushed = hasUpstreamVal
          ? await getUnpushedCommitCount(event.workspace)
          : 0;

      emit(
        RepoStatusLoaded(
          staged: staged,
          unstaged: unstaged,
          rawOutput: stdout,
          currentBranch: currentBranch,
          branches: branches,
          remoteBranches: remoteBranches,
          stashes: stashes,
          tags: tags,
          remotes: remotes,
          hasRemote: hasRemoteVal,
          hasUpstream: hasUpstreamVal,
          unpushedCount: unpushed,
        ),
      );
    } catch (e) {
      emit(RepoStatusError(message: e.toString()));
    }
  }

  Future<void> _onLoadCommitGraph(
    LoadCommitGraph event,
    Emitter<RepoStatusState> emit,
  ) async {
    final currentState = state;
    if (currentState is RepoStatusLoaded) {
      emit(currentState.copyWith(commits: null));
    } else {
      emit(const RepoStatusLoading());
    }

    try {
      final commits = await getGraph(event.workspace);
      if (state is RepoStatusLoaded) {
        final currentState = state as RepoStatusLoaded;
        emit(currentState.copyWith(commits: commits));
      } else {
        emit(
          RepoStatusLoaded(
            staged: [],
            unstaged: [],
            rawOutput: '',
            commits: commits,
          ),
        );
      }
    } catch (e) {
      if (state is RepoStatusLoaded) {
        final currentState = state as RepoStatusLoaded;
        emit(currentState.copyWith(commits: []));
      } else {
        emit(RepoStatusError(message: e.toString()));
      }
    }
  }

  Future<void> _onLoadExtendedStatus(
    LoadGitExtendedStatus event,
    Emitter<RepoStatusState> emit,
  ) async {
    try {
      final currentBranch = await gitCurrentBranch(event.workspace);
      final branches = await gitListBranches(event.workspace);
      final remoteBranches = await gitListBranches(
        event.workspace,
        remote: true,
      );
      final stashes = await gitListStashes(event.workspace);
      final tags = await gitListTags(event.workspace);
      final remotes = await gitListRemotes(event.workspace);
      final hasRemoteVal = remotes.isNotEmpty;
      final hasUpstreamVal = await hasUpstream(event.workspace);
      final unpushed = hasUpstreamVal
          ? await getUnpushedCommitCount(event.workspace)
          : 0;

      if (state is RepoStatusLoaded) {
        final currentState = state as RepoStatusLoaded;
        emit(
          currentState.copyWith(
            currentBranch: currentBranch,
            branches: branches,
            remoteBranches: remoteBranches,
            stashes: stashes,
            tags: tags,
            remotes: remotes,
            hasRemote: hasRemoteVal,
            hasUpstream: hasUpstreamVal,
            unpushedCount: unpushed,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _onRefreshRemoteStatus(
    RefreshRemoteStatus event,
    Emitter<RepoStatusState> emit,
  ) async {
    try {
      final hasUpstreamVal = await hasUpstream(event.workspace);
      final unpushed = hasUpstreamVal
          ? await getUnpushedCommitCount(event.workspace)
          : 0;
      final remotes = await gitListRemotes(event.workspace);
      final hasRemoteVal = remotes.isNotEmpty;

      if (state is RepoStatusLoaded) {
        final currentState = state as RepoStatusLoaded;
        emit(
          currentState.copyWith(
            hasRemote: hasRemoteVal,
            hasUpstream: hasUpstreamVal,
            unpushedCount: unpushed,
            remotes: remotes,
          ),
        );
      }
    } catch (_) {}
  }
}

class GithubAuthCubit extends Cubit<bool> {
  GithubAuthCubit() : super(false) {
    refresh();
  }

  Future<void> refresh() async {
    final token = await const FlutterSecureStorage().read(
      key: 'github_access_token',
    );
    emit(token != null && token.isNotEmpty);
  }

  Future<void> logout() async {
    await const FlutterSecureStorage().delete(key: 'github_access_token');
    emit(false);
  }
}
