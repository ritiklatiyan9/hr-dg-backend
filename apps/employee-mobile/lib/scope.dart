/// Immutable access key: changing views cannot retarget a pending write.
class SiteScope {
  const SiteScope(
    this.organizationId,
    this.actorId,
    this.permissionVersion,
    this.siteId,
  );
  final String organizationId, actorId, siteId;
  final int permissionVersion;
  @override
  bool operator ==(Object other) =>
      other is SiteScope &&
      organizationId == other.organizationId &&
      actorId == other.actorId &&
      permissionVersion == other.permissionVersion &&
      siteId == other.siteId;
  @override
  int get hashCode =>
      Object.hash(organizationId, actorId, permissionVersion, siteId);
}

class ScopeEpoch {
  int _value = 0;
  int capture() => _value;
  void change() => _value++;
  bool isCurrent(int captured) => captured == _value;
}
