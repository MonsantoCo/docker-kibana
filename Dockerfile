# ################################################################
# NAME: Dockerfile
# DESC: Docker file to create Kibana image.
#
# LOG:
# yyyy/mm/dd [name] [version]: [notes]
# 2014/10/15 cgwong [v0.1.0]: Initial creation.
# 2014/11/11 cgwong v0.2.0: Updated sed command.
#                           Added environment variable for nginx config directory.
# 2014/12/03 cgwong v0.2.1: Updated Kibana version. Switch to specific nginx version.
# 2014/12/04 cgwong v0.2.2: Introduce more environment variables. Corrected bug in dashboard copy.
# 2015/01/08 cgwong v1.0.0: Added another variable.
# ################################################################

FROM dockerfile/ubuntu
MAINTAINER Stuart Wong <cgs.wong@gmail.com>

# Install Kibana
##ENV KIBANA_VERSION 4.0.0-BETA2
ENV KIBANA_VERSION 3.1.2
ENV KIBANA_BASE /var/www
ENV KIBANA_HOME ${KIBANA_BASE}/kibana
RUN mkdir -p ${KIBANA_BASE}
WORKDIR ${KIBANA_BASE}
RUN wget https://download.elasticsearch.org/kibana/kibana/kibana-${KIBANA_VERSION}.tar.gz \
  && tar zxf kibana-${KIBANA_VERSION}.tar.gz \
  && rm -f kibana-${KIBANA_VERSION}.tar.gz \
  && ln -s kibana-${KIBANA_VERSION} kibana

# Setup Kibana dashboards
COPY dashboards/ ${KIBANA_HOME}/app/dashboards/
RUN mv ${KIBANA_HOME}/app/dashboards/default.json ${KIBANA_HOME}/app/dashboards/default-org.json \
    && cp ${KIBANA_HOME}/app/dashboards/logstash.json ${KIBANA_HOME}/app/dashboards/default.json

# Setup nginx for proxy/authention for Kibana
ENV NGINX_VERSION 1.7.8-1~trusty
ENV NGINX_CFG_DIR /etc/nginx/conf.d
RUN wget -qO - http://nginx.org/keys/nginx_signing.key | sudo apt-key add -
RUN echo "deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list
RUN apt-get -y update && apt-get -y install \
    apache2-utils \
    nginx=${NGINX_VERSION}

# Forward standard out and error logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

# Expose persistent nginx configuration storage area
VOLUME ["${NGINX_CFG_DIR}"]

# Copy config and user password file into image
COPY conf/nginx-kibana.conf ${NGINX_CFG_DIR}/nginx-kibana.conf
COPY conf/kibana.localhost.htpasswd ${NGINX_CFG_DIR}/kibana.localhost.htpasswd
COPY kibana.sh /usr/local/bin/kibana.sh

# Copy in kibana.yml file for verion 4.x
##COPY config/kibana.yml ${KIBANA_BASE}/kibana/conf/kibana.yml
# Setup for Kibana 3.x using config.js
##RUN sed -e 's/"+window.location.hostname+"/localhost/' -i ${KIBANA_BASE}/kibana/config.js \
##    && cp ${KIBANA_BASE}/kibana/config.js /usr/share/nginx/html/config.js

# Listen for connections on HTTP port/interface: 80
EXPOSE 80
# Listen for SSL connections on HTTPS port/interface: 443
EXPOSE 443

# Define default command.
ENTRYPOINT ["/usr/local/bin/kibana.sh"]
