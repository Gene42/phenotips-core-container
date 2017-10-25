#!/usr/bin/env bash

set +x

get_solr_version() {
    _folder="$1"

    #cat /var/lib/phenotips/solr/META-INF/maven/org.phenotips/solr-configuration/pom.properties | grep version= | cut -d '=' -f 2
    _pom_prop_file_path="${_folder}/META-INF/maven/org.phenotips/solr-configuration/pom.properties"
    if [ -f "${_pom_prop_file_path}" ]; then
        _version=$(cat "${_pom_prop_file_path}" | grep version= | cut -d '=' -f 2)
        echo "${_version}"
    else
        echo "Unknown"
    fi
}

ls "${CATALINA_HOME}"

echo

ls "${CATALINA_HOME}/logs"

echo "Contents of ${GENE42_CONF_DIR}"
ls -a "${GENE42_CONF_DIR}"

if [ ! -d "${GENE42_CONF_DIR}" ]; then
   echo "Config dir ${GENE42_CONF_DIR} could not be found. Container will not start."
   exit 1
fi

# Config
cp -R "${GENE42_CONF_DIR}/WEB-INF/" "${CATALINA_HOME}/webapps/ROOT/"

# Deal with Solr, because we can't overwrite ' solr.embedded.home=' :(
solr_dir="${PT_PERSISTENT_DIR}/solr"
if [ -d "${solr_dir}" ]; then
    current_solr_version=$(get_solr_version "${solr_dir}")
    echo "Removing old solr folder, version [${current_solr_version}]"
    rm -r "${solr_dir}"
fi
new_solr_version=$(get_solr_version "${WEB_INF_DIR}/solr" )
echo "Adding new solr folder, version [${new_solr_version}]"

mv "${WEB_INF_DIR}/solr" "${PT_PERSISTENT_DIR}"

ls -a "${WEB_INF_DIR}"

catalina.sh run

