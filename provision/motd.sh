flag="/home/vagrant/.provisioned.motd"
if [[ ! -f $flag ]]; then

  ########
  # MOTD #
  ########
  wget -qO /usr/bin/update_motd.sh https://gist.githubusercontent.com/micperr/efe6e415610bd893b3a4ac9882bd9dd4/raw/4c4fe1a24f9f4a1cdb292be9fdace2a0f223a924/motd.sh
  chmod 775 /usr/bin/update_motd.sh
  # sed -e ':motd=/etc/motd: s/^#*/#/' -i /etc/pam.d/system-login
  sed -e '/pam_motd.so/ s/^#*/#/' -i /etc/pam.d/system-login
  echo "\nsession    optional   pam_exec.so   stdout /usr/bin/update_motd.sh\nsession    optional   pam_motd.so   motd=/etc/motd\" | sudo tee -a /etc/pam.d/sshd > /dev/null

  touch $flag
fi
