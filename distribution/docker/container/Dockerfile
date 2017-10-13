FROM openjdk:8u131-jre-alpine

MAINTAINER Sebastian Stanisor <sebastain@gene42.com>

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.20
ENV TOMCAT_USER tomcat${TOMCAT_MAJOR}
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH

ENV PT_PERSISTENT_DIR /var/lib/phenotips

# /
# ├── /var/lib/phenotips/
# │            ├── cache/
# │            ├── extension/
# │            ├── jobs/
# │            ├── solr/
# │            └── storage/
# └── /usr/local/tomcat/

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
  && adduser -D -u 9000 ${TOMCAT_USER} \
	&& apk add --no-cache bash \
	&& find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' +

# Create PhenoTips persistent directory
RUN mkdir -p ${PT_PERSISTENT_DIR}/conf

RUN rm -r webapps/ROOT
RUN mkdir -p webapps

COPY src/main/sh/start-container.sh $CATALINA_HOME/bin
RUN chmod +x $CATALINA_HOME/bin/start-container.sh

# Standalone (for the extansions, etc..)
COPY target/gene42-phenotips-core-standalone.zip ./
RUN unzip -d standalone gene42-phenotips-core-standalone.zip
RUN temp_folder=$(ls standalone); mv standalone/${temp_folder} standalone/standalone

RUN mv standalone/standalone/webapps/phenotips webapps
RUN mv webapps/phenotips webapps/ROOT

# SOLR
RUN mv standalone/standalone/data/solr ${PT_PERSISTENT_DIR}
RUN rm -r ${PT_PERSISTENT_DIR}/solr/patients/

# Local Extension REPO
COPY target/gene42-phenotips-core-local-repository.zip ./

# Other suff
RUN mv standalone/standalone/data/cache ${PT_PERSISTENT_DIR}/
RUN mv standalone/standalone/data/extension ${PT_PERSISTENT_DIR}/
RUN mv standalone/standalone/data/storage ${PT_PERSISTENT_DIR}/

RUN rm -r standalone

RUN chown ${TOMCAT_USER}:${TOMCAT_USER} -R ${CATALINA_HOME}
RUN chown ${TOMCAT_USER}:${TOMCAT_USER} -R ${PT_PERSISTENT_DIR}

USER ${TOMCAT_USER}

EXPOSE 8080
ENTRYPOINT ["start-container.sh"]
CMD []
