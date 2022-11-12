INSERT INTO Users VALUES ('e0200@u.nus.edu','Iron Man','DBS1213','OCVBC123');

SELECT * FROM Users;

CALL add_user('e0000@u.nus.edu','Iron Man','DBS10232','DBS28391',
			  'Manhatthan','237','1238123','United States','BOTH');
CALL add_user('e0001@u.nus.edu','Iron Man','DBS10232','DBS28391',
			  'Manhatthan','237','1238123','United States','CREATOR');

SELECT * FROM Backers;


SELECT * FROM Users;