#!/bin/bash
. $(dirname $0)/config.sh

if [ -z "$DB_PASS" ]; then
      read -srp "Enter your database password: " DB_PASS
      printf "\n"
fi

until mysql -s -u$DB_USER -p$DB_PASS $DB_NAME -e ";" ; do
    read -srp "Can't connect to database, enter password: " DB_PASS
    printf "\n"
done

echo "Connected to database successfuly!"

MYSQL="mysql -N -s -u$DB_USER -p$DB_PASS $DB_NAME"

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

    $MYSQL -e "$TABLE_QUERY";

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

    if [ $(${MYSQL} -e "SELECT COUNT(*) FROM migrations WHERE filename='${FILE}'") -eq 1 ]; then
        echo "$FILE already migrated. Skipping..."
        continue
    fi

    # add transaction handlers to queries file
    QUERY="BEGIN; $(cat ${filePath}) COMMIT;";

    # execute modified query
    ${MYSQL} -e "${QUERY}";

    if [ "$?" -eq 0 ]; then
        echo "Query OK"

        SAVE_MIGRATION_QUERY="INSERT INTO ${MIGRATIONS_TABLE} VALUES (null, '${FILE}', NOW())"
        ${MYSQL} -e "${SAVE_MIGRATION_QUERY}"
    else
        echo "Query incorrect. Skipping..."

        CORRUPTED_FILES+=("${FILE}")
    fi
done

if [ ${#CORRUPTED_FILES[@]} -eq 0 ]; then
    echo "Migration OK!"
else
    echo "Migration OK, but"
    echo "Corrupted files: ${CORRUPTED_FILES[*]}"
fi

exit 1
