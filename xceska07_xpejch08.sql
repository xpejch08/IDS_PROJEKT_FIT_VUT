/*
  Destroying every table with the same name for safety first
*/
DROP TABLE REGISTER CASCADE CONSTRAINTS;
DROP TABLE COMMISION CASCADE CONSTRAINTS;
DROP TABLE STORAGE_WORKER CASCADE CONSTRAINTS;
DROP TABLE MERCHANT CASCADE CONSTRAINTS;
DROP TABLE INVOICE CASCADE CONSTRAINTS;
DROP TABLE PRODUCT CASCADE CONSTRAINTS;
DROP TABLE SUPPLY CASCADE CONSTRAINTS;
DROP TABLE PURCHASE CASCADE CONSTRAINTS;


-----------------------CREATING TABLES-----------------------

CREATE TABLE MERCHANT (
     ID INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
     FIRST_NAME VARCHAR2(30) NOT NULL,
     LAST_NAME VARCHAR2(30) NOT NULL,
     EMAIL VARCHAR2(100) NOT NULL
     CONSTRAINT email_ckm CHECK(REGEXP_LIKE(
         EMAIL, '^[a-z]+[a-z0-9\.]*@[a-z0-9\.-]+\.[a-z]{2,}$', 'i'
     )),
     ADDRESS VARCHAR2(100) NOT NULL
);

CREATE TABLE STORAGE_WORKER (
     ID INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
     FIRST_NAME VARCHAR2(30) NOT NULL,
     LAST_NAME VARCHAR2(30) NOT NULL,
     PHONE_NUMBER CHAR(9) NOT NULL
     CONSTRAINT phone_number_ck CHECK (PHONE_NUMBER BETWEEN '111111111' AND '999999999'),
     EMAIL VARCHAR2(100) NOT NULL
     CONSTRAINT email_ck CHECK(REGEXP_LIKE(
			EMAIL, '^[a-z]+[a-z0-9\.]*@[a-z0-9\.-]+\.[a-z]{2,}$', 'i'
	)),
     WAGE_IN_DOLLARS NUMBER(10, 2) NOT NULL
);

CREATE TABLE PRODUCT (
     ID INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
     NAME VARCHAR2(100) NOT NULL,
     ORIGIN VARCHAR2(100) NOT NULL,
     PRICE_IN_DOLLARS_FOR_KG NUMBER(10, 2) NOT NULL,
     AGE_IN_WEEKS INT NOT NULL,
     IN_STOCK_IN_TONS NUMBER(10, 2) DEFAULT 0 NOT NULL
);

CREATE TABLE REGISTER (
     ID INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
     TYPE SMALLINT DEFAULT 0 NOT NULL
     CONSTRAINT type_ck CHECK (TYPE BETWEEN 0 AND 1), /* 0 FOR PURCHASE 1 FOR SUPPLY */
     AMOUNT_IN_KG NUMBER(10, 2) NOT NULL,
     PRODUCT_ID INT REFERENCES PRODUCT(ID) ON DELETE SET NULL
);

-----SPECIALIZATION-----
--tabulka pro nadtyp + tabulka pro podtymy s primarnim klicem nadtypu
CREATE TABLE COMMISION (
     ID INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
     TYPE SMALLINT DEFAULT 0 NOT NULL
     CONSTRAINT type_ckc CHECK (TYPE BETWEEN 0 AND 1),
     REGISTER_ID INT REFERENCES REGISTER(ID) ON DELETE SET NULL,
     STORAGE_WORKER_ID INT DEFAULT NULL REFERENCES STORAGE_WORKER(ID) ON DELETE SET NULL,
     MERCHANT_ID INT REFERENCES MERCHANT(ID) ON DELETE SET NULL
);

CREATE TABLE SUPPLY (
     ID INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
     SUPPLY_DATE DATE NOT NULL,
     COMMISION_ID INT REFERENCES COMMISION(ID) ON DELETE SET NULL
);

