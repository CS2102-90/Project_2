/* ----- TRIGGERS     ----- */
/* Trigger #1 Enforce constraint Users === {Creators, Backers} */
CREATE OR REPLACE FUNCTION user_must_be_backer_or_creator()
RETURNS TRIGGER AS $$
DECLARE
  count1 NUMERIC;
  count2 NUMERIC;
BEGIN
  SELECT COUNT(*) INTO count1
			  FROM  Backers
			  WHERE NEW.email = Backers.email; /* Creators.email */

  SELECT COUNT(*) INTO count2
			  FROM Creators
			  WHERE NEW.email = Creators.email;
  
  IF (count1 > 0) OR (count2 > 0) THEN
    RETURN NEW;
  ELSE 
  	RAISE EXCEPTION 'Neither Backer nor Creator';
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER backer_or_creator
AFTER INSERT ON Users
DEFERRABLE INITIALLY IMMEDIATE
FOR EACH ROW EXECUTE FUNCTION user_must_be_backer_or_creator();


/* Trigger #2  Enforce constraint that (backer's pledge amount) >= (reward level minium amount) */
CREATE OR REPLACE FUNCTION check_reward_amount()
RETURNS TRIGGER AS $$
DECLARE
  minimal NUMERIC;
BEGIN
  SELECT  min_amt INTO minimal
  FROM    Rewards
  WHERE   NEW.name = Rewards.name
  AND NEW.id = Rewards.id ; 

  IF (NEW.amount >= minimal) THEN
    RETURN NEW;
  ELSE 
    BEGIN
      RAISE NOTICE 'Backers must pledge an amount greater
      than or equal to the minimum amount';
      RETURN NULL;
    END;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_reward_min
BEFORE INSERT ON Backs
FOR EACH ROW EXECUTE FUNCTION check_reward_amount();

/* Trigger #3  Enforce constraint Project === Has. Each project has at least one reward level */
CREATE OR REPLACE FUNCTION check_project_no_reward()
RETURNS TRIGGER AS $$
DECLARE 
  count1 INTEGER;
BEGIN 
  SELECT COUNT(*) INTO count1
  FROM Rewards 
  WHERE Rewards.id = NEW.id;
  IF (count1 > 0) THEN
    RETURN NEW;
  ELSE 
  	RAISE EXCEPTION 'Project has no reward';
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER project_no_reward 
AFTER INSERT ON Projects
DEFERRABLE INITIALLY IMMEDIATE
FOR EACH ROW EXECUTE FUNCTION check_project_no_reward();

/* Trigger #4 */
CREATE OR REPLACE FUNCTION check_refund()
RETURNS TRIGGER AS $$
DECLARE 
  checkk DATE;
  ddl DATE;
BEGIN 
  SELECT request INTO checkk
  FROM Backs 
  WHERE NEW.email = Backs.email
  AND NEW.pid = Backs.id;

  SELECT deadline INTO ddl 
  FROM Projects
  WHERE NEW.pid = Projects.id;

  IF (checkk IS NULL) OR (NEW.date < checkk) THEN
     RETURN NULL;
  END IF;

  BEGIN
    ddl := (ddl + interval '90 day');
    IF (ddl >= checkk) THEN
      RETURN NEW;
    ELSE 
      RETURN (NEW.email, NEW.pid, NEW.eid, NEW.date, FALSE);
    END IF;
  END;

END;
$$ LANGUAGE plpgsql;

CREATE Trigger check_valid_refund1
BEFORE INSERT ON Refunds
FOR EACH ROW EXECUTE FUNCTION check_refund();

/* Trigger #5 */
CREATE OR REPLACE FUNCTION check_backs()
RETURNS TRIGGER AS $$
DECLARE 
  crt DATE;
  ddl DATE;
BEGIN 

  SELECT deadline, created INTO ddl, crt
  FROM Projects
  WHERE NEW.id = Projects.id;

  IF (crt <= NEW.backing) AND (NEW.backing <= ddl) THEN
    RETURN NEW;
  ELSE 
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE Trigger check_back
BEFORE INSERT ON Backs
FOR EACH ROW EXECUTE FUNCTION check_backs();

