#!/bin/bash

_SCRIPT_DIR=$(dirname $([ -L $0 ] && readlink -f $0 || echo $0))
_DATE=$(date +"%Y-%m-%d")
_SERVER=$1

# Here list of configurable options that might be set in conf/$_SERVER.sh
SSH_ALIAS=""
REMOTE_DIR=""
EXCLUDE="*backup*"
BACKUP_MYSQL=1
MYSQL_USER="root"
MYSQL_PASSWORD=""

if [ "" != "$_SERVER" ] && [ -e $_SCRIPT_DIR/conf/$_SERVER.sh ]
then
	. $_SCRIPT_DIR/conf/$_SERVER.sh
else
	echo "Please specify server to backup"
	j=1
	declare -A _SERVERS=()
	for _FILE in $(ls $_SCRIPT_DIR/conf); do
		_SERVERS[$j]="${_FILE%.*}"
		echo "[${j}]" "${_FILE%.*}"
		((j++))
	done
	printf "Provide server number: "
	read _CONF_NUMBER
	_SERVER=${_SERVERS[$_CONF_NUMBER]}
	. $_SCRIPT_DIR/conf/$_SERVER.sh
fi

echo "Doing backup for server: $_SERVER"

_BACKUP_DIR="$(pwd)/$_SERVER/$_DATE"

if [ 1 == $BACKUP_MYSQL ]
then
	mkdir -p $_BACKUP_DIR/db
	echo "Backup Databases"
	ssh $SSH_ALIAS 'bash -s' < $_SCRIPT_DIR/mysqldump.sh /tmp/db $MYSQL_USER $MYSQL_PASSWORD

	echo "Download databases"
	rsync -avz $SSH_ALIAS:/tmp/db/ $_BACKUP_DIR/db

	echo "Remove dumps from server"
	ssh $SSH_ALIAS 'rm -rf /tmp/db'
fi

echo "Download sites"
mkdir -p $_BACKUP_DIR/sites
rsync -avz --exclude $EXCLUDE $SSH_ALIAS:$REMOTE_DIR $_BACKUP_DIR/sites