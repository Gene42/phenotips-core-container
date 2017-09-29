FROM openjdk:8u131-jre-alpine

MAINTAINER Sebastian Stanisor <sebastain@gene42.com>
ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.20
ENV TOMCAT_USER tomcat${TOMCAT_MAJOR}
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH

ENV KEYS_URL "https://www.apache.org/dist/tomcat/tomcat-8/KEYS"
ENV TOMCAT_ASC_URL "https://www.apache.org/dist/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz.asc"
ENV TOMCAT_TGZ_URL "https://www.apache.org/dist/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"

RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

RUN apk add --no-cache gnupg

RUN set -x \
	\
	&& apk add --no-cache --virtual .fetch-deps \
		ca-certificates \
		tar \
		openssl \
		unzip \
		wget \
  && { \
    wget -O KEYS "$KEYS_URL" \
  ; } \
	&& { \
		wget -O tomcat.tar.gz "$TOMCAT_TGZ_URL" \
	; } \
	&& { \
		wget -O tomcat.tar.gz.asc "$TOMCAT_ASC_URL" \
	; } \
	&& gpg --import KEYS \
	&& gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm tomcat.tar.gz* \
  && adduser -D -u 9000 ${TOMCAT_USER} \
	&& apk add --no-cache bash \
	&& find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' +

COPY target/solr-configuration.jar ./
RUN mkdir -p /var/lib/phenotips/conf
RUN mkdir -p /var/lib/phenotips/solr
RUN unzip solr-configuration.jar -d /var/lib/phenotips/solr
RUN rm solr-configuration.jar
RUN chown ${TOMCAT_USER}:${TOMCAT_USER} -R /var/lib/phenotips/
#RUN chown ${TOMCAT_USER}:${TOMCAT_USER} -R data

RUN rm -r ./webapps/ROOT
RUN mkdir -p ./webapps/ROOT

COPY target/gene42-phenotips-core.war ./
RUN unzip gene42-phenotips-core.war -d ./webapps/ROOT/
RUN rm gene42-phenotips-core.war

COPY src/main/sh/start-container.sh $CATALINA_HOME/bin
RUN chmod +x $CATALINA_HOME/bin/start-container.sh
RUN chown ${TOMCAT_USER}:${TOMCAT_USER} -R $CATALINA_HOME

USER ${TOMCAT_USER}

EXPOSE 8080
ENTRYPOINT ["start-container.sh"]
CMD []
