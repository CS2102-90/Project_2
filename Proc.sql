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

  IF count > 0 THEN
    RETURN NULL;
  ELSE 
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER non_backer
BEFORE INSERT OR UPDATE ON Creators
FOR EACH ROW EXECUTE FUNCTION not_backer();

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

  IF NEW.amount > minimal THEN
    RETURN NEW;
  ELSE 
    RETURN (NEW.email, NEW.name, NEW.id, NEW.backing, NEW.request, minimal);
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_reward_min
BEFORE INSERT OR UPDATE ON Backs
FOR EACH ROW EXECUTE FUNCTION check_reward_amount();

/* Trigger #3  Enforce constraint Project === Has. Each project has at least one reward level */
CREATE OR REPLACE
RETURNS TRIGGER AS $$
BEGIN 

END;
$$ LANGUAGE plpgsql;

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
  reward_size INTEGER;
  amount_size INTEGER;
BEGIN
  -- your code here
  SET reward_size = CARDINALITY(names);
  SET amount_size = CARDINALITY(amounts);
  IF
    INSERT INTO Projects VALUES 
    (id, email, ptype, created, name, deadline, goal);
  END IF;
END;
$$ LANGUAGE plpgsql;



/* Procedure #3 */
CREATE OR REPLACE PROCEDURE auto_reject(
  eid INT, today DATE
) AS $$
-- add declaration here
BEGIN
  -- your code here
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
END;
$$ LANGUAGE plpgsql;



/* Function #2  */
CREATE OR REPLACE FUNCTION find_top_success(
  n INT, today DATE, ptype TEXT
) RETURNS TABLE(id INT, name TEXT, email TEXT,
                amount NUMERIC) AS $$
  SELECT 1, '', '', 0.0; -- replace this
$$ LANGUAGE sql;



/* Function #3  */
CREATE OR REPLACE FUNCTION find_top_popular(
  n INT, today DATE, ptype TEXT
) RETURNS TABLE(id INT, name TEXT, email TEXT,
                days INT) AS $$
-- add declaration here
BEGIN
  -- your code here
END;
$$ LANGUAGE plpgsql;
/* ------------------------ */