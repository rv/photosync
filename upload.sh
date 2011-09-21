#!/bin/bash

../s3sync/s3sync.rb $1 -rsv --delete --exclude="Thumbs|.vignettes.jpg" $PHOTOS/ $S3_ACCOUNT:photos
#Idem avec docs

