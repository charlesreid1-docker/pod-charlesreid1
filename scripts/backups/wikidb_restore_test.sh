#!/bin/bash
#
# Restore a wikidb dump into a throwaway MySQL 5.7 container and run sanity
# queries against it. Compares row counts to live stormy_mysql. Exits non-zero
# on any failure.
#
# Usage:
#   ./wikidb_restore_test.sh <path-to-dump.sql>
#
# A backup is only a backup if you have actually restored from it.
set -euo pipefail

DUMP="${1:-}"
if [ -z "${DUMP}" ] || [ ! -f "${DUMP}" ]; then
    echo "Usage: $0 <path-to-wikidb-dump.sql>" >&2
    exit 1
fi

LIVE_CONTAINER="stormy_mysql"
TEST_CONTAINER="wikidb_restore_test_$$"
TEST_PW="temp_restore_test_pw_$$"
IMAGE="mysql:5.7"

cleanup() {
    docker stop "${TEST_CONTAINER}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "[1/5] Starting throwaway MySQL container ${TEST_CONTAINER}..."
docker run -d --rm \
    --name "${TEST_CONTAINER}" \
    -e MYSQL_ROOT_PASSWORD="${TEST_PW}" \
    "${IMAGE}" >/dev/null

echo "[2/5] Waiting for MySQL to accept authenticated connections..."
# `mysqladmin ping` returns OK before the root user is actually set up, so we
# have to probe with a real authenticated query and accept only success.
ready=0
for i in $(seq 1 60); do
    if docker exec -e MYSQL_PWD="${TEST_PW}" "${TEST_CONTAINER}" \
        mysql -uroot -e 'SELECT 1' >/dev/null 2>&1; then
        ready=1
        break
    fi
    sleep 2
done
if [ "${ready}" -ne 1 ]; then
    echo "ERROR: MySQL in ${TEST_CONTAINER} never became ready." >&2
    docker logs "${TEST_CONTAINER}" 2>&1 | tail -20 >&2
    exit 4
fi

echo "[3/5] Piping dump into throwaway MySQL..."
docker exec -i -e MYSQL_PWD="${TEST_PW}" "${TEST_CONTAINER}" \
    mysql -uroot < "${DUMP}"

echo "[4/5] Querying restored DB..."
restored=$(docker exec -e MYSQL_PWD="${TEST_PW}" "${TEST_CONTAINER}" \
    mysql -uroot -N -B -e "
        USE wikidb;
        SELECT COUNT(*) FROM page;
        SELECT COUNT(*) FROM revision;
        SELECT COUNT(*) FROM text;
        SELECT COALESCE(MAX(rev_timestamp), 'none') FROM revision;
    ")

echo "--- restored ---"
echo "${restored}"

echo "[5/5] Querying live ${LIVE_CONTAINER}..."
LIVE_PW="$(docker exec "${LIVE_CONTAINER}" printenv MYSQL_ROOT_PASSWORD)"
live=$(docker exec -e MYSQL_PWD="${LIVE_PW}" "${LIVE_CONTAINER}" \
    mysql -uroot -N -B -e "
        USE wikidb;
        SELECT COUNT(*) FROM page;
        SELECT COUNT(*) FROM revision;
        SELECT COUNT(*) FROM text;
        SELECT COALESCE(MAX(rev_timestamp), 'none') FROM revision;
    ")

echo "--- live ---"
echo "${live}"

r_page=$(echo "${restored}"   | sed -n '1p')
r_rev=$(echo  "${restored}"   | sed -n '2p')
r_text=$(echo "${restored}"   | sed -n '3p')
l_page=$(echo "${live}"       | sed -n '1p')
l_rev=$(echo  "${live}"       | sed -n '2p')
l_text=$(echo "${live}"       | sed -n '3p')

fail=0
for kind in page rev text; do
    r_var="r_${kind}"
    l_var="l_${kind}"
    r="${!r_var}"
    l="${!l_var}"
    if [ "${r}" != "${l}" ]; then
        echo "MISMATCH: ${kind} count restored=${r} live=${l}" >&2
        fail=1
    else
        echo "OK: ${kind} count = ${r}"
    fi
done

if [ "${fail}" -ne 0 ]; then
    echo "RESTORE TEST FAILED." >&2
    exit 5
fi

echo "RESTORE TEST PASSED."
