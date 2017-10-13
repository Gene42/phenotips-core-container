#!/usr/bin/env bash

set +x

CATALINA_HOME=/usr/local/tomcat

config_file_name=$1
config_dir=/var/lib/phenotips/conf
config_file=${config_dir}/${config_file_name}

ls ${CATALINA_HOME}

echo

ls ${CATALINA_HOME}/logs

echo "Contents of ${config_dir}"
ls -a ${config_dir}

if [ ! -f "${config_file}" ]; then
   echo "Config file ${config_file} could not be found. Container will not start."
   exit 1
fi

rm ${config_file}

ls -a ${config_dir}

catalina.sh run

