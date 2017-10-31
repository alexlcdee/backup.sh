#!/bin/bash

# Initialize default values
_CONF_DIR="$(dirname $([ -L $0 ] && readlink -f $0 || echo $0))/conf"
_BACKUP_DIR=$(pwd)
_SSH_COMMAND="/usr/bin/env ssh"
_RSYNC_COMMAND="/usr/bin/env rsync"
_BACKUP_ALL=0
_VERBOSE=""
_OUTPUT_REDIRECTION=" &>/dev/null 2>&1"

# Load config file by server name
# @param server name
require_conf() {
    __require_conf $1
}

__require_conf() {
    local __SERVER_NAME=$1
    if [ "" == "$__SERVER_NAME" ]
    then 
        echo "Server name does not specified"
        exit 1
    fi

    local __CONF_FILE="${_CONF_DIR}/${__SERVER_NAME}.conf"
    if [ ! -e $__CONF_FILE ]
    then
        echo "Config file ${__CONF_FILE} not found"
        exit 1
    fi

    # Reset variables to defaults
    SSH_ALIAS=""
    REMOTE_DIR=""
    RSYNC_OPTS="-az"
    BACKUP_MYSQL=1
    MYSQL_USER="root"
    MYSQL_PASSWORD=""

    # Import variables from conf file
    . $__CONF_FILE
}

# Backup data from MySQL server
# @param backup directory
backup_mysql() {
    __backup_mysql $1
}

__backup_mysql() {
    local __BACKUP_DIR=$1

    mkdir -p $__BACKUP_DIR/db
    if [ "-v" == "$_VERBOSE" ]
    then
        echo "Backup Databases"
    fi

    local __TMP_PATH="/tmp/db"

    local __MYSQLDUMP=$(cat <<ENDSCRIPT
mkdir -p $__TMP_PATH

DATABASES=\$(mysql \
 -u ${MYSQL_USER} \
 --batch \
 --skip-column-names \
 -p${MYSQL_PASSWORD} \
 -e "show databases")

for __DB in \$DATABASES; do
    if [ \$__DB == "information_schema" ] 
    then 
        continue 
    fi
    if [ \$__DB == "mysql" ]
    then
        continue
    fi
    if [ \$__DB == "performance_schema" ]
    then
        continue
    fi

    if [ "-v" == "${_VERBOSE}" ]
    then
        echo "Dump database: \$__DB"
    fi

    mysqldump -u ${MYSQL_USER} \
 -p${MYSQL_PASSWORD} \
 \$__DB | gzip --best > $__TMP_PATH/\$__DB.sql.gz
done

if [ "-v" == "${_VERBOSE}" ]
then
    echo "Dumps created"
fi
ENDSCRIPT
)

    ${_SSH_COMMAND} ${SSH_ALIAS} 'bash -c' "'${__MYSQLDUMP}'"

    if [ "-v" == "$_VERBOSE" ]
    then
        echo "Download databases"
    fi

    ${_RSYNC_COMMAND} "-az" ${_VERBOSE} "${SSH_ALIAS}:${__TMP_PATH}/" "${__BACKUP_DIR}/db"


    if [ "-v" == "$_VERBOSE" ]
    then
        echo "Remove dumps from server"
    fi
    ${_SSH_COMMAND} ${SSH_ALIAS} 'rm -rf /tmp/db'
}

# Backup files from server
# @param backup directory
backup_files() {
    __backup_files $1
}

__backup_files() {
    local __BACKUP_DIR=$1

    if [ "-v" == "$_VERBOSE" ]
    then
        echo "Download files"
    fi

    mkdir -p "${__BACKUP_DIR}/sites"

    ${_RSYNC_COMMAND} ${RSYNC_OPTS} ${_VERBOSE} "${SSH_ALIAS}:${REMOTE_DIR}" "${__BACKUP_DIR}/sites"
}

# Prompt server name from user
# @return string server name
prompt_server_name() {
    local __1
    __prompt_server_name __1
    eval $1=\$__1
}

__prompt_server_name() {
    local __j=1
    local -A __SERVER_NAMES=()
    local -i __CONF_NUMBER=0
    local __FILE

    echo "Please specify server to backup"

    for __FILE in $(ls $_CONF_DIR | grep .conf); do
        __SERVER_NAMES[$__j]="${__FILE%.*}"
        echo "[${__j}]" "${__FILE%.*}"
        ((__j++))
    done

    printf "Provide server number: "
    read __CONF_NUMBER

    eval $1="'${__SERVER_NAMES[$__CONF_NUMBER]}'"
}

# Backup data from single server
# @param server name
do_backup_single() {
    require_conf $1

    if [ "-v" == "$_VERBOSE" ]
    then
        echo "Doing backup for server: $1"
    fi

    local __BACKUP_DIR="${_BACKUP_DIR}/${1}/"$(date +"%Y-%m-%d")

    if [ 1 == $BACKUP_MYSQL ]
    then
        backup_mysql $__BACKUP_DIR
    fi

    backup_files $__BACKUP_DIR
}

# Perform backup by config
# @param optional server name
do_backup() {
    if [ 1 == $_BACKUP_ALL ]
    then
        local __FILE
        for __FILE in $(ls $_CONF_DIR | grep .conf); do
            do_backup_single "${__FILE%.*}"
    done
    else
        local __SERVER_NAME=$1
        if [ "" == "$__SERVER_NAME" ]
        then
            prompt_server_name __SERVER_NAME
        fi
        do_backup_single $__SERVER_NAME
    fi

    exit 0
}

print_help() {
    local __script_path=$1
    echo "
Usage: 
    ${__script_path} [option]... [<server_name>]

    Where <server_name> stands for config file from your config directory

Available options:
 -a, --all                  Backup sites from all configs in config directory
 -c, --conf-dir=DIR         Directory with server configs
 -b, --backup-dir=DIR       Directory to store backups
 -s, --ssh-command=FILE     SSH Client binary path
 -r, --rsync-command=FILE   Rsync binary path
 -v, --verbose              Verbose output
 -h, --help                 Print this help
"
    exit 0
}

for __option in "$@"
do
case "${__option}" in
    --all)
        _BACKUP_ALL=1
        shift
    ;;
    --conf-dir=*)
        _CONF_DIR="${__option#*=}"
        shift # past argument=value
    ;;
    --backup-dir=*)
        _BACKUP_DIR="${__option#*=}"
        shift # past argument=value
    ;;
    --ssh-command=*)
        _SSH_COMMAND="${__option#*=}"
        shift # past argument=value
    ;;
    --rsync-command=*)
        _RSYNC_COMMAND="${__option#*=}"
        shift # past argument=value
    ;;
    --help|-h)
        print_help $0
        shift
    ;;
    --verbose)
        _OUTPUT_REDIRECTION=""
        _VERBOSE="-v"
        shift
    ;;
    *)
    ;;
esac
done

OPTIND=1
while getopts "h?v?ac:b:s:r:" opt; do
case "$opt" in
    a)
        _BACKUP_ALL=1
    ;;
    c)  
        _CONF_DIR=$OPTARG
    ;;
    b)  
        _BACKUP_DIR=$OPTARG
    ;;
    s)  
        _SSH_COMMAND=$OPTARG
    ;;
    r)  
        _RSYNC_COMMAND=$OPTARG
    ;;
    h)
        print_help $0
    ;;
    v)
        _VERBOSE="-v"
        _OUTPUT_REDIRECTION=""
    ;;
esac
done
shift $((OPTIND-1))
[ "$1" = "--" ] && shift

do_backup $1
