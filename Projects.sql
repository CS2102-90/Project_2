DROP TABLE IF EXISTS Employees, Users, Verifies, Backers, Creators, ProjectTypes, Projects, Updates, Rewards, Backs, Refunds CASCADE;

CREATE TABLE Employees (
  id     SERIAL PRIMARY KEY,
  name   VARCHAR(50) NOT NULL,
  salary NUMERIC NOT NULL CHECK (salary > 0)
);

CREATE TABLE Users (
  email  VARCHAR(50) PRIMARY KEY,
  name   VARCHAR(50) NOT NULL,
  cc1    VARCHAR(19) NOT NULL,
  cc2    VARCHAR(19)
);

CREATE TABLE Verifies (
  email    VARCHAR(50) PRIMARY KEY
    REFERENCES Users(email),
  id       INT NOT NULL REFERENCES Employees(id),
  verified DATE NOT NULL
);

CREATE TABLE Backers (
  email   VARCHAR(50) PRIMARY KEY
    REFERENCES Users(email) ON UPDATE CASCADE,
  street  VARCHAR(20) NOT NULL,
  num     VARCHAR(7)  NOT NULL,
  zip     VARCHAR(6)  NOT NULL,
  country VARCHAR(20) NOT NULL
);

CREATE TABLE Creators (
  email   VARCHAR(50) PRIMARY KEY
    REFERENCES Users(email) ON UPDATE CASCADE,
  country VARCHAR(20) NOT NULL
);

CREATE TABLE ProjectTypes (
  name  VARCHAR(50) PRIMARY KEY,
  id    INT NOT NULL REFERENCES Employees(id)
);

CREATE TABLE Projects (
  id       SERIAL PRIMARY KEY,
  email    VARCHAR(50) NOT NULL
    REFERENCES Creators(email) ON UPDATE CASCADE,
  ptype    VARCHAR(50) NOT NULL
    REFERENCES ProjectTypes(name) ON UPDATE CASCADE,
  created  DATE NOT NULL, -- alt: TIMESTAMP
  name     VARCHAR(50) NOT NULL,
  deadline DATE NOT NULL CHECK (deadline >= created),
  goal     NUMERIC NOT NULL CHECK (goal > 0)
);

CREATE TABLE Updates (
  time    TIMESTAMP,
  id      INT REFERENCES Projects(id)
    ON UPDATE CASCADE, -- ON DELETE CASCADE (optional)
  message TEXT NOT NULL,
  PRIMARY KEY (time, id)
);

CREATE TABLE Rewards (
  name    VARCHAR(20),
  id      INT REFERENCES Projects(id)
    ON UPDATE CASCADE, -- ON DELETE CASCADE (optional)
  min_amt NUMERIC NOT NULL CHECK (min_amt > 0),
  PRIMARY KEY (name, id)
);

CREATE TABLE Backs (
  email    VARCHAR(50) REFERENCES Backers(email),
  name     VARCHAR(20) NOT NULL,
  id       INT,
  request  DATE,
  amount   NUMERIC NOT NULL CHECK (amount > 0),
  -- status will be derived via queries instead
  PRIMARY KEY (email, id),
  FOREIGN KEY (name, id) REFERENCES Rewards(name, id)
);

CREATE TABLE Refunds (
  email    VARCHAR(50),
  pid      INT,
  eid      INT NOT NULL
    REFERENCES Employees(id),
  date     DATE NOT NULL,
  accepted BOOLEAN NOT NULL,
  PRIMARY KEY (email, pid),
  FOREIGN KEY (email, pid)
    REFERENCES Backs(email, id)
);