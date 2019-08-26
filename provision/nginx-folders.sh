sites_available=/etc/nginx/sites-available
sites_enabled=/etc/nginx/sites-enabled

mkdir -p \
  /etc/nginx/ssl \
  $sites_available \
  $sites_enabled

rm -rf \
  /usr/share/nginx/html \
  $sites_enabled/* \
  $sites_available/*


# systemctl enable nginx && systemctl start nginx
mkdir -p /usr/share/nginx
