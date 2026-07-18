class Project {
  final String name;
  final String rootPath;
  final String primaryLanguage;
  final DateTime lastOpened;
  final String? gitRemoteUrl;

  Project({
    required this.name,
    required this.rootPath,
    required this.primaryLanguage,
    required this.lastOpened,
    this.gitRemoteUrl,
  });

  Project copyWith({
    String? name,
    String? rootPath,
    String? primaryLanguage,
    DateTime? lastOpened,
    String? gitRemoteUrl,
  }) {
    return Project(
      name: name ?? this.name,
      rootPath: rootPath ?? this.rootPath,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      lastOpened: lastOpened ?? this.lastOpened,
      gitRemoteUrl: gitRemoteUrl ?? this.gitRemoteUrl,
    );
  }
}
