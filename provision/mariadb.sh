mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
systemctl enable mariadb.service && systemctl start mariadb.service

NEW_MYSQL_PASSWORD='xxx'
SECURE_MYSQL=$(expect -c '
  set timeout 3
  spawn mysql_secure_installation
  expect "Enter current password for root (enter for none):"
  send "\r"
  expect "Switch to unix_socket authentication"
  send "n\r"
  expect "Change the root password?"
  send "y\r"
  expect "New password:"
  send "'${NEW_MYSQL_PASSWORD}'\r"
  expect "Re-enter new password:"
  send "'${NEW_MYSQL_PASSWORD}'\r"
  expect "Remove anonymous users?"
  send "n\r"
  expect "Disallow root login remotely?"
  send "n\r"
  expect "Remove test database and access to it?"
  send "n\r"
  expect "Reload privilege tables now?"
  send "y\r"
  expect eof
')
echo "${SECURE_MYSQL}"


GRANT_ALL=$(expect -c '
set timeout 3
spawn mysql -u root -p -e '{"GRANT ALL PRIVILEGES ON *.* TO root@\'%\' IDENTIFIED BY \'xxx\'"}'
expect "Enter password:"
send "'${NEW_MYSQL_PASSWORD}'\r"
expect eof
')

echo "${GRANT_ALL}"
