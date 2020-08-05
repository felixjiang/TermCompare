Delete from log
WHERE sentence IN ('With Windows Hello as shown in the following figure, you can accomplish a lot of things.', 
'For example, you can add a matching self-built cover page, header, and sidebar.',
'Click Insert and then choose the elements you want to operate from the different galleries.',
'On the Status page above, you can see the availability state of the VMs.',
'SRXEditor includes a sample file in SRX 2.0 format with a default set of segmentation rules supporting most standard cases as follows.',
'In this page, it also includes segmentation rules specific for these languages.',
'For some programming scenarios in Office Add-ins that use one of the host-specific API models (for Excel, Word, OneNote, and Visio).',
'Your code needs to read, write, or process some property on the dialog box from every member of a collection object.'
);

DELETE log
FROM log INNER JOIN ( 
	SELECT MIN(id) id, sentence, rule_hit, COUNT(rule_hit) AS count FROM log
	GROUP BY sentence, rule_hit
	HAVING COUNT(rule_hit) > 1) b
WHERE log.sentence = b.sentence AND log.rule_hit=b.rule_hit AND log.id <> b.id;

SELECT a.WEEK, total, false_pos, ROUND(false_pos/total*100,2) AS false_pos_rate FROM
(SELECT datediff(check_date,'2020-06-26') DIV 7 + 1 AS WEEK, COUNT(sentence) AS total FROM log
GROUP BY WEEK) a
INNER JOIN 
(SELECT datediff(check_date,'2020-06-26') DIV 7 + 1 AS WEEK, COUNT(sentence) as false_pos FROM log
WHERE feedback = 'false'
GROUP BY WEEK) b
ON a.week = b.week
ORDER BY 1;

SELECT check_date, sentence, rule_hit, datediff(check_date,'2020-06-26') DIV 7 + 1 AS week FROM log
WHERE feedback = 'false'
-- AND datediff(check_date,'2020-06-26') DIV 7 + 1 IN (3,4,5);

/*
SELECT * FROM log

CREATE TABLE log_bak (
check_date DATETIME,
sentence VARCHAR(2000),
rule_hit SMALLINT UNSIGNED,
feedback VARCHAR(50));

INSERT INTO log_bak
SELECT check_date, sentence, rule_hit, feedback
FROM log
ORDER BY id;

ALTER TABLE log_bak ADD id INT;
ALTER TABLE log_bak CHANGE id id int NOT NULL AUTO_INCREMENT PRIMARY KEY;

DROP TABLE log;

CREATE TABLE log (
check_date DATETIME,
sentence VARCHAR(2000),
rule_hit SMALLINT UNSIGNED,
feedback VARCHAR(50));

INSERT INTO log
SELECT check_date, sentence, rule_hit, feedback
FROM log_bak
ORDER BY id;

ALTER TABLE log ADD id INT;
ALTER TABLE log CHANGE id id int NOT NULL AUTO_INCREMENT PRIMARY KEY;

DROP TABLE log_bak;
*/