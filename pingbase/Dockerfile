#- # Ping Identity Docker Image - `pingbase`
#- 
#- This docker image provides a base image for all Ping Identity DevOps 
#- product images.  Primarly, the builder can provide an argument, `SHIM`,
#- that will be used to determine the base OS used when building.  The options
#- include:
#- - alpine (default)
#- - centos
#- - ubuntu
#-
#- ## Related Docker Images
#- - `openjdk:8-jre-alpine` - Parent Image for `SHIM=alpine`
#- - `centos` - Parent Image for `SHIM=cenots`
#- - `ubuntu:disco` - Parent Image for `SHIM=ubuntu`
#-

# Default to Alpine
ARG SHIM=alpine

#
# Ubuntu disco OpenJDK11 shim
#
FROM ubuntu:disco as shim-ubuntu
ONBUILD LABEL	maintainer=devops_program@pingidentity.com \
		license="Ping Identity Proprietary" \
		vendor="Ping Identity Corp." \
		name="Ping Identity (Ubuntu/OpenJDK11) Image"

ONBUILD RUN apt -y update \
        && apt -y  upgrade \
        && apt -y install apt-utils \
        && apt -y install  openjdk-11-jdk curl gettext-base dnsutils git jq unzip \
        && apt-get -y autoremove \
        && rm -rf /var/lib/apt/lists/* \ 
        && mkdir -p ${BASE}/tests


#
# Centos shim
#
FROM centos as shim-centos
ONBUILD LABEL	maintainer=devops_program@pingidentity.com \
		license="Ping Identity Proprietary" \
		vendor="Ping Identity Corp." \
		name="Ping Identity (CentOS/OpenJDK11) Image"

ONBUILD RUN yum update -y \
        && yum upgrade -y \
        && yum -y install epel-release \
        && yum -y install java-11-openjdk-devel gettext bind-utils git jq unzip \
        && yum -y autoremove \
        && yum -y clean all \
        && rm -rf /var/cache/yum \
        && mkdir -p ${BASE}/tests
        

#
# The good shim
# 
FROM openjdk:8-jre-alpine as shim-alpine
ONBUILD LABEL	maintainer=devops_program@pingidentity.com \
		license="Ping Identity Proprietary" \
		vendor="Ping Identity Corp." \
		name="Ping Identity (Alpine/OpenJDK8) Image"
        
ONBUILD RUN apk --no-cache add git curl ca-certificates jq zip \
    && apk add --update libintl \
    && apk add --virtual build_deps gettext \
    && cp /usr/bin/envsubst /usr/local/bin/envsubst \
    && apk del build_deps \
    && mkdir -p ${BASE}/tests


FROM shim-${SHIM} 

# the image base /might/ be changed at build-time but
# be aware that the entrypoint will have to be
# overridden to reflect the change
#-- Location of the top level directory where everything is located in 
#-- image/container
ONBUILD ARG BASE
ONBUILD ENV BASE=${BASE:-/opt}
#-- Location of a local server-profile volume
ONBUILD ENV IN_DIR=${BASE}/in
#-- Path to the runtime volume
ONBUILD ENV OUT_DIR=${BASE}/out
#-- Path to a volume generically used to export or backup data
ONBUILD ENV BAK_DIR=${BASE}/backup
#-- Default path to the secrets
ONBUILD ENV SECRETS_DIR=/usr/local/secrets

#-- Path to the staging area where the remote and local server profiles
#-- can be merged
ONBUILD ENV STAGING_DIR=${BASE}/staging
#-- Path to the topology file
ONBUILD ENV TOPOLOGY_FILE=${STAGING_DIR}/topology.json
#-- Path where all the hooks scripts are stored
ONBUILD ENV HOOKS_DIR=${STAGING_DIR}/hooks
#-- Path where the remote server profile is checked out or cloned before
#-- being staged prior to being applied on the runtime
ONBUILD ENV SERVER_PROFILE_DIR=/tmp/server-profile
#-- A valid git HTTPS URL (not ssh)
ONBUILD ENV SERVER_PROFILE_URL=""
#-- A valid git branch (optional)
ONBUILD ENV SERVER_PROFILE_BRANCH=""
#-- The subdirectory in the git repo
ONBUILD ENV SERVER_PROFILE_PATH=""
#-- Whether to update the server profile upon container restart
ONBUILD ENV SERVER_PROFILE_UPDATE="false"
#-- Path from which the runtime executes
ONBUILD ENV SERVER_ROOT_DIR=${OUT_DIR}/instance
#-- License directory and filename
ONBUILD ENV LICENSE_DIR="${SERVER_ROOT_DIR}"
#-- The command that the entrypoint will execute in the foreground to 
#-- instantiate the container
ONBUILD ENV STARTUP_COMMAND=""
#-- The command-line options to provide to the the startup command when 
#-- the container starts with the server in the foreground. This is the 
#-- normal start flow for the container
ONBUILD ENV STARTUP_FOREGROUND_OPTS=""
#-- The command-line options to provide to the the startup command when 
#-- the container starts with the server in the background. This is the 
#-- debug start flow for the container
ONBUILD ENV STARTUP_BACKGROUND_OPTS=""

#-- A whitespace separated list of log files to tail to the container 
#-- standard output
ONBUILD ENV TAIL_LOG_FILES=""

#-- Location default value
ONBUILD ENV LOCATION=Docker

#-- Heap size (for java products)
ONBUILD ENV MAX_HEAP_SIZE=384m

ONBUILD ENV JVM_TUNING="AGGRESSIVE"

#-- Triggers verbose messages in scripts using the set -x option.
ONBUILD ENV VERBOSE=false

#-- Set the server in debug mode, with increased output
ONBUILD ENV PING_DEBUG=false

#-- The name of Ping product.  Should be overridden by child images.
ONBUILD ENV PING_PRODUCT=""

#-- Port over which to communicate for LDAP
ONBUILD ENV LDAP_PORT=389
#-- Port over which to communicate for LDAPS
ONBUILD ENV LDAPS_PORT=636
#-- Port over which to communicate for HTTPS
ONBUILD ENV HTTPS_PORT=443
#-- Port for monitoring over JMX protocol
ONBUILD ENV JMX_PORT=689

ONBUILD ENV TOPOLOGY_SIZE=1
ONBUILD ENV TOPOLOGY_PREFIX=""
ONBUILD ENV TOPOLOGY_SUFFIX=""

ONBUILD ENV USER_BASE_DN=dc=example,dc=com
ONBUILD ENV DOLLAR='$'
ONBUILD ENV PD_ENGINE_PUBLIC_HOSTNAME="localhost"
ONBUILD ENV PF_ENGINE_PUBLIC_HOSTNAME="localhost"
ONBUILD ENV PF_ADMIN_PUBLIC_HOSTNAME="localhost"
ONBUILD ENV PA_ENGINE_PUBLIC_HOSTNAME="localhost"
ONBUILD ENV PA_ADMIN_PUBLIC_HOSTNAME="localhost"

#-- the default administrative user for PingData
ONBUILD ENV ROOT_USER_DN="cn=administrator"

ONBUILD ENV PATH="${BASE}:${SERVER_ROOT_DIR}/bin:${PATH}"

# the default evaluation user/key for obtaining DevOps License
ONBUILD ENV PING_IDENTITY_EVAL_USER="PingIdentityDevOpsEval"
ONBUILD ENV PING_IDENTITY_EVAL_KEY="e30a780b-481b-46dc-a47e-ac26d9457221"

# the method by which the framework can assess whether the container is viable or not
ONBUILD HEALTHCHECK --interval=31s --timeout=29s --start-period=241s --retries=7 CMD [ "liveness.sh" ]

ONBUILD VOLUME [ "${BAK_DIR}", "${IN_DIR}", "${OUT_DIR}" ]
ONBUILD WORKDIR ${BASE}
### WARNING THE ENTRYPOINT WILL NEED TO BE UPDATED MANUALLY IF THE BASE IS CHANGED
### IT DOES NOT EXPAND VARIABLES -- REAL BUMMER
ONBUILD ENTRYPOINT [ "entrypoint.sh" ]
ONBUILD CMD [ "start-server" ]