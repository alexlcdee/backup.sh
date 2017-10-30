#!/bin/bash

TMP_PATH=$1
MYSQL_USER=$2
MYSQL_PASSWORD=$3

mkdir -p $TMP_PATH

DATABASES=`mysql -u $MYSQL_USER --batch --skip-column-names -p$MYSQL_PASSWORD -e "show databases"`

for DB in $DATABASES; do
	if [ $DB == "information_schema" ] || [ $DB == "mysql" ] || [ $DB == "performance_schema" ]
	then
		continue
	fi
	
	echo "Dump database: $DB"
	
    mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $DB | gzip --best > $TMP_PATH/$DB.sql.gz
	
done

echo "Dumps created"