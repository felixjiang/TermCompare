-- 译员数量（总共 ):
-- 西安：14, 杭州：8, 北京：16, 上海：9, LBT：30, 舜禹：17

USE term_compare;

/*DELETE perf 
FROM perf INNER JOIN log
ON perf.user_guid = log.user_guid
WHERE sentence IN ('With Windows Hello on Unix as shown in the following figure, you can accomplish a lot of things in self-built Unix.',
'For example, you can add a matching self-built cover page, header, and sidebar.',
'Click Insert and then choose the elements you want to operate from the different galleries.',
'On the Status page above, you can see the availability state of the VMs.',
'SRXEditor includes a sample file in SRX 2.0 format with a default set of segmentation rules supporting most standard cases as follows.',
'In this page, it also includes segmentation rules specific for these languages.',
'For some programming scenarios in Office Add-ins that use one of the host-specific API models (for Unix, Excel, Word, OneNote, and Visio).',
'Your code needs to read, write, or process some property on the dialog box from every member of a collection object.'
);

DELETE FROM perf
WHERE word_count IS NULL;*/

DELETE FROM log  
WHERE sentence IN ('With Windows Hello on Unix as shown in the following figure, you can accomplish a lot of things in self-built Unix.',
'For example, you can add a matching self-built cover page, header, and sidebar.',
'Click Insert and then choose the elements you want to operate from the different galleries.',
'On the Status page above, you can see the availability state of the VMs.',
'SRXEditor includes a sample file in SRX 2.0 format with a default set of segmentation rules supporting most standard cases as follows.',
'In this page, it also includes segmentation rules specific for these languages.',
'For some programming scenarios in Office Add-ins that use one of the host-specific API models (for Unix, Excel, Word, OneNote, and Visio).',
'Your code needs to read, write, or process some property on the dialog box from every member of a collection object.'
);

DELETE log
FROM log INNER JOIN ( 
	SELECT MIN(id) id, sentence, rule_hit, COUNT(rule_hit) AS count FROM log
	GROUP BY sentence, rule_hit
	HAVING COUNT(rule_hit) > 1) b
WHERE log.sentence = b.sentence AND log.rule_hit=b.rule_hit AND log.id <> b.id;

UPDATE log
SET user_guid = NULL
WHERE user_guid = '';

UPDATE log
SET ip_location = NULL
WHERE ip_location = '';

UPDATE log
SET session_guid = NULL
WHERE session_guid = '';

SELECT a.WEEK AS week, unique_users, sessions, runs, total_issues, false_pos, CONCAT(ROUND(false_pos/total_issues*100,2),'%') AS false_pos_rate FROM
(SELECT datediff(check_date,'2020-06-26') DIV 7 + 1 AS week, COUNT(sentence) AS total_issues, COUNT(DISTINCT user_guid) AS unique_users, COUNT(DISTINCT LEFT(session_guid, 37)) as sessions FROM log
GROUP BY WEEK) a
LEFT JOIN 
(SELECT datediff(check_date,'2020-06-26') DIV 7 + 1 AS week, COUNT(sentence) as false_pos FROM log
WHERE feedback = 'false'
GROUP BY WEEK) b
ON a.week = b.week
INNER JOIN
(SELECT WEEK, SUM(runs) AS runs FROM 
(SELECT datediff(check_date,'2020-06-26') DIV 7 + 1 AS week, CONVERT(MAX(IFNULL(SUBSTRING(session_guid,38,2),'0')), UNSIGNED) AS runs FROM log
GROUP BY WEEK, LEFT(session_guid, 37)) z
GROUP BY week) c
ON a.week=c.week
ORDER BY 1;

SELECT check_date, location, sentence, rule_hit, datediff(check_date,'2020-06-26') DIV 7 + 1 AS WEEK
FROM log a INNER JOIN ip_location b ON a.ip_location = b.ip
WHERE feedback = 'false'
ORDER BY 1;
-- AND datediff(check_date,'2020-06-26') DIV 7 + 1 IN (3,4,5);

SELECT DISTINCT a.user_guid, a.session_guid, b.ip_location, c.location, word_count, check_type, 
CASE
	WHEN loading = 0 THEN 0
	ELSE loading - start_check
END AS loading_time,
CASE
	WHEN checking = 0 THEN 0
	ELSE checking - loading
END AS checking_time FROM 
(SELECT user_guid, session_guid, MAX(word_count) AS word_count, 
	CONCAT(CASE
		WHEN EVENT = 'Start CheckAll' THEN 'CheckAll'
		WHEN EVENT = 'Start CheckRange' THEN 'CheckRange'
		WHEN EVENT = 'Start CheckRest' THEN 'CheckRest'
		ELSE ''
	END) AS check_type,
	SUM(CASE
		WHEN EVENT like"Start Check%" THEN ms
		ELSE 0
	END) AS start_check,
	SUM(CASE
		WHEN EVENT = 'Loading completes' THEN ms
		ELSE 0
	END) AS loading,
	SUM(CASE
		WHEN EVENT = 'Check Completes' THEN ms
		ELSE 0
	END) AS checking
FROM perf
GROUP BY user_guid, session_guid) a
INNER JOIN log b ON a.user_guid = b.user_guid AND a.session_guid = b.session_guid
LEFT JOIN ip_location c ON b.ip_location = c.ip;

SELECT * FROM log;

SELECT * FROM perf;

SELECT DISTINCT ip_location AS missing_ip_info FROM log
WHERE ip_location NOT IN (
SELECT ip FROM ip_location);

-- insert into ip_location (ip, location) values ('112.3.232.157','江苏南京');

/*
CREATE TABLE log_bak (
check_date DATETIME,
sentence VARCHAR(2000),
rule_hit SMALLINT UNSIGNED,
feedback VARCHAR(50),
ip_location VARCHAR(50),
user_guid VARCHAR(50),
session_guid VARCHAR(50));

INSERT INTO log_bak
SELECT check_date, sentence, rule_hit, feedback, ip_location, user_guid, session_guid
FROM log
ORDER BY id;

ALTER TABLE log_bak ADD id INT;
ALTER TABLE log_bak CHANGE id id int NOT NULL AUTO_INCREMENT PRIMARY KEY;

DROP TABLE log;

CREATE TABLE log (
check_date DATETIME,
sentence VARCHAR(2000),
rule_hit SMALLINT UNSIGNED,
feedback VARCHAR(50),
ip_location VARCHAR(50),
user_guid VARCHAR(50),
session_guid VARCHAR(50));

INSERT INTO log
SELECT check_date, sentence, rule_hit, feedback, ip_location, user_guid, session_guid
FROM log_bak
ORDER BY id;

ALTER TABLE log ADD id INT;
ALTER TABLE log CHANGE id id int NOT NULL AUTO_INCREMENT PRIMARY KEY;

DROP TABLE log_bak;
*/
