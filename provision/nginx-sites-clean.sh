sites_available=/etc/nginx/sites-available
sites_enabled=/etc/nginx/sites-enabled

is_cleaned=false
for site_available in ${sites_available}/*; do
    site_name=`basename ${site_available}`
    project_dir=/home/vagrant/${site_name}

    # Project directory exists and is empty (happens when synced folder used to be mapped is not mapped anymore)
    if [[ -d ${project_dir} && ! "$(ls -A ${project_dir})" ]]; then

        rm -rf ${project_dir} 2> /dev/null

        printf "Cleaned `${site_name}`\n"
        is_cleaned=true

        # rm -rf above will fail if directory is mounted as synced folder but empty anyway
        if [ $? -eq 0 ]; then
            rm -f ${sites_available}/${site_name} ${sites_enabled}/${site_name}
        fi
    fi
done


if [ $is_cleaned ]; then
      echo "Nothing to clean"
fi
# if [[ -d /home/vagrant/${project} && ! -f ${sites_available}/${project} ]]; then
#     echo '#{template_nginx_symfony_site_conf}' | sed s/{SITE}/${project}/g >> /etc/nginx/sites-available/${project}
#     ln -s ${sites_available}/${project} ${sites_enabled}/${project}
# fi
