#!/bin/bash
# Ce script envoie les photos vers S3 pour une année seulement

# ./upload_thumbs.sh $1 $2 $3

#screen -S upyear$1 
../s3sync/s3sync.rb $2 -rsv --delete --exclude="Thumbs" $PHOTOS/$1/ $S3_ACCOUNT:photos/$1
