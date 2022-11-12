INSERT INTO Projects VALUES (56, 'e2221223@u.nus.edu','Tech',
                            '2022-11-10','Smurf','2023-11-10',10000);
SELECT * FROM Projects;

CALL add_project(56, 'e0001@u.nus.edu','Tech',
				 '2022-11-10', 'Smurf', '2023-11-10', 
				 10000, ARRAY['bronze','silver','gold'],ARRAY[1000,2000,3000]);

SELECT * FROM Projects