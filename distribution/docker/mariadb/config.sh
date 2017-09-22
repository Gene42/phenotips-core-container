#!/bin/sh
#--host=172.17.0.2 --user=root -p


CONF_MARIADB_ROOT_PASS=mypass
pt_db=phenotips
pt_user_user=user1
pt_user_pass=test1234
host="172.17.0.2"

mysql --host=${host} -u root --password=${CONF_MARIADB_ROOT_PASS} -e "CREATE DATABASE IF NOT EXISTS ${pt_db} character set utf8 collate utf8_bin;"
mysql --host=${host} -u root --password=${CONF_MARIADB_ROOT_PASS} -e "CREATE USER IF NOT EXISTS ${pt_user_user}@'localhost' IDENTIFIED BY '${pt_user_pass}';"
mysql --host=${host} -u root --password=${CONF_MARIADB_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON ${pt_db}.* TO '${pt_user_user}'@'localhost' IDENTIFIED BY '${pt_user_pass}'; FLUSH PRIVILEGES;"
