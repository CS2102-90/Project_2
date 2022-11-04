/* ----- TRIGGERS     ----- */
/* Trigger #1 Enforce constraint Users === {Creators, Backers} */
CREATE OR REPLACE FUNCTION not_backer()
RETURNS TRIGGER AS $$
DECLARE
  count NUMERIC;
BEGIN
  SELECT COUNT(*) INTO count 
  FROM  Backers
  WHERE NEW.email = Backers.email /* Creators.email */

  IF (count > 0) THEN
    RETURN NULL;
  ELSE 
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER non_backer
BEFORE INSERT ON Creators
FOR EACH ROW EXECUTE FUNCTION not_backer();

CREATE OR REPLACE FUNCTION not_creator()
RETURNS TRIGGER AS $$
DECLARE
  count NUMERIC;
BEGIN
  SELECT COUNT(*) INTO count 
  FROM  Creators
  WHERE NEW.email = Creators.email /* Creators.email */

  IF (count > 0) THEN
    RETURN NULL;
  ELSE 
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER non_creator
BEFORE INSERT ON Backers
FOR EACH ROW EXECUTE FUNCTION not_creator();

/* Trigger #2  Enforce constraint that (backer's pledge amount) >= (reward level minium amount) */
CREATE OR REPLACE FUNCTION check_reward_amount()
RETURNS TRIGGER AS $$
DECLARE
  minimal NUMERIC;
BEGIN
  SELECT  min_amt INTO minimal
  FROM    Rewards
  WHERE   NEW.name = Rewards.name
  AND NEW.id = Rewards.id  

  IF (NEW.amount >= minimal) THEN
    RETURN NEW;
  ELSE 
    RETURN NULL;
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
  count INTEGER;
BEGIN 
  SELECT COUNT(*) INTO count 
  FROM Rewards 
  WHERE Rewards.id = NEW.id
  IF (count > 0) THEN
    RETURN NEW;
  ELSE 
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER project_no_reward 
BEFORE INSERT ON Projects
DEFERRABLE INITIALLY IMMEDIATE
FOR EACH ROW EXECUTE FUNCTION check_project_no_reward();

/* Trigger #4 */
CREATE OR REPLACE FUNCTION check_refund()
RETURNS TRIGGER AS $$
DECLARE 
  check DATE;
  ddl DATE;
BEGIN 
  SELECT request INTO check
  FROM Backs 
  WHERE NEW.email = Backs.email
  AND NEW.pid = Backs.id

  SELECT deadline INTO ddl 
  FROM Projects
  WHERE NEW.pid = Projects.id

  IF (check IS NOT NULL) THEN
  BEGIN 
    ddl := DATEADD(DD, -90, ddl)
    IF (ddl >= check) THEN
      RETURN NEW;
    ELSE 
      RETURN (NEW.email, NEW.pid, NEW.eid, NEW.date, FALSE);
    END IF;
  END
  ELSE 
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE Trigger check_valid_refund
BEFORE INSERT ON Refunds
FOR EACH ROW EXECUTE FUNCTION check_refund();

/* Trigger #5 */
CREATE OR REPLACE FUNCTION check_backs()
RETURNS TRIGGER AS $$
DECLARE 
  ddl DATE;
BEGIN 

  SELECT deadline INTO ddl 
  FROM Projects
  WHERE NEW.pid = Projects.id

  IF (ddl >= NEW.backing) THEN
    RETURN NEW;
  ELSE 
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE Trigger check_valid_refund
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
  WHERE NEW.pid = Backs.id 
  
  SELECT goal, deadline INTO goal, ddl
  FROM Projects
  WHERE Projects.id = NEW.pid 

  IF (total_plegde >= goal) AND (NEW.date > ddl) THEN
    RETURN NEW;
  ELSE 
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE Trigger check_valid_refund
BEFORE INSERT OR UPDATE ON Refunds
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
BEGIN
  -- your code here
  INSERT INTO Users VALUES (email, name, cc1, cc2);
  
  IF kind = "BACKER" THEN
    INSERT INTO Backers VALUES (email,  street, num, zip, country);
  ELSE IF kind = "CREATOR" THEN
    INSERT INTO Creators VALUES (email, country);
  ELSE IF kind = "BOTH" THEN
  BEGIN
    INSERT INTO Backers VALUES (email,  street, num, zip, country);
    INSERT INTO Creators VALUES (email, country);
  END
  END IF;
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
  SET CONSTRAINTS project_no_reward DEFFERED;
  -- your code here
  INSERT INTO Projects VALUES (id, email, ptype, created, deadline, goal);
  cur_idx := 0;
  WHILE (cur_idx < array_length(names, 1))
  BEGIN
    INSERT INTO Rewards VALUES (id, names[cur_idx], amounts[cur_idx]);
    cur_idx := cur_idx + 1;
  END
  COMMIT;
