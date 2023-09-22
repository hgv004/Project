create database crm;

use crm;

select * from crm;

-- 1. Avg Sessions per client

select (sum(Is_Session) / count(distinct part_mail)) as Avg_session_per_client
from crm;

-- 2. Client lifespan Duration between first and last “appointment_date” per client

SELECT
    part_mail,
    MAX(`Appt Date`) AS md,
    MIN(`Appt Date`) AS min_d,
    DATEDIFF(MAX(`Appt Date`), MIN(`Appt Date`)) AS date_diff
FROM
    crm
GROUP BY
    part_mail;

CREATE TABLE crm1 AS
SELECT
    CAST(CONCAT(RIGHT(`Appt Date`, 4), "/", SUBSTRING_INDEX(`Appt Date`, '/', 2)) AS DATE) AS Appt_date,
    part_mail,
    Is_Session
FROM
    crm;
   
SELECT
    part_mail,
    DATEDIFF(MAX(Appt_date), MIN(Appt_date)) AS lifespan
FROM
    crm1
GROUP BY
    part_mail;

/* 3. Frequency of client - 
How many times a month the clients repeat on average
How often clients come on a weekly/monthly basis
How often each therapists has recurring clients 
Broken up by therapist, region and time frame */
   
/* 
How many clients drop off after session # 1,2,3…
-- What is a drop off?
	-- No future ‘appointment_request_datetime’ and had atleast 1 session
-- Display the bars by Total Sessions by participant (horizontal)
*/
   
   
