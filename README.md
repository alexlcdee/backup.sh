# Configurable backup script

For backup create `conf/${SERVER_NAME}.conf` file with parameters for server. For example:

```bash
#!/bin/bash

SSH_ALIAS="root@host"

REMOTE_DIR="/path/to/files/for/backup/"

MYSQL_USER="user"
MYSQL_PASSWORD="password"
```
then run:
```bash
$ cd /path/to/my/backups
$ /path/to/backup.sh ${SERVER_NAME}
```

For select server from list of available just run:
```bash
$ cd /path/to/my/backups
$ /path/to/backup.sh
```
and you will be prompted for server number from list.

## Here list of configurable options that might be set in `conf/$_SERVER.conf`

`SSH_ALIAS` — ssh server connection string. E.g.: `"root@host"`

`REMOTE_DIR` — path to files for backup. E.g.: `"/var/www"`

`RSYNC_OPTS` — options for rsync. Defalts to `"-az"`

`BACKUP_MYSQL` — whether or not backup MySQL databases. `BACKUP_MYSQL=1` to backup. Defaults to `1`

`MYSQL_USER` — MySQL server username. Defaults to `"root"`

`MYSQL_PASSWORD` — MySQL server user password. Defaults to empty string

## Available options

```bash
 -a, --all                  Backup sites from all configs in config directory
 -c, --conf-dir=DIR         Directory with server configs
 -b, --backup-dir=DIR       Directory to store backups
 -s, --ssh-command=FILE     SSH Client binary path
 -r, --rsync-command=FILE   Rsync binary path
 -v, --verbose              Verbose output
 -h, --help                 Print this help
```

## Authentication on server
Basically, you will be prompted for shh password several times (based on ypur configuration). For passwordless authentication SSH keys for server without passphrases.

## Requirements
- rsync  version >=3.1.1
- OpenSSH client

## Requirements on server
- rsync  version >=3.1.1
- OpenSSH server
