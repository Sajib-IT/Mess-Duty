import '../models/task_model.dart';
import '../models/user_model.dart';

class RotationService {
  /// Calculates the next available member index and ID for a given task.
  /// Skips members who are not available.
  static Map<String, dynamic>? getNextAssignment({
    required TaskModel task,
    required List<UserModel> allUsers,
  }) {
    if (task.membersOrder.isEmpty) return null;

    int currentIndex = task.rotationIndex;
    int originalIndex = currentIndex;
    int totalMembers = task.membersOrder.length;

    // We try to find the next available member starting from the current index
    for (int i = 0; i < totalMembers; i++) {
      int checkIndex = (currentIndex + i) % totalMembers;
      String memberId = task.membersOrder[checkIndex];
      
      // Find the user in the allUsers list
      UserModel? user = allUsers.firstWhere(
        (u) => u.id == memberId,
        orElse: () => UserModel(id: '', name: 'Unknown', email: '', isAvailable: false),
      );

      if (user.id.isNotEmpty && user.isAvailable) {
        // Found the next available member
        int nextRotationIndex = (checkIndex + 1) % totalMembers;
        return {
          'memberId': user.id,
          'nextRotationIndex': nextRotationIndex,
          'memberName': user.name,
        };
      }
    }

    // No available members found
    return null;
  }
}
