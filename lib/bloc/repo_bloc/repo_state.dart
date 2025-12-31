part of 'repo_bloc.dart';

abstract class RepoStatusState extends Equatable {
  const RepoStatusState();
  @override List<Object?> get props => [];
}

class RepoStatusInitial extends RepoStatusState { const RepoStatusInitial(); }
class RepoStatusLoading extends RepoStatusState { const RepoStatusLoading(); }

class RepoStatusLoaded extends RepoStatusState {
  final List<String> staged;
  final List<String> unstaged;
  final String rawOutput;
  const RepoStatusLoaded({required this.staged, required this.unstaged, required this.rawOutput});
  @override List<Object?> get props => [staged, unstaged, rawOutput];
}

class RepoStatusError extends RepoStatusState {
  final String message;
  const RepoStatusError({required this.message});
  @override List<Object?> get props => [message];
}