END;
$$ LANGUAGE plpgsql;



/* Procedure #3 */
CREATE OR REPLACE PROCEDURE auto_reject(
  eid INT, today DATE
) AS $$
-- add declaration here
DECLARE 
  emails TEXT[]
  pids INT[]
  cur_ind = 0
BEGIN
  -- your code here
  SELECT b.email, b.id INTO emails, pids
  FROM Backs b, Prokects p
  WHERE b.request is not NULL
  AND b.id = p.id
  HAVING SELECT DATEADD(DD, -90, p.deadline) > b.request;

  cur_ind := 0;
  WHILE (cur_ind < array_length(emails, 1))
  BEGIN
    INSERT INTO Refunds VALUES (emails[cur_ind], pids[cur_ind], eid, today, FALSE);
    cur_ind := cur_ind + 1;
  END

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
  SELECT email, name 
  FROM Backers, Users,
  WHERE Backers.email = Users.email
  AND Backers.email IN ((SELECT email
                        FROM Backers NATURAL JOIN Backs, Projects
                        WHERE Backers.email in (SELECT email FROM Verifies)
                        AND Backs.id IN  (SELECT id
                                            FROM Projects p, Backs b 
                                            WHERE p.id = b.id 
                                            AND deadline >= SELECT DATEADD(day, -30, today)
                                            AND today > deadline
                                            GROUP BY p.id 
                                            HAVING SUM(b.amount) >= p.goal )
                        AND Backs.id = Projects.id 
                        GROUP BY email
                        HAVING COUNT(Projects.id) >= 5
                        AND COUNT(DISTINCT Projects.ptype) >= 3)
                        UNION
                        (SELECT email
                        FROM Backers NATURAL JOIN Backs
                        WHERE Backers.email IN (SELECT email FROM Vertifies)
                        AND NOT EXISTS (SELECT *
                                        FROM Backs z
                                        WHERE Backers.email = z.email
                                        AND z.request IS NOT NULL)
                        AND NOT EXISTS (SELECT * 
                                        FROM Refunds
                                        WHERE Backers.email = Refunds.email)

                        AND Backs.id IN (SELECT id
                                            FROM Projects p, Backs b 
                                            WHERE p.id = b.id 
                                            AND deadline >= SELECT DATEADD(day, -30, today)
                                            AND today > deadline
                                            GROUP BY p.id 
                                            HAVING SUM(b.amount) >= p.goal )
                        GROUP BY email
                        HAVING SUM(amount) >= 1500))
  ORDER BY email ASC;
END;
$$ LANGUAGE plpgsql;



/* Function #2  */
CREATE OR REPLACE FUNCTION find_top_success(
  n INT, today DATE, ptype TEXT
) RETURNS TABLE(id INT, name TEXT, email TEXT,
                amount NUMERIC) AS $$
  BEGIN
    SELECT p.id, p.email, (SUM(b.ammount) / p.goal) AS success_metric
    FROM Projects p, Backs b
    WHERE p.id = b.id 
    AND today >= p.deadline
    AND p.ptype = ptype
    GROUP BY p.id 
    ORDER BY success_metric DESC, deadline DESC, p.id
    LIMIT n;
  END;
$$ LANGUAGE sql;



/* Function #3  */
CREATE OR REPLACE FUNCTION find_top_popular(
  n INT, today DATE, ptype TEXT
) RETURNS TABLE(id INT, name TEXT, email TEXT,
                days INT) AS $$
-- add declaration here
BEGIN
  -- your code here
  SELECT p.id, p.email, DATEDIFF(day, p.created, MIN(d.backing)) as day_nums
  FROM Projects p, (SELECT id, backing, (SELECT SUM(amount)
                                        FROM Backs b
                                        WHERE b.id = id 
                                        AND b.backing <= backing) AS date_money
                    FROM Backs
                    GROUP BY id, backing) AS d
  WHERE p.id = d.id 
  AND p.ptype = ptype
  AND p.created >= today
  AND d.date_money >= p.goal 
  ORDER BY day_nums, p.id ASC;
END;
$$ LANGUAGE plpgsql;
/* ------------------------ */