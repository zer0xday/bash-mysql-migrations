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
printf "\n\n"

MYSQL="mysql -N -s -u$DB_USER -p$DB_PASS $DB_NAME"

if [ $(${MYSQL} -e "${SCHEMA_QUERY}") -eq 1 ]; then
    echo "Table ${MIGRATIONS_TABLE} exists!";
else
    echo "Table ${MIGRATIONS_TABLE} does not exist"
    echo "Creating ${MIGRATIONS_TABLE} table..."

    $MYSQL -e "$TABLE_QUERY";

    if [ $(${MYSQL} -e "${SCHEMA_QUERY}") -eq 1 ]; then
      echo "Table ${MIGRATIONS_TABLE} created successfuly!"
    else
      echo "For some reason I couldn't create ${MIGRATIONS_TABLE} table :("
      printf "\nTerminating...\n"
      exit 1
    fi
fi

printf "\n\n"
echo "Migrating files..."

for filePath in $FILES; do
    FILE=${filePath##*/}
    printf "\n\n"
    echo "----------------------------------"
    echo "Found file: ${FILE}"

    if [ $(${MYSQL} -e "SELECT COUNT(*) FROM ${MIGRATIONS_TABLE} WHERE filename='${FILE}'") -eq 1 ]; then
        printf "$FILE already migrated. ${YELLOW}Skipping...${NC}\n"
        echo "----------------------------------"
        continue
    fi

    # add transaction handlers to queries file
    QUERY="BEGIN; $(cat ${filePath}) COMMIT;";

    # execute modified query
    ${MYSQL} -e "${QUERY}";

    if [ "$?" -eq 0 ]; then
        echo "----------------------------------"
        echo "**********************************"
        printf "************ Query ${GREEN}OK${NC} ************\n"
        echo "**********************************"

        SAVE_MIGRATION_QUERY="INSERT INTO ${MIGRATIONS_TABLE} VALUES (null, '${FILE}', NOW())"
        ${MYSQL} -e "${SAVE_MIGRATION_QUERY}"
    else
        CORRUPTED_FILES+=("${FILE}")

        while true; do
          printf "\n*!!!* File ${RED}corrupted${NC}. Would you like to skip this one and continue? (y/n): ";
          read -p "" choice
          case $choice in
              [Yy]* ) printf "\n$FILE ${YELLOW}skipped${NC}"; break;;
              [Nn]* ) printf "\nTerminating...\n"; exit;;
              * ) echo "Please answer yes or no.";;
          esac
        done
    fi
    echo "----------------------------------"
done

printf "\n\n"
echo "----------****DONE****------------"
echo "---"

if [ ${#CORRUPTED_FILES[@]} -eq 0 ]; then
    printf "    Migration ${GREEN}OK${NC}!\n";
else
    printf "    Migration ${GREEN}OK${NC}, but...\n";
    printf "    ${RED}Corrupted${NC} files: ${CORRUPTED_FILES[*]}\n";
fi

echo "---"
echo "----------****DONE****------------"

printf "\n\n"

exit 1