CREATE TABLE PURCHASE (
     ID INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
     PURCHASE_DATE DATE NOT NULL,
     COMMISION_ID INT REFERENCES COMMISION(ID) ON DELETE SET NULL
);


CREATE TABLE INVOICE (
     ID INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
     INVOICE_DATE DATE NOT NULL,
     COMMISION_ID INT REFERENCES COMMISION(ID) ON DELETE SET NULL
);

-------------------------TRIGGERS---------------------------
---this trigger triggers every time the a new register is made, it subtracts/ads the the amount in kg used in the supply/order used in the register
CREATE OR REPLACE TRIGGER update_stock
AFTER INSERT OR UPDATE ON register
FOR EACH ROW
BEGIN
  IF :new.TYPE = 1 THEN
    UPDATE product SET in_stock_in_tons = in_stock_in_tons - :new.amount_in_kg/1000 WHERE id = :new.product_id;
  ELSE
    UPDATE product SET in_stock_in_tons = in_stock_in_tons + :new.amount_in_kg/1000 WHERE id = :new.product_id;
  END IF;
END;
/


---this trigger increments the wage in dollars of a worker every time he does some work by handeling a commision
CREATE OR REPLACE TRIGGER increment_storage_worker_wage
AFTER INSERT ON COMMISION
FOR EACH ROW
WHEN (NEW.STORAGE_WORKER_ID IS NOT NULL)
BEGIN
  UPDATE STORAGE_WORKER
  SET WAGE_IN_DOLLARS = WAGE_IN_DOLLARS + 1
  WHERE ID = :NEW.STORAGE_WORKER_ID;
END;
/


-----------------------INSERTING DATA-----------------------

INSERT INTO "PRODUCT" ("NAME", "ORIGIN", "PRICE_IN_DOLLARS_FOR_KG", "AGE_IN_WEEKS", "IN_STOCK_IN_TONS")
VALUES('TOMATO','SPAIN', 10, 3, 10);
INSERT INTO "PRODUCT" ("NAME", "ORIGIN", "PRICE_IN_DOLLARS_FOR_KG", "AGE_IN_WEEKS", "IN_STOCK_IN_TONS")
VALUES('APPLES', 'CZ', 12, 4, 20);
INSERT INTO "PRODUCT" ("NAME", "ORIGIN", "PRICE_IN_DOLLARS_FOR_KG", "AGE_IN_WEEKS", "IN_STOCK_IN_TONS")
VALUES('APPLES', 'FRANCE', 12, 4, 10);
INSERT INTO "PRODUCT" ("NAME", "ORIGIN", "PRICE_IN_DOLLARS_FOR_KG", "AGE_IN_WEEKS", "IN_STOCK_IN_TONS")
VALUES('CUCUMBERS', 'FRANCE', 12, 4, 50);



INSERT INTO "STORAGE_WORKER" ("FIRST_NAME", "LAST_NAME", "PHONE_NUMBER", "EMAIL", "WAGE_IN_DOLLARS")
VALUES('DOMINIK', 'MARTINU', '666666666', 'martinu@randmail.com', 10);
INSERT INTO "STORAGE_WORKER" ("FIRST_NAME", "LAST_NAME", "PHONE_NUMBER", "EMAIL", "WAGE_IN_DOLLARS")
VALUES('TOMAS', 'INDRUCH', '787878787', 'indruch@randmail.com', 20);
INSERT INTO "STORAGE_WORKER" ("FIRST_NAME", "LAST_NAME", "PHONE_NUMBER", "EMAIL", "WAGE_IN_DOLLARS")
VALUES('LADISLAV', 'DOBROMIL', '787878696', 'dobrakcz@randmail.com', 20);
INSERT INTO "STORAGE_WORKER" ("FIRST_NAME", "LAST_NAME", "PHONE_NUMBER", "EMAIL", "WAGE_IN_DOLLARS")
VALUES('TOMAS', 'ALFONZ', '787878777', 'alfonz@randmail.com', 30);

