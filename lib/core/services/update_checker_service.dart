class UpdateCheckerService {
  final String currentVersion;

  UpdateCheckerService({required this.currentVersion});

  bool isUpdateAvailable(String latestVersion) {
    try {
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      final latestParts = latestVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (currentParts[i] > latestParts[i]) return false;
      }
    } catch (_) {}
    return false;
  }
}
