#!/usr/bin/with-contenv bash
# shellcheck shell=bash

set -eo pipefail
EXITCODE=0

FA_IPS=$(piaware-config -show adept-serverhosts | cut -d '{' -f 2 | cut -d '}' -f 1)
FA_PORT=$(piaware-config -show adept-serverport)
NETSTAT_AN=$(netstat -an)

CONNECTED=""
for FA_IP in $FA_IPS; do
    IP_DOTS=${FA_IP//./\\.}
    REGEX="^\s*tcp\s+\d+\s+\d+\s+(?>\d{1,3}\.{0,1}){4}:\d{1,5}\s+(?>${IP_DOTS}):(?>${FA_PORT})\s+ESTABLISHED\s*$"
    if echo "$NETSTAT_AN" | grep -P "$REGEX" > /dev/null 2>&1; then
        CONNECTED="true"
        break 2
    fi
done

if [[ -z "$CONNECTED" ]]; then
    echo "No connection to Flightaware, NOT OK."
    EXITCODE=1
else
    echo "Connected to Flightaware, OK."
fi

REGEX="^(?'date'\d{4}-\d{1,2}-\d{1,2})\s+(?'time'\d{1,2}:\d{1,2}:[\d\.]+)\s+\[piaware\]\s+(?'date2'\d{4}\/\d{1,2}\/\d{1,2})\s+(?'time2'\d{1,2}:\d{1,2}:[\d\.]+)\s+\d+ msgs recv'd from the ADS-B data program at ${BEAST_HOST}\/${BEAST_PORT} \(\K(?'msgslast5m'\d+) in last 5m\);\s+\d+ msgs sent to FlightAware\s*$"
NB_MSGS_HOUR=$(tail -$((12 * 10)) /var/log/piaware/current | grep -oP "$REGEX" | tail "-12" | tr -s " " | cut -d " " -f 1)
TOTAL_MSGS=0
for NB_MSGS in $NB_MSGS_HOUR; do
    TOTAL_MSGS=$((TOTAL_MSGS + NB_MSGS))
done

if [[ "$TOTAL_MSGS" -gt 0 ]]; then
    echo "$TOTAL_MSGS messages sent in past hour, OK."
else
    echo "$TOTAL_MSGS messages sent in past hour, NOT OK."
    EXITCODE=1
fi

exit $EXITCODE
