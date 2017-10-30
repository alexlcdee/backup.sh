# Configurable backup script

For backup place ${SERVER_NAME}.sh config in conf/ directory. For example:

```bash
#!/bin/bash

SSH_ALIAS="root@host"

REMOTE_DIR=/path/to/files/for/backup/
EXCLUDE="rsync/exclude"

MYSQL_USER="user"
MYSQL_PASSWORD="password"
```
## Here list of configurable options that might be set in conf/$_SERVER.sh

`SSH_ALIAS` — ssh server connection string. E.g.: "root@host" 

`REMOTE_DIR` — path to files for backup

`EXCLUDE` — exlude pattern for rsync. Defaults to `"backup"`

`BACKUP_MYSQL` — whether or not backup MySQL databases. `BACKUP_MYSQL=1` to backup. Defaults to `1`

`MYSQL_USER` — MySQL server username. Defaults to `"root"`

`MYSQL_PASSWORD` — MySQL server user password. Defaults to empty string
