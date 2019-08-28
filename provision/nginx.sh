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

cp /vagrant/provision/templates/nginx.conf /etc/nginx/nginx.conf

# PHP Info
echo "<?php phpinfo() ?>" | tee /usr/share/nginx/phpinfo.php > /dev/null

# Adminer
curl -s https://api.github.com/repos/vrana/adminer/releases/latest \
| grep "browser_download_url.*adminer-[0-9\.]*-en.php" \
| cut -d : -f 2,3 \
| tr -d \" \
| wget -O /usr/share/nginx/adminer.php -qi -
