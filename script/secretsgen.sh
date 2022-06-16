#!/bin/bash
set -euo pipefail

OUTPUT_FILE="$1"

if [ ! -f "${OUTPUT_FILE}" ]; then
  cat <<EOF > ${OUTPUT_FILE}
generated_secrets:
  influxdb_admin_password: "$(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1)"
  influxdb_telegraf_password: "$(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1)"
EOF
  echo "Generated secrets in ${OUTPUT_FILE}"
else
  echo "${OUTPUT_FILE} already exists - reusing generated secrets"
fi