INSERT INTO "MERCHANT" ("FIRST_NAME", "LAST_NAME", "EMAIL", "ADDRESS")
VALUES('STEPAN', 'PEJCHAR', 'pejchar@randmail.com', 'VEVERI 12');
INSERT INTO "MERCHANT" ("FIRST_NAME", "LAST_NAME", "EMAIL", "ADDRESS")
VALUES('ONDREJ', 'CESKA', 'ceska@randmail.com', 'CESKA 1');

INSERT INTO "SUPPLY" ("SUPPLY_DATE", "COMMISION_ID")
VALUES(TO_DATE('12.01.2023', 'DD.MM.YYYY'), (SELECT ID FROM COMMISION WHERE TYPE = 1));
INSERT INTO "SUPPLY" ("SUPPLY_DATE", "COMMISION_ID")
VALUES(TO_DATE('09.02.2023', 'DD.MM.YYYY'), (SELECT ID FROM COMMISION WHERE TYPE = 0));

INSERT INTO "PURCHASE" ("PURCHASE_DATE", "COMMISION_ID")
VALUES(TO_DATE('12.01.2023', 'DD.MM.YYYY'), (SELECT ID FROM COMMISION WHERE TYPE = 1));
INSERT INTO "PURCHASE" ("PURCHASE_DATE", "COMMISION_ID")
VALUES(TO_DATE('09.02.2023', 'DD.MM.YYYY'), (SELECT ID FROM COMMISION WHERE TYPE = 0));

INSERT INTO "REGISTER" ("TYPE", "AMOUNT_IN_KG", "PRODUCT_ID")
VALUES(1, 100, (SELECT ID FROM PRODUCT WHERE NAME = 'APPLES' AND ORIGIN = 'FRANCE'));
INSERT INTO "REGISTER" ("TYPE", "AMOUNT_IN_KG", "PRODUCT_ID")
VALUES(1, 150, (SELECT ID FROM PRODUCT WHERE NAME = 'CUCUMBER' AND ORIGIN = 'FRANCE'));
INSERT INTO "REGISTER" ("TYPE", "AMOUNT_IN_KG", "PRODUCT_ID")
VALUES(0, 250, (SELECT ID FROM PRODUCT WHERE NAME = 'TOMATO'));
INSERT INTO "REGISTER" ("TYPE", "AMOUNT_IN_KG", "PRODUCT_ID")
VALUES(0, 300, (SELECT ID FROM PRODUCT WHERE NAME = 'TOMATO'));

INSERT INTO "COMMISION" ("TYPE", "REGISTER_ID", "STORAGE_WORKER_ID", "MERCHANT_ID")
VALUES(1, (SELECT ID FROM REGISTER WHERE AMOUNT_IN_KG = 250), 
          (SELECT ID FROM STORAGE_WORKER WHERE FIRST_NAME = 'TOMAS' AND  LAST_NAME = 'INDRUCH'), 
          (SELECT ID FROM MERCHANT WHERE FIRST_NAME = 'STEPAN' AND LAST_NAME = 'PEJCHAR'));
INSERT INTO "COMMISION" ("TYPE", "REGISTER_ID", "STORAGE_WORKER_ID", "MERCHANT_ID")
VALUES(0, (SELECT ID FROM REGISTER WHERE AMOUNT_IN_KG = 100), 
          (SELECT ID FROM STORAGE_WORKER WHERE FIRST_NAME = 'DOMINIK' AND  LAST_NAME = 'MARTINU'), 
          (SELECT ID FROM MERCHANT WHERE FIRST_NAME = 'ONDREJ' AND LAST_NAME = 'CESKA'));


INSERT INTO "INVOICE" ("INVOICE_DATE", "COMMISION_ID")
VALUES(TO_DATE('12.01.2023', 'DD.MM.YYYY'), (SELECT ID FROM COMMISION WHERE TYPE = 1));
INSERT INTO "INVOICE" ("INVOICE_DATE", "COMMISION_ID")
VALUES(TO_DATE('09.02.2023', 'DD.MM.YYYY'), (SELECT ID FROM COMMISION WHERE TYPE = 0));

