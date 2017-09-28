#!/bin/sh

RED='\033[31;1m'
GREEN='\033[32;1m'
YELLOW='\033[33;1m'
NO_COLOR='\033[0m'

repository=gene42/gene42-phenotips-core
tag_name=latest
container_name=gene42-phenotips-core-test

service_is_running_string="Service $container_name is running"

running=""
containers_to_wait_on=

ANSI_=$(if [ "$(tput colors)" -eq "8" ]; then echo true; fi);

# Prints the given text with given indentation and ends it with a new line
## $1 : {string} [optional] - the text to print
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

image_exists_() {
    image_string_local_=$(sudo docker images | grep "${repository}" | grep "${tag_name}")
    echo "$image_string_local_"
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
  running=$(sudo docker inspect --format="{{ .State.Running }}" ${container_name} 2> /dev/null)

  if [ $? -eq 1 ]; then
    echo "UNKNOWN - $container_name does not exist. Please run the $container_name install script."
    exit 3
  fi

  if [ "$running" = "true" ]; then
    if [ "$_local_expected" = "false" ]; then
       echo "Service $container_name already running" >&2
       exit 1
    elif [ "$_local_expected" = "?" ] || [ "$_local_output" ]; then
       echo "Service $container_name is running"
    fi
  elif [ "$running" = "false" ]; then
    if [ "$_local_expected" = "true" ]; then
       echo "Service $container_name not running" >&2
       exit 1
    elif [ "$_local_output" ]; then
       echo "Service $container_name is not running"
    elif [ "$_local_expected" = "?" ]; then
       echo "Service $container_name is not running" >&2
       exit 3
    fi
  else
      echo "Service $container_name is in unknown state!" >&2
      exit 1
  fi
}

start_() {
  check_running "false"

  if [ "$containers_to_wait_on" ]; then
    for to_wait_on in ${containers_to_wait_on}
    do
      wait_on_container "$to_wait_on"
      echo "$to_wait_on is running.."
    done
    sleep 5
  fi

  echo "Starting $container_name service…" >&2
  sudo docker start ${container_name} > /dev/null
  check_running "true" "true"
}

stop_() {
  check_running "true"
  echo "Stopping $container_name service…" >&2
  sudo docker stop ${container_name}> /dev/null
  check_running "false" "true"
}

status_() {
  check_running "?"
}

log_() {
  if [ "$(image_exists_)" ]; then
     sudo docker logs -f ${container_name}
  else
     echo "Container '${container_name}' does not exist."
     exit 0
  fi
}

install_() {
   local_tag_=
   local_repository_=${repository}
   local_config_=
   local_container_name_=${container_name}

   for i in "$@"
   do
   case ${i} in
     --conf=*)
       local_config_="${i#*=}"
     ;;
     --repo=*)
       local_repository_="${i#*=}"
     ;;
     --tag=*)
       local_tag_="${i#*=}"
     ;;
     *)
     ;;
   esac
   done

   if [ -z "${local_tag_}" ]; then
      echo "No version was specified, using 'latest'"
      local_tag_=latest
   fi

   echo "Installing ${local_repository_}:${local_tag_}"

   if [ -z "$(image_exists_)" ]; then
       echo "${local_repository_}:${local_tag_} was not found locally, pulling from repository.."
       sudo docker pull "${local_repository_}:${local_tag_}"

       if [ $? -ne 0 ]; then
            echo "Could not pull image, exiting.."
            exit 1
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

      sudo docker create \
             --name "${local_container_name_}" \
             -p 8080:8080 -p 8009:8009 \
             -v "$local_config_":/var/lib/phenotips/conf \
             "${local_repository_}:${local_tag_}" "${local_config_file_name_}" > /dev/null
   else
      sudo docker create \
             --name "${local_container_name_}" \
             -p 8080:8080 -p 8009:8009 \
             "${local_repository_}:${local_tag_}" > /dev/null
   fi


   printl "Done" "0" "${GREEN}"
}

uninstall_() {
   if [ "$service_is_running_string" = "$(check_running "?")" ]; then
      printl "Service is still running. Stop it and retry." "0" "${RED}"
      exit 1
   fi

   sudo docker rm "$container_name" > /dev/null

   for image_line in "$(sudo docker images | grep ${repository})"
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
    start_
    ;;
  stop)
    stop_
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
