FROM ubuntu:16.04

MAINTAINER Sebastian Stanisor <sebastain@gene42.com>

#ENV CATALINA_HOME /usr/local/tomcat
#ENV PATH $CATALINA_HOME/bin:$PATH
#RUN mkdir -p "$CATALINA_HOME"
#WORKDIR $CATALINA_HOME

USER root

RUN apt-get update && apt-get install -y openjdk-8-jdk tomcat8 unzip

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd --create-home --shell /bin/sh phenotips

USER phenotips
WORKDIR /home/phenotips

COPY gene42-niaid-phenotips-standalone-1.1-rc-1.zip ./

RUN unzip gene42-niaid-phenotips-standalone-1.1-rc-1.zip

RUN rm gene42-niaid-phenotips-standalone-1.1-rc-1.zip

ENTRYPOINT ["/bin/sh", "./gene42-niaid-phenotips-standalone-1.1-rc-1/start.sh"]
