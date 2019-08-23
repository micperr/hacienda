# PHP Info
echo "<?php phpinfo() ?>" | sudo tee /usr/share/nginx/phpinfo.php > /dev/null

# Adminer
curl -s https://api.github.com/repos/vrana/adminer/releases/latest \
| grep "browser_download_url.*adminer-[0-9\.]*-en.php" \
| cut -d : -f 2,3 \
| tr -d \\" \
| wget -O /usr/share/nginx/adminer.php -qi -
