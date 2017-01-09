#!/bin/sh

date=`date "+%Y-%m-%dT%H_%M_%S"`
TARGET=/Users/sludin/tmp/rsync/protocol-acme
HOST=home2
USER=sludin

rsync -azP \
  --delete \
  --delete-excluded \
  --exclude-from=$HOME/.rsync/exclude \
  --link-dest=../current \
  $TARGET $USER@$HOST:Backups/incomplete_back-$date \
  && ssh $USER@$HOST \
  "mv Backups/incomplete_back-$date Backups/back-$date \
  && rm -f Backups/current \
  && ln -s back-$date Backups/current"
