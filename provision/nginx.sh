mkdir -p /etc/nginx/ssl
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled
echo '#{template_nginx_conf}' > /etc/nginx/nginx.conf
chmod 755 /home/vagrant
rm -rf /usr/share/nginx/html

# PHP Info
echo "<?php phpinfo() ?>" | sudo tee /usr/share/nginx/phpinfo.php > /dev/null

# Adminer
curl -s https://api.github.com/repos/vrana/adminer/releases/latest \
| grep "browser_download_url.*adminer-[0-9\.]*-en.php" \
| cut -d : -f 2,3 \
| tr -d \\" \
| wget -O /usr/share/nginx/adminer.php -qi -


sites_available=/etc/nginx/sites-available
sites_enabled=/etc/nginx/sites-enabled

for project in #{projects.join(' ')}; do

for site_available in ${sites_available}/*; do
    site_name=`basename ${site_available}`
    project_dir=/home/vagrant/${site_name}

    # Project directory exists and is empty (happens when synced folder used to be mapped is not mapped anymore)
    if [[ -d ${project_dir} && ! "$(ls -A ${project_dir})" ]]; then
    rm -rf ${project_dir} 2> /dev/null
    # rm -rf above will fail if directory is mounted as synced folder but empty anyway
    if [ $? -eq 0 ]; then
        rm -f ${sites_available}/${site_name} ${sites_enabled}/${site_name}
    fi
    fi
done

if [[ -d /home/vagrant/${project} && ! -f ${sites_available}/${project} ]]; then
    echo '#{template_nginx_symfony_site_conf}' | sed s/{SITE}/${project}/g >> /etc/nginx/sites-available/${project}
    ln -s ${sites_available}/${project} ${sites_enabled}/${project}
fi

done

systemctl enable nginx && systemctl start nginx
