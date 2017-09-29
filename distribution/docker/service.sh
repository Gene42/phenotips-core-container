#!/bin/sh

RED='\033[31;1m'
GREEN='\033[32;1m'
YELLOW='\033[33;1m'
NO_COLOR='\033[0m'

#repository=gene42/gene42-phenotips-core
#tag_name=latest
#container_name=gene42-phenotips-core-test

#service_is_running_string="Service $container_name is running"

#running=""

ANSI_=$(if [ "$(tput colors)" -eq "8" ]; then echo true; fi);

# Prints the given text with given indentation and ends it with a new line
## $1 : {string} [required] - the text to print
## $2 : {number} [optional] - the number of tabs to print before text
printl()
{
    _text=$1
    _indent=$2
    _color=$3

    if [ "$ANSI_" ]; then
       _prefix=${_color}
       _suffix=${NO_COLOR}
    else
       _prefix=""
       _suffix=""
    fi

    if [ -z "$2" ]; then
        _end_index=0
    else
        _end_index=${_indent}
    fi

    _i=0
    _tabs=""

    while [ ${_i} -lt ${_end_index} ]
    do
        _tabs="${_tabs}\t"
        _i=$((_i+1))
    done

    printf "${_tabs}${_prefix}%s${_suffix}\n" "${_text}"
}

# Prints an error message and exits with an error code
print_and_exit() { printl "$1" "0" "${RED}"; exit 1; }

# Checks if the given string is empty for a given parameter
## $1 : {string} [required] - the parameter name
## $2 : {string} [required] - the string to check
check_non_empty() {
    if [ -z "$2" ]; then
        print_and_exit "Parameter [$1] is missing/empty. Exiting.."
    fi
}

# Checks if
## $1 : {string} [required] - repository
## $2 : {string} [required] - tag
image_exists() {
    echo "$(sudo docker images | grep "${1}" | grep "${2}" | cat)"
}

get_file_path() {
    local_given_path_="$1"
    local_first_char_="$(echo ${local_given_path_} | awk '{print substr($0, 0, 1)}')"

    if [ "$local_first_char_" = "/" ]; then
       echo "${local_given_path_}"
    elif [ "$local_first_char_" = "." ]; then
       echo "$(pwd)/$(echo ${local_given_path_} | awk '{print substr($0, 2)}')"
    else
       echo "$(pwd)/${local_given_path_}"
    fi
}

wait_on_container() {
    _local_to_wait_on=$1
    _local_is_running=$(sudo docker inspect --format="{{ .State.Running }}" ${_local_to_wait_on} 2> /dev/null)

    echo "Waiting on $_local_to_wait_on"

    _local_i=0
    while [ "$_local_is_running" = "false" ] && [ "$_local_i" -lt 15 ];  do
        sleep 4
        _local_is_running=$(sudo docker inspect --format="{{ .State.Running }}" ${_local_to_wait_on} 2> /dev/null)
        _local_i=$(expr ${_local_i} + 1)
    done

    if [ "$_local_i" -ge 10 ]; then
        echo "Timed out while waiting on $_local_to_wait_on!"
        exit 1
    fi
}

check_running() {
  _local_expected=$1
  # If set to non empty string, if the result does not match the expected result, the script won't exit with an error
  _local_output=$2
  _local_container_name=$3

  running=$(sudo docker inspect --format="{{ .State.Running }}" ${_local_container_name} 2> /dev/null)

  if [ $? -eq 1 ]; then
    echo "UNKNOWN - $_local_container_name does not exist. Please run the $_local_container_name install script."
    exit 3
  fi

  if [ "$running" = "true" ]; then
    if [ "$_local_expected" = "false" ]; then
       echo "Service $_local_container_name already running" >&2
       exit 1
    elif [ "$_local_expected" = "?" ] || [ "$_local_output" = "true" ]; then
       echo "Service $_local_container_name is running"
    fi
  elif [ "$running" = "false" ]; then
    if [ "$_local_expected" = "true" ]; then
       echo "Service $_local_container_name not running" >&2
       exit 1
    elif [ "$_local_output" ]; then
       echo "Service $_local_container_name is not running"
    elif [ "$_local_expected" = "?" ]; then
       echo "Service $_local_container_name is not running" >&2
       exit 3
    fi
  else
      echo "Service $_local_container_name is in unknown state!" >&2
      exit 1
  fi
}

start_() {
   start_container_name_=

   for i in "$@"
   do
   case ${i} in
     --name=*)
       start_container_name_="${i#*=}"
     ;;
     *)
     ;;
   esac
   done

  check_running "false" "false" "${start_container_name_}"

  echo "Starting ${start_container_name_} service…" >&2
  sudo docker start ${start_container_name_} > /dev/null
  check_running "true" "true" "${start_container_name_}"
}

