#!/bin/sh
# This is a comment

echo Hello World

psql -d project_2_db -f DDL.sql 

psql -d project_2_db -f Proc.sql

psql -d project_2_db -f test/init/add_user.sql

psql -d project_2_db -f test/init/add_employee.sql

psql -d project_2_db -f test/init/add_verified_users.sql

psql -d project_2_db -f test/init/add_project_types.sql

psql -d project_2_db -f test/init/add_project.sql

psql -d project_2_db -f test/init/add_backs.sql
