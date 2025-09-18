#!/bin/bash

# Getting latest measurement interval number COMPLETED
latest=$(gnmic -a 172.20.20.109 -u grpc -p telemetry --insecure get --format flat --path "/state/oam-pm/session[session-name=toPeering]/ip/twamp-light/statistics/delay/measurement-interval[duration=5-mins]/newest-index" | awk -F': ' '{print $2}')
completed=$((latest-1))

echo "Latest Interval Number (in-progress): $latest"
echo "Latest completed Interval Number: $completed"

echo ""
echo "Fetching Average Round Trip Delay for the latest completed interval..."
echo "value should update every 5 mins. Stop the script and run it again if value is not updated"
echo "-----------------------------------------------"
gnmic -a 172.20.20.109 -u grpc -p telemetry --insecure subscribe --format flat --path "/state/oam-pm/session[session-name=toPeering]/ip/twamp-light/statistics/delay/measurement-interval[duration=5-mins]/number[mi-number=$completed]/bin-type[bin-metric=fd]/round-trip/average"