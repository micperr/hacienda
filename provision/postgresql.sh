sudo -iu postgres
initdb -D /var/lib/postgres/data
createuser vagrant -s
exit

# createdb {DATABASE_NAME}
# psql -d {DATABASE_NAME}

sed -i "/^#listen_addresses/i listen_addresses='10.11.12.13'" /var/lib/postgres/data/postgresql.conf
echo 'host all all 10.11.12.1/32 trust' >> /var/lib/postgres/data/pg_hba.conf
# echo 'host all all 10.11.12.1/32 trust' | sudo tee -a /var/lib/postgres/data/pg_hba.conf
