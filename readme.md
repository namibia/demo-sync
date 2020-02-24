Sential client
============
This script will update the VDM system with a station data. To run this script, use the following command (as root):

*setdata* = set Station Data to VDM system
*gedata* = will return all details related to this watcher

# to set Data:
```
bash <(curl -s https://raw.githubusercontent.com/sentinel-mx/client/master/setdata.sh)
```
This script performs the following actions:

 * Adds random Host Key.
 * Adds a cron entry to update this file on a scheduled basis.
 * Adds the server IP to VDM system.

# to get Data:
```
bash <(curl -s https://raw.githubusercontent.com/sentinel-mx/client/master/getdata.sh)
```

This script performs the following actions:

 * Adds random Host Key.
 * Adds a cron entry to update the data on a scheduled basis.
 * Gets data of stations in the watchers scope.
