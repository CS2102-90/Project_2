
In Postgres server: create a database called "project_2_db"

```sh
psql
CREATE DATABASE project_2_db
```

To drop database use:
```sh
psql
DROP DATABASE project_2_db
```

In this directory (Project_2), create initial database by: 
```sh
chmod +x ./test.sh
./test.sh
```

To test function 3 for example:
```sh
psql -d project_2_db -f test/f3.sql
```