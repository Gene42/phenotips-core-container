#!/usr/bin/env bash

set +x

config_file_name=$1
config_dir=/var/lib/phenotips/conf
config_file=${config_dir}/${config_file_name}

if [ ! -f "${config_file}" ]; then
   echo "Config file ${config_file} could not be found. Container will not start."
   exit 1
fi

catalina.sh run

