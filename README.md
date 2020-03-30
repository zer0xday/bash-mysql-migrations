# bash-mysql-migrations

Simple script creating migrations for MySQL databases.
If you have a pleasure to use legacy frameworks that didn't have their own migration scripts - feel free to use.

## Requirements

- Bash
- MySQL client

## How to use?

1. Clone
2. Put your SQL files to `queries` directory
3. Copy `config.sh.dist`  to `config.sh`
4. Set your database credentials in `config.sh` you can change migrations table name as well
5. Run script `./migrate.sh`

**To create new query file you can use `create.sh` script, e.g.: `./create.sh add-sample-column` will make new sql file with actual date and your task name given as parameter**

Enjoy!
