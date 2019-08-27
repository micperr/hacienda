systemctl enable nginx
systemctl start nginx

systemctl enable php-fpm
systemctl start php-fpm

systemctl enable mariadb.service
systemctl start mariadb.service