/* Trigger #6 */
CREATE OR REPLACE FUNCTION check_refund_request()
RETURNS TRIGGER AS $$
DECLARE 
  ddl DATE;
  goal NUMERIC;
  total_plegde NUMERIC;
BEGIN 
  SELECT sum(amount) INTO total_plegde 
  FROM Backs
  WHERE NEW.id = Backs.id ;
  
  SELECT p.goal, p.deadline INTO goal, ddl
  FROM Projects p
  WHERE p.id = NEW.id ;

  IF (total_plegde >= goal) AND (NEW.request > ddl) THEN
    RETURN NEW;
  ELSE 
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE Trigger check_valid_refund
BEFORE UPDATE ON Backs
FOR EACH ROW EXECUTE FUNCTION check_refund_request();
/* ------------------------ */





/* ----- PROECEDURES  ----- */
/* Procedure #1 */
CREATE OR REPLACE PROCEDURE add_user(
  email TEXT, name    TEXT, cc1  TEXT,
  cc2   TEXT, street  TEXT, num  TEXT,
  zip   TEXT, country TEXT, kind TEXT
) AS $$
-- add declaration here
  -- your code here
BEGIN
	SET CONSTRAINTS backer_or_creator DEFERRED;
	INSERT INTO Users VALUES (email, name, cc1, cc2);

	IF (kind = 'BACKER') THEN
		INSERT INTO Backers VALUES (email,  street, num, zip, country);
	ELSIF (kind = 'CREATOR') THEN
		INSERT INTO Creators VALUES (email, country);
	ELSIF (kind = 'BOTH') THEN
	BEGIN
		INSERT INTO Backers VALUES (email,  street, num, zip, country);
		INSERT INTO Creators VALUES (email, country);
	END;
	END IF;
  -- Thong: Comment commit out
	--COMMIT;
END;
$$ LANGUAGE plpgsql;



/* Procedure #2 */
CREATE OR REPLACE PROCEDURE add_project(
  id      INT,     email TEXT,   ptype    TEXT,
  created DATE,    name  TEXT,   deadline DATE,
  goal    NUMERIC, names TEXT[],
  amounts NUMERIC[]
) AS $$
-- add declaration here
DECLARE
  cur_idx INT;
BEGIN
  SET CONSTRAINTS project_no_reward DEFERRED;
  -- your code here
  INSERT INTO Projects VALUES (id, email, ptype, created, name, deadline, goal);
  -- Thong cur_idx from 0 to 1
  cur_idx := 1;
  WHILE (cur_idx <= array_length(names, 1))
  LOOP
    INSERT INTO Rewards VALUES (names[cur_idx], id, amounts[cur_idx]);
    cur_idx := cur_idx + 1;
  END LOOP;
  -- Thong: comment commit out
  --COMMIT;
END;
$$ LANGUAGE plpgsql;



/* Procedure #3 */
CREATE OR REPLACE PROCEDURE auto_reject(
  eid INT, today DATE
) AS $$
-- add declaration here
DECLARE 
  emaill TEXT;
  pidd INT;
  cur_ind INT;
BEGIN
  -- your code here
  FOR emaill, pidd IN
    SELECT b.email, b.id 
    FROM Backs b, Projects p
    WHERE b.request is not NULL
    AND b.id = p.id
    AND p.deadline + interval '90 day' > b.request

  --Only insert into Refunds table if (email, pid) not yet exists
  LOOP
    IF NOT EXISTS (
      SELECT * FROM
      Refunds r 
      WHERE r.email = emaill
      AND r.pid = pidd 
    ) THEN
      INSERT INTO Refunds VALUES (emaill, pidd, eid, today, FALSE);
    END IF;
  END LOOP;

END;
$$ LANGUAGE plpgsql;
/* ------------------------ */





