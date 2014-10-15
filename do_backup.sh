#!/bin/bash

set -x

current_dir="$(dirname "$0")"
source "$current_dir/env.sh"
cd /

function backup_db {
	find "$BACKUP_DB_PATH" -mtime "+$BACKUP_DB_NOT_OLDER" -type f -delete

	for dbname in "${BACKUP_POSTGRES[@]}"
	do
		sudo -u postgres pg_dump $dbname | gzip -9 > "$BACKUP_DB_PATH/postgres/$dbname-$(date +"%Y-%m-%d").sql.gz"
	done
	for dbname in "${BACKUP_MYSQL[@]}"
	do
		mysqldump -u root -p$BACKUP_MYSQL_ROOTPW $dbname | gzip -9 > "$BACKUP_DB_PATH/mysql/$dbname-$(date +"%Y-%m-%d").sql.gz"
	done
}

function backup_files {
	duplicity -v5 remove-older-than $BACKUP_FILES_REMOVE_IF_OLDER --force $BACKUP_TARGETPATH 2>&1 | tee -a $BACKUP_LOG "/tmp/backup-$(date +"%Y-%m-%d").log"

		#--dry-run \
	duplicity \
		-v5 \
		--no-encryption \
		--full-if-older-than $BACKUP_FILES_FULL_IF_OLDER \
		--volsize $BACKUP_FILES_VOLSIZE \
		--include-globbing-filelist $BACKUP_FILELIST \
		/ $BACKUP_TARGETPATH 2>&1 | tee -a $BACKUP_LOG "/tmp/backup-$(date +"%Y-%m-%d").log"

	mail -s "$BACKUP_EMAIL_SUBJECT" $BACKUP_EMAIL_RECIPIENTS < "/tmp/backup-$(date +"%Y-%m-%d").log"
}

backup_db
backup_files
