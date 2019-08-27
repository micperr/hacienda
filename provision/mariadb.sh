#!/usr/bin/expect -f

exec mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
exec systemctl start mariadb.service

set DB_PASSWORD $::env(DB_PASSWORD)
set timeout 3

spawn mysql_secure_installation
expect "Enter current password for root (enter for none):"
send "\r"
expect "Switch to unix_socket authentication"
send "n\r"
expect "Change the root password?"
send "y\r"
expect "New password:"
send "$DB_PASSWORD\r"
expect "Re-enter new password:"
send "$DB_PASSWORD\r"
expect "Remove anonymous users?"
send "n\r"
expect "Disallow root login remotely?"
send "n\r"
expect "Remove test database and access to it?"
send "n\r"
expect "Reload privilege tables now?"
send "y\r"
expect eof

exec systemctl stop mariadb.service
# spawn mysql -u root -p -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY 'xxx'"
# expect "Enter password:"
# send "${PASSWORD}\r"
# expect eof
