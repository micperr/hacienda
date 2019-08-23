sites_available=/etc/nginx/sites-available
sites_enabled=/etc/nginx/sites-enabled

mkdir -p /etc/nginx/ssl
mkdir -p $sites_available
mkdir -p $sites_enabled
rm -f $sites_available/*
rm -f $sites_enabled/*
rm -rf /usr/share/nginx/html
# chmod 755 $1
chmod 755 /home/vagrant


# systemctl enable nginx && systemctl start nginx
