FROM openjdk:8u131-jre-alpine

LABEL maintainer="sebastain@gene42.com"

# /
# ├── /var/lib/gene42/phenotips/conf/
# │                             └── WEB-INF/
# │                                 ├── hybernate.cfg.xml
# │                                 ├── xwiki.properties
# │                                 └── xwiki.cfg
# ├── /var/lib/phenotips/
# │            ├── cache/
# │            ├── extension/
# │            ├── jobs/
# │            ├── solr/
# │            └── storage/
# └── /usr/local/tomcat/
#                ├── /
#                └── webapps/ROOT/

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.20
ENV TOMCAT_USER tomcat${TOMCAT_MAJOR}
ENV USER_ID 9000

# Folders
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
ENV PT_PERSISTENT_DIR /var/lib/phenotips
ENV CATALINA_HOME /usr/local/tomcat
ENV WEB_INF_DIR ${CATALINA_HOME}/webapps/ROOT/WEB-INF
ENV GENE42_DIR /var/lib/gene42
ENV GENE42_CONF_DIR ${GENE42_DIR}/phenotips/conf

# Files
ENV SOLR_JAR solr-configuration.jar
ENV PT_WAR phenotips.war
ENV LOCAL_REPO_ZIP phenotips-local-repository.zip

ENV KEYS_URL "https://www.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR}/KEYS"
ENV TOMCAT_TGZ_URL "https://www.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
ENV TOMCAT_ASC_URL "${TOMCAT_TGZ_URL}.asc"
ENV TOMCAT_ARCHIVE_TGZ_URL "https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
ENV TOMCAT_ARCHIVE_ASC_URL "${TOMCAT_ARCHIVE_TGZ_URL}.asc"

ENV TOMCAT_TGZ_FILE "tomcat.tar.gz"
ENV TOMCAT_ASC_FILE "tomcat.tar.gz.asc"

RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

RUN apk add --no-cache gnupg

# Fetch tomcat and validate (look into archive if not found on main link)
RUN set -x \
	\
	&& apk add --no-cache --virtual .fetch-deps \
		ca-certificates \
		tar \
		openssl \
		unzip \
		wget \
  && { \
    wget -O KEYS ${KEYS_URL} \
  ; } \
	&& { \
		if ! wget -O ${TOMCAT_TGZ_FILE} ${TOMCAT_TGZ_URL}; then wget -O ${TOMCAT_TGZ_FILE} ${TOMCAT_ARCHIVE_TGZ_URL} ; fi \
	; } \
	&& { \
	  if ! wget -O ${TOMCAT_ASC_FILE} ${TOMCAT_ASC_URL}; then wget -O ${TOMCAT_ASC_FILE} ${TOMCAT_ARCHIVE_ASC_URL} ; fi \
	; } \
	&& gpg --import KEYS \
	&& gpg --batch --verify ${TOMCAT_ASC_FILE} ${TOMCAT_TGZ_FILE} \
	&& tar -xvf ${TOMCAT_TGZ_FILE} --strip-components=1 \
	&& rm bin/*.bat \
	&& rm ${TOMCAT_TGZ_FILE}* \
  && adduser -D -u ${USER_ID} ${TOMCAT_USER} \
	&& apk add --no-cache bash \
	&& find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' +

# Create PhenoTips persistent directory
RUN mkdir -p ${PT_PERSISTENT_DIR}

RUN rm -r webapps
RUN mkdir -p webapps

# Standalone (for the extensions, etc..)
#COPY target/${PT_STANDALONE_ZIP} ./
#RUN unzip -d standalone ${PT_STANDALONE_ZIP}
#RUN rm ${PT_STANDALONE_ZIP}
#RUN temp_folder=$(ls standalone); mv standalone/${temp_folder} standalone/standalone
#RUN mv standalone/standalone/webapps/phenotips webapps
#RUN mv webapps/phenotips webapps/ROOT

# WAR
COPY target/${PT_WAR} ./
RUN unzip ${PT_WAR} -d ./webapps/ROOT/
RUN rm ${PT_WAR}


# SOLR
COPY target/${SOLR_JAR} ./
RUN unzip ${SOLR_JAR} -d ${WEB_INF_DIR}/solr
RUN rm ${SOLR_JAR}

#RUN rm -r standalone

# Local Extension REPO
COPY target/${LOCAL_REPO_ZIP} ./
RUN unzip ${LOCAL_REPO_ZIP} -d .m2
RUN rm ${LOCAL_REPO_ZIP}

# Change permissions for tomcat user
RUN chown ${TOMCAT_USER}:${TOMCAT_USER} -R ${PT_PERSISTENT_DIR}

# The location where the configurations used to start the container will be placed
RUN mkdir -p ${GENE42_CONF_DIR}
RUN chown ${TOMCAT_USER}:${TOMCAT_USER} -R  ${GENE42_DIR}

# Remove confg files
RUN rm ${WEB_INF_DIR}/hibernate.cfg.xml
RUN rm ${WEB_INF_DIR}/xwiki.cfg
RUN rm ${WEB_INF_DIR}/xwiki.properties

RUN rm ${WEB_INF_DIR}/classes/hibernate.cfg.xml
RUN rm ${WEB_INF_DIR}/classes/xwiki.cfg
RUN rm ${WEB_INF_DIR}/classes/xwiki.properties

# Start Script
COPY src/main/sh/start-container.sh ${CATALINA_HOME}/bin
RUN chmod +x $CATALINA_HOME/bin/start-container.sh

RUN chown ${TOMCAT_USER}:${TOMCAT_USER} -R ${CATALINA_HOME}

USER ${TOMCAT_USER}

EXPOSE 8080
ENTRYPOINT ["start-container.sh"]
CMD []
