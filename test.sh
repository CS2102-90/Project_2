#!/bin/sh
# This is a comment!
echo Hello World

psql -d hungkhoaitay -f DDL.sql 

psql -d hungkhoaitay -f Proc.sql

psql -d hungkhoaitay -f test/init/add_user.sql

psql -d hungkhoaitay -f test/init/add_employee.sql

psql -d hungkhoaitay -f test/init/add_project_types.sql

psql -d hungkhoaitay -f test/init/add_project.sql

psql -d hungkhoaitay -f test/init/add_backs.sql