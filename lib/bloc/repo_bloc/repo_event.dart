part of 'repo_bloc.dart';

abstract class RepoStatusEvent extends Equatable {
  const RepoStatusEvent();
  @override List<Object?> get props => [];
}

class LoadRepoStatus extends RepoStatusEvent {
  final String workspace;
  const LoadRepoStatus(this.workspace);
  @override List<Object?> get props => [workspace];
}