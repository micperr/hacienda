site_available=/etc/nginx/sites-available/$1
site_enabled=/etc/nginx/sites-enabled/$1

cp $2 $site_available
sed -i "s|{ROOT}|$3|g" $site_available
sed -i "s|{DOMAIN}|$4|g" $site_available

ln -fs $site_available $site_enabled

systemctl restart nginx
