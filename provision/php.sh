function enable_ext() {
  sed -i "/extension\s*=\s*$1/ s/^;*//" /etc/php/php.ini
}

function uncomment() {
  sed -i "/$1\s*=/ s/^;*//" /etc/php/php.ini
}

function uncomment_all() {
  sed -i 's/\;//' $1
}

function change_val() {
  sed -i "s,$1\s*=.*$,$1=$2," /etc/php/php.ini
  # sed -e "/$1.*=.*/ s/=.*/=$2/" /etc/php/php.ini
  # sed 's,$1.*=.*$,$1=$2' /etc/php/php.ini
}

function uncomment_change_val() {
  uncomment $1 && change_val $1 $2
}

enable_ext iconv
enable_ext intl
enable_ext opcache
enable_ext pdo_mysql
enable_ext sockets
uncomment opcache.enable
uncomment_change_val realpath_cache_size 4096K
uncomment_change_val realpath_cache_ttl 600
uncomment_change_val opcache.memory_consumption 256
uncomment_change_val opcache.max_accelerated_files 20000

### XDEBUG ###
echo "zend_extension=xdebug.so
xdebug.idekey=LISTENTOME
xdebug.remote_enable=1
xdebug.remote_host=10.0.2.2
xdebug.remote_port=9000
xdebug.remote_autostart=0
xdebug.remote_connect_back=0
xdebug.remote_handler=dbgp
xdebug.remote_log=/var/log/xdebug.log
xdebug.max_nesting_level=300
xdebug.var_display_max_depth = 5
xdebug.var_display_max_children = 256
xdebug.var_display_max_data = 1024" > /etc/php/conf.d/xdebug.ini

systemctl enable php-fpm && systemctl start php-fpm
