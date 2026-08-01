import 'package:flutter_bloc/flutter_bloc.dart';

class StaffWorkspaceState {
  const StaffWorkspaceState({this.reportRefreshRevision = 0});

  final int reportRefreshRevision;
}

class StaffWorkspaceCubit extends Cubit<StaffWorkspaceState> {
  StaffWorkspaceCubit() : super(const StaffWorkspaceState());

  void reportWorkflowUpdated() {
    emit(
      StaffWorkspaceState(
        reportRefreshRevision: state.reportRefreshRevision + 1,
      ),
    );
  }
}
