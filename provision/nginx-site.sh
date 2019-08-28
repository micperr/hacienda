site_available=/etc/nginx/sites-available/$1
site_enabled=/etc/nginx/sites-enabled/$1

echo "$2" > $site_available
ln -fs $site_available $site_enabled