stop_() {
   stop_container_name_=
   for i in "$@"
   do
   case ${i} in
     --name=*)
       stop_container_name_="${i#*=}"
     ;;
     *)
     ;;
   esac
   done

  check_running "true" "false" "${stop_container_name_}"
  echo "Stopping ${stop_container_name_} service…" >&2
  sudo docker stop ${stop_container_name_}> /dev/null
  check_running "false" "true" "${stop_container_name_}"
}

status_() {
  check_running "?"
}

log_() {
  if [ "$(image_exists)" ]; then
     sudo docker logs -f ${container_name}
  else
     echo "Container '${container_name}' does not exist."
     exit 0
  fi
}

install_() {
   install_tag_=
   install_repository_=
   local_config_=
   local_container_name_=

   for i in "$@"
   do
   case ${i} in
     --conf=*)
       local_config_="${i#*=}"
     ;;
     --repo=*)
       install_repository_="${i#*=}"
     ;;
     --tag=*)
       install_tag_="${i#*=}"
     ;;
     --name=*)
       local_container_name_="${i#*=}"
     ;;
     *)
     ;;
   esac
   done

   check_non_empty "--repo=" ${install_repository_}
   #check_non_empty "--tag=" ${install_tag_}
   check_non_empty "--conf=" ${local_config_}
   check_non_empty "--name=" ${local_container_name_}

   if [ -z "${install_tag_}" ]; then
      echo "No version was specified, using 'latest'"
      install_tag_=latest
   fi

   install_image_="${install_repository_}:${install_tag_}"

   echo "Installing ${install_repository_}:${install_tag_}"

   if [ -z "$(image_exists ${install_repository_} ${install_tag_} )" ]; then
       echo "${install_image_} was not found locally, pulling from repository.."
       sudo docker pull "${install_image_}"

       if [ $? -ne 0 ]; then
            print_and_exit "Could not pull image, exiting.."
       fi
   fi

   running=$(sudo docker inspect --format="{{ .State.Running }}" "$local_container_name_" 2> /dev/null)

   if [ $? -eq 0 ]; then
      echo "Container $local_container_name_ already exists, remove and create a new one."
      if [ "$running" = "true" ]; then
          sudo docker stop "$local_container_name_" > /dev/null
      fi
      sudo docker rm "$local_container_name_" > /dev/null
   fi

   echo "Creating container [${local_container_name_}], with configuration [${local_config_}]"

   if [ -f "$local_config_" ]; then

      local_config_file_name_=$(echo ${local_config_} | awk -F "/" '{print $NF}')

      # Create config location and log
      install_container_home_=~/.gene42/docker/${local_container_name_}__${local_config_file_name_}
      mkdir -p ${install_container_home_}/conf
      mkdir -p ${install_container_home_}/log
      sudo cp -f "$(get_file_path ${local_config_})" "${install_container_home_}/conf"
      sudo chown -R 9000:9000 ${install_container_home_}
      sudo chmod -R o-rwx ${install_container_home_}/conf

      sudo docker create \
             --name "${local_container_name_}" \
             -p 8080:8080 -p 8009:8009 \
             -v ${install_container_home_}/conf:/var/lib/phenotips/conf \
             -v ${install_container_home_}/log:/usr/local/tomcat/logs \
             "${install_image_}" "${local_config_file_name_}" > /dev/null
   else
      print_and_exit "Config file [$local_config_] does not exist. Exiting.."
   fi

   printl "Done" "0" "${GREEN}"
}

uninstall_() {
   if [ "$service_is_running_string" = "$(check_running "?")" ]; then
      print_and_exit "Service is still running. Stop it and retry."
   fi

   sudo docker rm "$container_name" > /dev/null

   for image_line in "$(sudo docker images | grep ${repository} | cat)"
   do
      echo "$image_line"
      image_to_delete_="$(echo ${image_line} | awk '{print $3}')"
      echo "image_to_delete_=$image_to_delete_"
      if [ "${image_to_delete_}" ]; then
         sudo docker rmi "$image_to_delete_"
      fi
   done
   printl "Done" "0" "${GREEN}"
}

case "$1" in
  install)
    install_ "$@"
    ;;
  uninstall)
    uninstall_
    ;;
  start)
    start_ "$@"
    ;;
  stop)
    stop_ "$@"
    ;;
  restart)
    stop_
    start_
    ;;
  status)
    status_
    ;;
  log)
    log_
    ;;
  *)
    printl "Usage: $0 {install|uninstall|start|stop|restart|status|uninstall}" "0" "${YELLOW}"
esac
