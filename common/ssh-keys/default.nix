# Admin SSH keys
with builtins;
let
  # A list of admin keys.
  keyFiles = [
      ./tian.pub
      ./zhaofeng.pub
      ./actions.pub
  ];
in { lib, ... }: {
  # Filter them out if they are not decrypted.
  users.users.root.openssh.authorizedKeys.keyFiles = filter (path: lib.hasPrefix "ssh-" (readFile path)) keyFiles;
}