/* ----- FUNCTIONS    ----- */
/* Function #1  */
CREATE OR REPLACE FUNCTION find_superbackers(
  today DATE
) RETURNS TABLE(email TEXT, name TEXT) AS $$
-- add declaration here
BEGIN
  -- your code here 
  RETURN QUERY
  SELECT Backers.email, Users.name 
  FROM Backers , Users
  WHERE Backers.email = Users.email
  AND Backers.email IN ((SELECT bb.email
                        FROM Backers NATURAL JOIN Backs AS bb, Projects
                        WHERE bb.email in (SELECT Verifies.email FROM Verifies)
                        AND bb.id IN  (SELECT p.id
                                            FROM Projects p, Backs b 
                                            WHERE p.id = b.id 
                                            AND deadline >= (SELECT (today - interval '30 day'))
                                            AND today > deadline
                                            GROUP BY p.id 
                                            HAVING SUM(b.amount) >= p.goal )
                        AND bb.id = Projects.id 
                        GROUP BY bb.email
                        HAVING COUNT(Projects.id) >= 5
                        AND COUNT(DISTINCT Projects.ptype) >= 3)
                        UNION
                        (SELECT bb.email
                        FROM Backers NATURAL JOIN Backs AS bb
                        WHERE bb.email IN (SELECT Verifies.email FROM Verifies)
                        AND NOT EXISTS (SELECT *
                                        FROM Backs z
                                        WHERE Backers.email = z.email
                                        AND z.request IS NOT NULL
									    AND z.request >= (SELECT (today - interval '30 day')))
                        AND NOT EXISTS (SELECT * 
                                        FROM Refunds
                                        WHERE Backers.email = Refunds.email
									    AND Refunds.date >= (SELECT (today - interval '30 day')))

                        AND bb.id IN (SELECT p.id
                                            FROM Projects p, Backs b 
                                            WHERE p.id = b.id 
                                            AND deadline >= (SELECT (today - interval '30 day'))
                                            AND today > deadline
                                            GROUP BY p.id 
                                            HAVING SUM(b.amount) >= p.goal )
                        GROUP BY bb.email
                        HAVING SUM(amount) >= 1500))
  ORDER BY email ASC;
END;
$$ LANGUAGE plpgsql;

/* Function #2  */
CREATE OR REPLACE FUNCTION find_top_success(
  n INT, today DATE, ptypee TEXT
) RETURNS TABLE(id INT, name TEXT, email TEXT,
                amount NUMERIC) AS $$
	SELECT p.id, p.name, p.email, SUM(b.amount) AS amount
	FROM Projects p, Backs b
	WHERE p.id = b.id 
	AND today >= p.deadline
	AND p.ptype = ptypee
	GROUP BY p.id, p.name 
	ORDER BY (SUM(b.amount) / p.goal) DESC, deadline DESC, p.id
	LIMIT n;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION closest_date_goal(
  p_id INT, created DATE, goal NUMERIC, today DATE
) RETURNS INT AS $$
DECLARE
  backing_date DATE;
  amount  NUMERIC;
  pledged_amount NUMERIC;
BEGIN
  pledged_amount := 0;
  FOR backing_date, amount IN
    SELECT b.backing, b.amount
    FROM Backs b
    WHERE b.backing <= today AND b.id = p_id
    ORDER BY b.backing ASC
  LOOP
    pledged_amount := pledged_amount + amount;
    IF pledged_amount >= goal THEN
      RETURN backing_date - created;
    END IF;
  END LOOP;
  RETURN NULL;
END; $$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS find_top_popular;

/* Function #3  */
CREATE OR REPLACE FUNCTION find_top_popular(
  n INT, today DATE, p_typee TEXT
) RETURNS TABLE(id INT, name TEXT, email TEXT, days INT) AS $$
BEGIN
  RETURN QUERY
  WITH projects_with_finish_interval as (SELECT p.id, closest_date_goal(p.id, p.created, p.goal, today) as interval
  FROM Projects p)
  SELECT p.id, p.name, p.email, projects_with_finish_interval.interval
  FROM
    Projects p, projects_with_finish_interval
  WHERE p.id = projects_with_finish_interval.id 
    AND p.ptype = p_typee 
    AND projects_with_finish_interval.interval IS NOT NULL 
    AND p.created < today
  ORDER BY projects_with_finish_interval.interval ASC, p.id ASC
  LIMIT n;
END;
$$ LANGUAGE plpgsql;
/* ------------------------ */