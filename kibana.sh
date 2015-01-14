#!/bin/bash
# #################################################################
# NAME: kibana.sh
# DESC: Kibana/nginx startup file.
#
# LOG:
# yyyy/mm/dd [user] [version]: [notes]
# 2014/11/11 cgwong v0.1.0: Initial creation
# 2015/01/14 cgwong v0.2.0: Added Kibana 4.
#                           For now just using Kibana w/o nginx.
# #################################################################

# Set environment
ES_PORT_9200_TCP_ADDR=${ES_PORT_9200_TCP_ADDR:-localhost}
ES_PORT_9200_TCP_PORT=${ES_PORT_9200_TCP_PORT:-9200}
ES_PORT_9200_TCP_PROTO=${ES_PORT_9200_TCP_PROTO:-http}
ES_URL="${ES_PORT_9200_TCP_PROTO}://${ES_PORT_9200_TCP_ADDR}:${ES_PORT_9200_TCP_PORT}"

KIBANA_BASE=${KIBANA_BASE:-"/var/www"}
KIBANA_HOME=${KIBANA_HOME:-"$KIBANA_BASE/kibana"}
KIBANA_VERSION=${KIBANA_VERSION:-"4.0.0-beta3"}
KIBANA_INDEX=${KIBANA_INDEX:-kibana-int}

# Check for Kibana version
if [ `echo "$KIBANA_VERSION" | cut -d '.' -f1` == "4"]; then
  sed -i "s;^elasticsearch:.*;elasticsearch: ${ES_URL}" "${KIBANA_HOME}/config/kibana.yml"
##  sed -i "s;^kibana_index:.*;kibana_index: ${KIBANA_INDEX};" "${KIBANA_HOME}/config/kibana.yml"
else
  # Setup for Kibana 3.x using config.js
  sed -e "s/http:\/\/\"+window.location.hostname+\":9200/${ES_PORT_9200_TCP_PROTO}:\/\/${ES_PORT_9200_TCP_ADDR}:${ES_PORT_9200_TCP_PORT}/" -i ${KIBANA_HOME}/config.js
  cp ${KIBANA_HOME}/config.js /usr/share/nginx/html/config.js
fi

# if `docker run` first argument start with `--` the user is passing launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
##  exec nginx "$@"
  exec ${KIBANA_HOME}/bin/kibana "$@"
fi

# As argument is not Elasticsearch, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
