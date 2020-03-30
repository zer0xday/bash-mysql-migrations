#!/bin/bash

QUERIES_DIR='./queries/';
NOW=$(date +"%Y_%m_%d_%H_%M_%S");
EXT='.sql';
NAME=$1;

if [ -z "$NAME" ]
then
  echo 'You need to pass action name as parameter, for e.g.: "add_sample_column"';
  exit;
fi

FIXED_NAME=$(tr '-' '_' <<<"$NAME");
FILENAME="${NOW}_${FIXED_NAME}${EXT}";

touch "${QUERIES_DIR}${FILENAME}";

if [ $? -eq 0 ]; then
    echo "${FILENAME} successfuly created.";
else
    echo "${FILENAME} couldn't be created. Please, try again.";
fi
