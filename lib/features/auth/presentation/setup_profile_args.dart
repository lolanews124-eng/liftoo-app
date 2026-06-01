class SetupProfileArgs {
  final String? phone;
  final bool phoneLocked;
  final bool fromGoogle;

  const SetupProfileArgs({
    this.phone,
    this.phoneLocked = false,
    this.fromGoogle = false,
  });
}
