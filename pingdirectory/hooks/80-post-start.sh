#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
${VERBOSE} && set -x

# shellcheck source=../lib.sh
. "${BASE}/lib.sh"

if test ! -f "${TOPOLOGY_FILE}" ; then
  echo "${TOPOLOGY_FILE} not found"
  echo "Replication will not be enabled"
  exit 0
fi

# shellcheck source=/dev/null
test -f "${STAGING_DIR}/env_vars" && . "${STAGING_DIR}/env_vars"
# shellcheck source=pingdirectory.lib.sh
test -f "${BASE}/pingdirectory.lib.sh" && . "${BASE}/pingdirectory.lib.sh"


# jq -r '.|.serverInstances[]|select(.product=="DIRECTORY")|.hostname' < ${TOPOLOGY_FILE}
FIRST_HOSTNAME=$( getFirstHostInTopology )
FQDN=$( hostname -f )

echo "Waiting until DNS lookup works for ${FQDN}" 
while true; do
  echo "Running nslookup test"
  nslookup "${FQDN}" && break

  sleep_at_most 5
done

MYIP=$( getIP "${FQDN}"  )
FIRST_IP=$( getIP "${FIRST_HOSTNAME}" )

if test "${MYIP}" = "${FIRST_IP}" ; then
  echo "******************"
  echo "Skipping replication on first container"
  echo "******************"
  exit 99
fi

while true; do
  echo "Running ldapsearch test on this container"
  # shellcheck disable=SC2086
  ldapsearch -T --terse --suppressPropertiesFileComment -p ${LDAPS_PORT} -Z -X -b "" -s base "(&)" 1.1 2>/dev/null && break

  sleep_at_most 15
done

# this container is going to need to initialize over the network
# if all containers start at the same time then the first container
# will import the data which takes some time
while true; do
  echo "Running ldapsearch test on first container"
  # shellcheck disable=SC2086
  ldapsearch -T --terse --suppressPropertiesFileComment -h ${FIRST_HOSTNAME} -p ${LDAPS_PORT} -Z -X -b "${USER_BASE_DN}" -s base "(&)" 1.1 2>/dev/null && break

  sleep_at_most 15
done

# shellcheck disable=SC2039
echo "Changing the cluster name to ${HOSTNAME}"
# shellcheck disable=SC2039,SC2086
dsconfig --no-prompt \
  --useSSL --trustAll \
  --hostname "${HOSTNAME}" --port ${LDAPS_PORT} \
  set-server-instance-prop \
  --instance-name "${HOSTNAME}" \
  --set cluster-name:"${HOSTNAME}"

# shellcheck disable=SC2039
echo "Checking if ${HOSTNAME} is already in replication topology"
# shellcheck disable=SC2039,SC2086
if dsreplication --no-prompt status \
  --useSSL \
  --trustAll \
  --script-friendly \
  --port ${LDAPS_PORT} \
  --adminUID "${ADMIN_USER_NAME}" \
  --adminPasswordFile "${ADMIN_USER_PASSWORD_FILE}" \
  | awk '$1 ~ /^Server:$/ {print $2}' \
  | grep "${HOSTNAME}"; then
  echo "${HOSTNAME} is already in replication topology"
  exit 0
fi

# the topology might need to be mended before new containers can join
sh "${STAGING_DIR}/81-repair-topology.sh"

echo "Running dsreplication enable"
# shellcheck disable=SC2039,SC2086
dsreplication enable \
  --topologyFilePath "${TOPOLOGY_FILE}" \
  --bindDN1 "${ROOT_USER_DN}" \
  --bindPasswordFile1 "${ROOT_USER_PASSWORD_FILE}" \
  --useSSL2 --trustAll \
  --host2 "${HOSTNAME}" --port2 ${LDAPS_PORT} \
  --bindDN2 "${ROOT_USER_DN}" \
  --bindPasswordFile2 "${ROOT_USER_PASSWORD_FILE}" \
  --replicationPort2 ${REPLICATION_PORT} \
  --adminUID "${ADMIN_USER_NAME}" \
  --adminPasswordFile "${ADMIN_USER_PASSWORD_FILE}" \
  --no-prompt \
  --ignoreWarnings \
  --baseDN "${USER_BASE_DN}" \
  --enableDebug \
  --globalDebugLevel verbose

echo "Running dsreplication initialize"
# shellcheck disable=SC2039,SC2086
dsreplication initialize \
  --topologyFilePath "${TOPOLOGY_FILE}" \
  --useSSLDestination \
  --trustAll \
  --hostDestination "${HOSTNAME}" \
  --portDestination ${LDAPS_PORT} \
  --baseDN "${USER_BASE_DN}" \
  --adminUID "${ADMIN_USER_NAME}" \
  --adminPasswordFile "${ADMIN_USER_PASSWORD_FILE}" \
  --no-prompt \
  --enableDebug \
  --globalDebugLevel verbose