----------------------- SELECTING DATA---------------------------------------------
--2 tables -- spoj tabulky register a product (v jakém rejstříku je jaký produkt)
SELECT p.name, r.ID, p.IN_STOCK_IN_TONS, p.ORIGIN
FROM product p
JOIN register r ON p.id = r.product_id;

SELECT s.FIRST_NAME, s.LAST_NAME, s.WAGE_IN_DOLLARS
FROM storage_worker s;

--2 tables -- spoj tabulky register a commision (v jaké zakázce je jaký rejstřík, kolik váží jeho produkt a kdo má zakázku má na starosti)
SELECT s.register_id, r.amount_in_kg, s.STORAGE_WORKER_ID
FROM register r
JOIN commision s ON r.id = s.register_id;



--3 tables --(id objednávky, jméno a příjmení zaměstnance, který ji má na starosti, a jméno a příjmení obchodníka, kterého se objednávka týká)
SELECT c.id, w.first_name AS krestni_skladnika, w.last_name AS prijmeni_skladnika, m.first_name AS krestni_obchodnika, m.last_name  AS prijmeni_obchodnika
FROM commision c
JOIN storage_worker w ON c.storage_worker_id = w.id
JOIN merchant m ON c.merchant_id = m.id;

--group by -- (celková hmotnost prodaného zboží podle země původu)(vyskytlo se v rejstříku objednávky)
SELECT p.origin, SUM(r.amount_in_kg)
FROM product p
JOIN register r ON p.id = r.product_id
GROUP BY p.origin;



SELECT p.ID, p.NAME, p.ORIGIN
FROM product p
WHERE EXISTS (
    SELECT 1
    FROM register c
    WHERE p.ID = c.PRODUCT_ID AND p.ORIGIN = 'FRANCE'
)
GROUP BY p.ID, p.NAME, p.ORIGIN;

-- This query returns the name of each product that has been purchased at least once.


-- EXISTS -- (vrací id, název a původ produktu, který se vyskytuje v rejstříku objednávky právě jednou nebo nulakrát)
SELECT DISTINCT p.id, p.name, p.origin
FROM PRODUCT p
WHERE NOT EXISTS (
  SELECT *
  FROM REGISTER r
  WHERE r.PRODUCT_ID = p.ID
  GROUP BY r.PRODUCT_ID
  HAVING COUNT(*) > 1
);

--IN -- (Vrací jméno a příjmení obchodníka a název produktu, který byl prodán v celkovém mmnožství větší než 400 kg)
SELECT m.first_name, m.last_name, p.name
FROM merchant m
JOIN commision c ON m.id = c.merchant_id
JOIN register r ON c.id = r.id
JOIN product p ON r.product_id = p.id
WHERE p.id IN (
    SELECT r2.product_id
    FROM register r2
    WHERE r2.type = 0
    GROUP BY r2.product_id
    HAVING SUM(r2.amount_in_kg) > 400
);
-- This query returns the first and last name of each merchant and the name of each product that has been purchased in total over 1000 kg.

------------PROCEDURES-----------------

-- Procedure that returns the average wage of a storage worker with a given first name.
SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE CalculateAvgWageFirstName
    (First IN STORAGE_WORKER.FIRST_NAME%TYPE)
AS
    AvgWage FLOAT;
BEGIN
    SELECT AVG(WAGE_IN_DOLLARS) INTO AvgWage
    FROM STORAGE_WORKER
    WHERE FIRST_NAME = First;
    DBMS_OUTPUT.PUT_LINE('The average wage for ' || First || ' is ' || AvgWage || '$' );
END;
/
-- Testing of this procedure. Expecting 25.5, since one worker has 21$ and the other 30$.
EXECUTE CalculateAvgWageFirstName('TOMAS');