sites_available=/etc/nginx/sites-available
sites_enabled=/etc/nginx/sites-enabled

echo "$2" > /etc/nginx/sites-available/$1.conf
ln -fs ${sites_available}/${1} ${sites_enabled}/${1}

# for project in #{projects.join(' ')}; do

# for site_available in ${sites_available}/*; do
#     site_name=`basename ${site_available}`
#     project_dir=/home/vagrant/${site_name}

#     # Project directory exists and is empty (happens when synced folder used to be mapped is not mapped anymore)
#     if [[ -d ${project_dir} && ! "$(ls -A ${project_dir})" ]]; then
#         rm -rf ${project_dir} 2> /dev/null
#         # rm -rf above will fail if directory is mounted as synced folder but empty anyway
#         if [ $? -eq 0 ]; then
#             rm -f ${sites_available}/${site_name} ${sites_enabled}/${site_name}
#         fi
#     fi
# done

# if [[ -d /home/vagrant/${project} && ! -f ${sites_available}/${project} ]]; then
#     echo '#{template_nginx_symfony_site_conf}' | sed s/{SITE}/${project}/g >> /etc/nginx/sites-available/${project}
#     ln -s ${sites_available}/${project} ${sites_enabled}/${project}
# fi

# done
