#!/bin/bash

# Check if hostname is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

NAGIOS_CMD_FILE="/var/lib/nagios4/rw/nagios.cmd"
STATUS_FILE="/var/lib/nagios4/status.dat"
HOST_NAME="$1"

# Get the current timestamp
CURRENT_TIME=$(date +%s)

# Find all downtime IDs and service names for the specified host
DOWNTIME_ENTRIES=$(awk -v host="$HOST_NAME" '
  BEGIN { RS = ""; FS = "\n" }
  /servicedowntime/ {
    for (i = 1; i <= NF; i++) {
      if ($i ~ /host_name=/ && $i ~ host) {
        downtime_id=""
        service_name=""
        for (j = i; j <= NF; j++) {
          if ($j ~ /downtime_id=/) {
            split($j, a, "=")
            downtime_id=a[2]
          }
          if ($j ~ /service_description=/) {
            split($j, b, "=")
            service_name=b[2]
          }
          if (downtime_id && service_name) {
            print downtime_id ";" service_name
            break
          }
        }
      }
    }
  }
' $STATUS_FILE)

# Find all downtime IDs for the specified host itself
HOST_DOWNTIME_IDS=$(awk -v host="$HOST_NAME" '
  BEGIN { RS = ""; FS = "\n" }
  /hostdowntime/ {
    for (i = 1; i <= NF; i++) {
      if ($i ~ /host_name=/ && $i ~ host) {
        for (j = i; j <= NF; j++) {
          if ($j ~ /downtime_id=/) {
            split($j, a, "=")
            print a[2]
            break
          }
        }
      }
    }
  }
' $STATUS_FILE)

# Check if any downtime entries were found
if [ -z "$DOWNTIME_ENTRIES" ] && [ -z "$HOST_DOWNTIME_IDS" ]; then
  echo "No downtime entries found for host $HOST_NAME"
  exit 1
fi

# Loop through each service downtime entry and construct the command to delete it
echo "$DOWNTIME_ENTRIES" | while IFS=";" read -r DOWNTIME_ID SERVICE_NAME; do
  COMMAND="[$CURRENT_TIME] DEL_SVC_DOWNTIME;$DOWNTIME_ID"
  # Append the command to the Nagios command file
  echo "$COMMAND" >> $NAGIOS_CMD_FILE
  # Echo the service name
  echo "Downtime cleared for service: $SERVICE_NAME"
done

# Loop through each host downtime ID and construct the command to delete it
echo "$HOST_DOWNTIME_IDS" | while read -r DOWNTIME_ID; do
  COMMAND="[$CURRENT_TIME] DEL_HOST_DOWNTIME;$DOWNTIME_ID"
  # Append the command to the Nagios command file
  echo "$COMMAND" >> $NAGIOS_CMD_FILE
  # Echo the host downtime cleared
  echo "Downtime cleared for host: $HOST_NAME"
done

echo "Downtime cleared for host $HOST_NAME and its services"
