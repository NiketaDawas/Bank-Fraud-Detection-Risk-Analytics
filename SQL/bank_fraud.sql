use bank_fraud;
select database();
create table transactions (
step int,
type varchar(20),
amount decimal(18,2),
nameOrig varchar(30),
oldbalanceOrg decimal(18, 2),
newbalanceOrig decimal(18,2),
nameDest varchar(30),
oldbalanceDest decimal(18,2),
newbalanceDest decimal(18,2),
isFraud tinyint,
isFlaggedFraud tinyint
);
select *from transactions ;
show tables;
describe transactions;
show variables like 'local_infile';
set global local_infile=1;

SELECT COUNT(*) AS total_transactions
FROM transactions;
select count(*) as total_fraud_transactions
from transactions
where isFraud=1;

-- Fraud Percentage
select round (
(sum(isFraud)/ count(*))*100,2)
as Fraud_percentage from transactions;
-- Total Fraud Amount
SELECT 
    ROUND(SUM(amount), 2) AS total_fraud_amount
FROM transactions
WHERE isFraud = 1;

-- Average Transaction Amount
SELECT 
    ROUND(AVG(amount), 2) AS average_transaction_amount
FROM transactions;

-- Fraud by Transaction Type
select type, count(*) as total_transactions,
sum(isFraud) as fraud_transactions
from transactions
group by type 
order by fraud_transactions desc;

-- Fraud Rate by Transaction Type
SELECT
    type,
    COUNT(*) AS total_transactions,
    SUM(isFraud) AS fraud_transactions,
    ROUND(
        (SUM(isFraud) / COUNT(*)) * 100,
        2
    ) AS fraud_rate
FROM transactions
GROUP BY type
ORDER BY fraud_rate DESC;

-- Fraud by step 
SELECT
    step,
    COUNT(*) AS total_transactions,
    SUM(isFraud) AS fraud_transactions,
    ROUND(
        (SUM(isFraud) / COUNT(*)) * 100,
        2
    ) AS fraud_rate
FROM transactions
GROUP BY step
ORDER BY fraud_transactions DESC;
-- which time window sees the most fraud activity?
SELECT
    step,
    COUNT(*) AS total_transactions,
    SUM(isFraud) AS fraud_transactions,
    ROUND(
        SUM(isFraud) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate
FROM transactions
GROUP BY step
ORDER BY fraud_transactions DESC
LIMIT 10;

-- Hieghest fraud Rate with minimum transactions
SELECT step,count(*) as  total_transactions,
sum(isFraud) as fraud_transactions,
round(sum(isfraud)*100.0/count(*),2) as fraud_rate
from transactions
group by step having count(*)>=1000
order by fraud_rate desc
limit 10;

-- Fraud Amount by Transaction Type

select	type, count(*) as fraud_transactions,
sum(amount) as fraud_amount,
round(avg(amount),2) as avg_fraud_amount
from transactions
where isFraud=1
group by type
order by fraud_transactions;

-- Fraud vs isFlaggedFraud
SELECT
    isFlaggedFraud,
    COUNT(*) AS total_transactions,
    SUM(isFraud) AS fraud_transactions,
    ROUND(
        SUM(isFraud) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate
FROM transactions
GROUP BY isFlaggedFraud
ORDER BY isFlaggedFraud;

-- Top 10 Fraud-Prone Origin Accounts
SELECT
    nameOrig,
    COUNT(*) AS fraud_transactions,
    SUM(amount) AS total_fraud_amount,
    ROUND(AVG(amount), 2) AS avg_fraud_amount
FROM transactions
WHERE isFraud = 1
GROUP BY nameOrig
ORDER BY fraud_transactions DESC, total_fraud_amount DESC
LIMIT 10;

-- Which customers have the highest fraud frequency
SELECT
    fraud_count,
    COUNT(*) AS number_of_accounts
FROM (
    SELECT
        nameOrig,
        COUNT(*) AS fraud_count
    FROM transactions
    WHERE isFraud = 1
    GROUP BY nameOrig
) AS fraud_accounts
GROUP BY fraud_count
ORDER BY fraud_count DESC;

-- Which merchant categories see the most fraud?

WITH fraud_summary AS (
    SELECT
        type,
        COUNT(*) AS total_transactions,
        SUM(isFraud) AS fraud_transactions
    FROM transactions
    GROUP BY type
)
SELECT
    type,
    total_transactions,
    fraud_transactions,
    ROUND(fraud_transactions * 100.0 / total_transactions,2) AS fraud_rate,
    RANK() OVER (ORDER BY fraud_transactions * 100.0 / total_transactions DESC) AS fraud_rate_rank
FROM fraud_summary
ORDER BY fraud_rate_rank;

-- Low/Medium/High risk
WITH fraud_summary AS (
    SELECT
        type,
        COUNT(*) AS total_transactions,
        SUM(isFraud) AS fraud_transactions
    FROM transactions
    GROUP BY type
)
SELECT
    type,
    total_transactions,
    fraud_transactions,
    ROUND(
        fraud_transactions * 100.0 / total_transactions,
        2
    ) AS fraud_rate,

    CASE
        WHEN fraud_transactions * 100.0 / total_transactions >= 0.50
            THEN 'High Risk'

        WHEN fraud_transactions * 100.0 / total_transactions >= 0.10
            THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS risk_level

FROM fraud_summary
ORDER BY fraud_rate DESC;