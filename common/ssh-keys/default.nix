# Admin SSH keys
{ lib, config, ... }: {
  # Filter them out if they are not decrypted.
  users.users.root.openssh.authorizedKeys.keyFiles = if config.uav-gaming.devEnv then [
    ./tian.pub
    ./zhaofeng.pub
    ./actions.pub
  ] else [];
}
