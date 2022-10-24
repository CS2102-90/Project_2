/* ----- TRIGGERS     ----- */


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
BEGIN
  -- your code here
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