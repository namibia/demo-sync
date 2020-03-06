Sync Websites
============
This script will setup a sync between websites. To run this script, use the following command (as root):

# Run Sync:
```
bash <(curl -s https://raw.githubusercontent.com/namibia/demo-sync/master/sync.sh)
```
This script performs the following actions:

 * Adds a cron entry to update run this sync on a scheduled basis.
 * Adds folder and database setup file to use in scheduled syncs
