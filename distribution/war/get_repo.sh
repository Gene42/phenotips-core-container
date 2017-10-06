#!/bin/sh

result_dir=target/repo
mkdir -p ${result_dir}
resulting_repo_folder=target/result_repo

mkdir -p ${resulting_repo_folder}

output_file=${result_dir}/deps

parsed_output_file=${result_dir}/result
echo "" > ${parsed_output_file}

#mvn org.apache.maven.plugins:maven-dependency-plugin:3.0.2:list | grep xar | cat | awk '{print $2}' > ${output_file}
# -DoutputFile=hmm.txt

maven_repo=~/.m2/repository



while read line; do
  #echo ${line}
  type=$(echo ${line} | awk -F ':' '{print $3}')
  if [ "$type" = "xar" ]; then

     group_id=$(echo "${line}" | awk -F ':' '{print $1}' | sed -e 's/\./\//g')
     artifact_id=$(echo "${line}" | awk -F ':' '{print $2}')
     version=$(echo "${line}" | awk -F ':' '{print $4}')

     #echo "${group_id},${artifact_id},${version}"

     folder_name=${maven_repo}/${group_id}/${artifact_id}/${version}
     #echo ${file_name}
     if [ -e ${folder_name} ]; then
        file_name=$(ls ${folder_name} | grep ".*xar$")
        #echo ${folder_name}/${file_name}
        echo "${folder_name}/${file_name}" >> ${parsed_output_file}
     fi

     #echo "${line}" >> ${parsed_output_file}
  fi
done <${output_file}

cat ${parsed_output_file}

#| grep xar | awk '{print $2}' | awk -F ':' '{print $1,$2,$4}' | sed -e 's/ /\//g'
