#!/bin/bash
# Ce script récupère les photos d'une année depuis s3 vers $PHOTOS
# Attention, le répertoire de l'année doit être présent

../s3sync/s3sync.rb $2 -rsv --delete --exclude="Picasa|Thumbs" boudala:photos/$1/ $PHOTOS/$1
