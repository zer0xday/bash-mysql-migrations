#!/bin/bash
. $(dirname $0)/config.sh

read -srp "Enter your database password: " DB_PASS

until mysql -s -u$DB_USER -p$DB_PASS $DB_NAME -e ";" ; do
    read -srp "Can't connect to database, please retry: " DB_PASS
done

echo "Connected to database successfuly!"

if [ $(mysql -N -s -u$DB_USER -p$DB_PASS -e "${SCHEMA_QUERY}") -eq 1 ]; then
    echo "Table ${MIGRATIONS_TABLE} exists!";
else
    echo "Table ${MIGRATIONS_TABLE} does not exist"
    echo "Creating ${MIGRATIONS_TABLE} table..."
    TABLE_QUERY="CREATE TABLE ${MIGRATIONS_TABLE} (\
      id INT AUTO_INCREMENT, \
      filename VARCHAR(255), \
      created_at DATETIME, \
      PRIMARY KEY(id), \
      UNIQUE (filename)
    );";

    mysql -u$DB_USER -p$DB_PASS $DB_NAME -e "$TABLE_QUERY";

    if [ $(mysql -N -s -u$DB_USER -p$DB_PASS -e "${SCHEMA_QUERY}") -eq 1 ]; then
      echo "Table ${MIGRATIONS_TABLE} created successfuly!"
    else
      echo "For some reason I couldn't create ${MIGRATIONS_TABLE} table :("
      echo "Terminating..."
      exit 1
    fi
fi

echo "Migrating files..."

for filePath in $FILES; do
    FILE=${filePath##*/}
    echo "Found file: ${FILE}"

    if [ $(mysql -N -s -u$DB_USER -p$DB_PASS $DB_NAME -e \
      "SELECT COUNT(*) FROM migrations WHERE filename='${FILE}'") -eq 1 ]; then
        echo "$FILE already migrated. Skipping..."
        continue
    fi

    mysql -N -s -u$DB_USER -p$DB_PASS $DB_NAME < $filePath;

    if [ "$?" -eq 0 ]; then
        echo "Query OK"
        SAVE_MIGRATION_QUERY="INSERT INTO ${MIGRATIONS_TABLE} VALUES (null, '${FILE}', NOW())"
        mysql -N -s -u$DB_USER -p$DB_PASS $DB_NAME -e "${SAVE_MIGRATION_QUERY}"
    else
        CORRUPTED_FILES+=("${FILE}")
        echo "Query incorrect. Skipping..."
    fi
done

if [ ${#CORRUPTED_FILES[@]} -eq 0 ]; then
    echo "Migration OK!"
else
    echo "Migration OK, but"
    echo "Corrupted files: ${CORRUPTED_FILES[*]}"
fi

exit 1
