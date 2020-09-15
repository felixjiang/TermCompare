-- 译员数量（总共 ):
-- 西安：14, 杭州：8, 北京：16, 上海：9, LBT：30, 舜禹：17
USE term_compare;

DELETE a.* FROM feedback_v2 a, 
(SELECT query_op, rule_hit, MIN(id) as id FROM feedback_v2
GROUP BY query_op, rule_hit) b
WHERE a.query_op = b.query_op
AND a.rule_hit = b.rule_hit
AND a.id > b.id;

DELETE FROM feedback_v2
WHERE sentence IN ('With Windows Hello on Unix as shown in the following figure, you can accomplish a lot of things in self-built Unix.',
'For example, you can add a matching self-built cover page, header, and sidebar.',
'Click Insert and then choose the elements you want to operate from the different galleries.',
'On the Status page above, you can see the availability state of the VMs.',
'SRXEditor includes a sample file in SRX 2.0 format with a default set of segmentation rules supporting most standard cases as follows.',
'In this page, it also includes segmentation rules specific for these languages.',
'For some programming scenarios in Office Add-ins that use one of the host-specific API models (for Unix, Excel, Word, OneNote, and Visio).',
'Your code needs to read, write, or process some property on the dialog box from every member of a collection object.'
);
 
DELETE a.* FROM user_session_v2 a
LEFT JOIN feedback_v2 b
ON a.sid = b.sid AND a.run = b.run
WHERE b.sid IS NULL;

DELETE a.* FROM sentence_word_cnt_v2 a
LEFT JOIN feedback_v2 b
ON a.sid = b.sid AND a.run = b.run
WHERE b.sid IS NULL;

DELETE a.* FROM performance_v2 a
LEFT JOIN feedback_v2 b
ON a.sid = b.sid AND a.run = b.run
WHERE b.sid IS NULL;

/* overview_v2
SELECT uid, a.sid, a.run, WEEK, b.sentence, b.rule_hit, feedback
FROM user_session_v2 a INNER JOIN feedback_v2 b
ON a.sid = b.sid AND a.run = b.run
WHERE NOT EXISTS (
	SELECT * FROM feedback_eval c
	WHERE b.feedback = 'false' AND b.query_op = c.query_op AND b.rule_hit = c.rule_hit AND evaluation = '无效'
)

-- Add auto incremental column
ALTER TABLE log ADD id INT;
ALTER TABLE log CHANGE id id int NOT NULL AUTO_INCREMENT PRIMARY KEY;

-- Add compute column
alter table feedback_v2 add column query_op char(10) as 
(CONCAT(substring(sentence, 1, 1), substring(sentence, LENGTH(sentence), 1), substring(sentence, ROUND(LENGTH(sentence)/9+1),1), substring(sentence, ROUND(LENGTH(sentence)/9*2+1),1),
substring(sentence, ROUND(LENGTH(sentence)/9*3+1),1), substring(sentence, ROUND(LENGTH(sentence)/9*4+1),1), substring(sentence, ROUND(LENGTH(sentence)/9*5+1),1),
substring(sentence, ROUND(LENGTH(sentence)/9*6+1),1), substring(sentence, ROUND(LENGTH(sentence)/9*7+1),1), substring(sentence, ROUND(LENGTH(sentence)/9*8+1),1))) NOT NULL
*/

-- 整体概况
SELECT a.WEEK, 用户数, 运行次数, 检查次数, 反馈条数, 误报条数, CONCAT(ROUND(误报条数*100/反馈条数, 2),'%') AS 误报率, IFNULL(修正规则,0) AS 修正规则, IFNULL(驳回, 0) AS 驳回, IFNULL(真正误报,0) AS 真正误报,
CONCAT(ROUND((IFNULL(真正误报,0)+IFNULL(修正规则,0))*100/反馈条数, 2),'%') AS 修正误报率, 反馈条数-IFNULL(修正规则,0)-IFNULL(真正误报,0) AS 发现问题 FROM
(SELECT WEEK,COUNT(sentence) AS 反馈条数, COUNT(DISTINCT user_guid) AS 用户数, COUNT(DISTINCT LEFT(session_guid, 37)) as 运行次数 FROM log_view 
GROUP BY WEEK) a
LEFT JOIN
(SELECT WEEK,COUNT(sentence) AS 误报条数 FROM log_view
WHERE feedback = 'false'
GROUP BY WEEK) b
ON a.week = b.week
LEFT JOIN
(SELECT WEEK, count(sentence) AS 修正规则 FROM feedback_eval
WHERE evaluation = '修正规则'
GROUP BY week) c
ON a.week = c.week
LEFT JOIN
(SELECT week, COUNT(sentence) AS 驳回 FROM feedback_eval
WHERE evaluation = '驳回'
GROUP BY week) d
ON a.week = d.week
LEFT JOIN
(SELECT week, COUNT(sentence) AS 真正误报 FROM feedback_eval
WHERE evaluation = '误报'
GROUP BY week) e
ON a.week = e.week
LEFT JOIN
(SELECT week, SUM(runs) AS 检查次数 FROM 
(SELECT week, MAX(runs) AS runs FROM log_view
GROUP BY WEEK, session_guid) z
GROUP BY week) f
ON a.week = f.week
WHERE a.week < 10
UNION
SELECT a.WEEK, 用户数, 运行次数, 检查次数, 反馈条数, 误报条数, CONCAT(ROUND(误报条数*100/反馈条数, 2),'%') AS 误报率, IFNULL(修正规则,0) AS 修正规则, IFNULL(驳回, 0) AS 驳回, IFNULL(真正误报,0) AS 真正误报,
CONCAT(ROUND((IFNULL(真正误报,0)+IFNULL(修正规则,0))*100/反馈条数, 2),'%') AS 修正误报率, 反馈条数-IFNULL(修正规则,0)-IFNULL(真正误报,0) AS 发现问题 FROM
(SELECT WEEK,COUNT(sentence) AS 反馈条数, COUNT(DISTINCT uid) AS 用户数, COUNT(DISTINCT sid) as 运行次数 FROM overview_v2
GROUP BY WEEK) a
LEFT JOIN
(SELECT WEEK,COUNT(sentence) AS 误报条数 FROM overview_v2
WHERE feedback = 'false'
GROUP BY WEEK) b
ON a.week = b.week
LEFT JOIN
(SELECT week, count(sentence) AS 修正规则 FROM feedback_eval
WHERE evaluation = '修正规则'
GROUP BY week) c
ON a.week = c.week
LEFT JOIN
(SELECT week, COUNT(sentence) AS 驳回 FROM feedback_eval
WHERE evaluation = '驳回'
GROUP BY week) d
ON a.week = d.week
LEFT JOIN
(SELECT week, COUNT(sentence) AS 真正误报 FROM feedback_eval
WHERE evaluation = '误报'
GROUP BY week) e
ON a.week = e.week
LEFT JOIN
(SELECT week, SUM(run) AS 检查次数 FROM 
(SELECT week, MAX(run) AS run FROM overview_v2
GROUP BY WEEK, sid) z
GROUP BY week) f
ON a.week = f.week;

-- 误报处理概览
SELECT 修正规则 + 驳回 + 误报 + 无效 AS 提交误报, 修正规则, 驳回, 误报, 无效 FROM
(SELECT COUNT(*) AS 修正规则
FROM feedback_eval
WHERE evaluation = '修正规则') a
JOIN
(SELECT COUNT(*) AS 驳回
FROM feedback_eval
WHERE evaluation = '驳回') b
JOIN
(SELECT COUNT(*) AS 无效
FROM feedback_eval
WHERE evaluation = '无效') c
JOIN
(SELECT COUNT(*) AS 误报
FROM feedback_eval
WHERE evaluation = '误报') d;

-- 具体误报_按城市

SELECT week, ctry_pr, city, sentence, rule_hit
FROM overview_v2 a INNER JOIN user_ip_v2 b
ON a.uid = b.uid
LEFT JOIN ip_location_v2 c
ON b.ip = c.ip
WHERE feedback = 'false'
ORDER BY 1;

-- 检查的性能
SELECT DISTINCT check_time, x.uid, x.sid, ctry_pr, city, total_words, check_type, 
CASE
	WHEN loading = 0 THEN 0
	ELSE loading - start_check
END AS loading_time,
CASE
	WHEN checking = 0 THEN 0
	ELSE checking - loading
END AS checking_time FROM 
(SELECT check_time, uid, a.sid, MAX(total_words) AS total_words,
	CONCAT(CASE
		WHEN EVENT = 'Start CheckAll' THEN 'CheckAll'
		WHEN EVENT = 'Start CheckRange' THEN 'CheckRange'
		WHEN EVENT = 'Start CheckRest' THEN 'CheckRest'
		ELSE ''
	END) AS check_type,
	SUM(CASE
		WHEN EVENT like"Start Check%" THEN duration
		ELSE 0
	END) AS start_check,
	SUM(CASE
		WHEN EVENT = 'Loading completes' THEN duration
		ELSE 0
	END) AS loading,
	SUM(CASE
		WHEN EVENT = 'Check Completes' THEN duration
		ELSE 0
	END) AS checking
FROM performance_v2 a INNER JOIN user_session_v2 b
ON a.sid = b.sid AND a.run = b.run
INNER JOIN sentence_word_cnt_v2 c
ON a.sid = c.sid AND a.run = c.run
GROUP BY a.sid, uid) x
INNER JOIN user_ip_ctry_city_v2 y
ON x.uid = y.uid
ORDER BY check_time;

-- 缺失位置的IP
SELECT DISTINCT ip AS missing_ip FROM user_ip_v2
WHERE ip NOT IN (
SELECT ip FROM ip_location_v2);

/*
insert into ip_location_v2 (ip, ctry_pr, city) values ('110.54.241.148','菲律宾','马尼拉');
insert into ip_location_v2 (ip, ctry_pr, city) values ('119.6.98.246','四川','成都');
insert into ip_location_v2 (ip, ctry_pr, city) values ('152.32.108.86','菲律宾','菲律宾');
insert into ip_location_v2 (ip, ctry_pr, city) values ('220.166.230.98','四川','成都');
*/

-- 误报条数_按城市
SELECT week, ctry_pr, city, COUNT(feedback) 误报条数
FROM overview_v2 a INNER JOIN user_ip_ctry_city_v2 b
ON a.uid = b.uid
WHERE feedback = 'false'
GROUP BY WEEK, city
ORDER BY 1, 4 DESC;

-- 驳回误报_按城市
SELECT b.check_time, ctry_pr, city, a.sentence, a.rule_hit
FROM feedback_v2 a INNER JOIN user_session_v2 b
ON a.sid = b.sid AND a.run = b.run
INNER JOIN feedback_eval c
ON a.query_op = c.query_op AND DATE(b.check_time) = DATE(c.check_date) AND a.rule_hit = c.rule_hit
LEFT JOIN user_ip_ctry_city_v2 d
ON b.uid = d.uid
WHERE evaluation = '驳回'
AND a.feedback = 'false';

-- 当前需要导出的误报
SELECT WEEK, check_time, sentence, rule_hit
FROM feedback_v2 a INNER JOIN user_session_v2 b
ON a.sid = b.sid
WHERE feedback = 'false'
ORDER BY check_time;

-- 查找没能匹配误报处理结果的误报_1。指定最后误报处理时间
SELECT WEEK, check_time, sentence, rule_hit
FROM feedback_v2 a INNER JOIN user_session_v2 b
ON a.sid = b.sid
WHERE feedback = 'false'
AND NOT EXISTS (
SELECT sentence FROM feedback_eval c
WHERE c.sentence = a.sentence AND c.rule_hit = a.rule_hit)
AND check_time <= STR_TO_DATE('9/7/2020 15:09', '%m/%d/%Y %H:%i:%s')
ORDER BY check_time;
-- 查找没能匹配误报处理结果的误报_2
SELECT * FROM feedback_eval
WHERE sentence LIKE '%aaaaaaaaa%';

-- 每周 top 5 问题附带例句和规则详细信息
	-- 定位每周 top 5 问题
TRUNCATE TABLE top_hit_rules_by_week;
SET @num:=0, @WEEK:='';
INSERT INTO top_hit_rules_by_week
SELECT WEEK, rule_hit, hits
FROM (
SELECT WEEK, rule_hit, hits, @num := if(@WEEK = WEEK, @num+1, 1) AS ROW_NUMBER, @WEEK := week AS dummy 
FROM (
SELECT WEEK, rule_hit, COUNT(sentence) AS hits FROM (
SELECT DISTINCT * FROM (
SELECT WEEK, sentence, rule_hit
FROM overview_v2 a
WHERE feedback = 'false'
AND EXISTS (
SELECT sentence FROM feedback_eval b
WHERE a.sentence = b.sentence
AND a.rule_hit = b.rule_hit
AND evaluation = '驳回' )
UNION
SELECT WEEK, sentence, rule_hit
FROM overview_v2
WHERE feedback = 'true'
UNION
SELECT WEEK, sentence, rule_hit
FROM log_view a
WHERE feedback = 'false'
AND check_date >= STR_TO_DATE('2020-07-15 15:18:09', '%Y-%m-%d %H:%i:%s')
AND EXISTS (
SELECT sentence FROM feedback_eval b
WHERE a.sentence = b.sentence
AND a.rule_hit = b.rule_hit
AND evaluation = '驳回')
UNION
SELECT WEEK, sentence, rule_hit
FROM log_view
WHERE feedback = 'true'
AND check_date >= STR_TO_DATE('2020-07-15 15:18:09', '%Y-%m-%d %H:%i:%s')) a) b
GROUP BY WEEK, rule_hit) c
ORDER BY 1, 3 DESC) d
WHERE d.row_number <= 5;
-- 查询结果添加规则信息
SET @num:=0, @WEEK:='';
SELECT WEEK, sentence, rule_hit, rule_msg, correction, good_example, bad_example
FROM (
SELECT WEEK, rule_hit, sentence, rule_msg, correction, good_example, bad_example, @num := if(@WEEK = week,@num +1,1) AS ROW_NUMBER, @WEEK := week AS dummy 
FROM (
SELECT a.WEEK, a.rule_hit, sentence, rule_msg, correction, pos_example AS good_example, neg_example AS bad_example
FROM top_hit_rules_by_week a INNER JOIN erroneous_sentence_by_week b
ON a.WEEK = b.week
AND a.rule_hit = b.rule_hit
INNER JOIN rules c
ON a.rule_hit = c.rule_id
ORDER BY week) y) z
WHERE ROW_NUMBER <= 5
ORDER BY WEEK;

-- 每周检测问题数量以及规则
SELECT WEEK, rule_hit, COUNT(sentence) AS hits FROM (
SELECT DISTINCT * FROM (
SELECT WEEK, sentence, rule_hit
FROM overview_v2 a
WHERE feedback = 'false'
AND EXISTS (
SELECT sentence FROM feedback_eval b
WHERE a.sentence = b.sentence
AND a.rule_hit = b.rule_hit
AND evaluation = '驳回' )
UNION
SELECT WEEK, sentence, rule_hit
FROM overview_v2
WHERE feedback = 'true'
UNION
SELECT WEEK, sentence, rule_hit
FROM log_view a
WHERE feedback = 'false'
AND check_date >= STR_TO_DATE('2020-07-15 15:18:09', '%Y-%m-%d %H:%i:%s')
AND EXISTS (
SELECT sentence FROM feedback_eval b
WHERE a.sentence = b.sentence
AND a.rule_hit = b.rule_hit
AND evaluation = '驳回')
UNION
SELECT WEEK, sentence, rule_hit
FROM log_view
WHERE feedback = 'true'
AND check_date >= STR_TO_DATE('2020-07-15 15:18:09', '%Y-%m-%d %H:%i:%s')) a) b
GROUP BY WEEK, rule_hit
ORDER BY 1, 3 DESC;
/*
-- log_view
SELECT id, check_date, CONCAT(CAST(YEAR(check_date) AS CHAR(4)), '-', CAST(MONTH(check_date) AS CHAR(2))) AS month,
(((TO_DAYS(check_date)-TO_DAYS('2020-06-26')) DIV 7) + 1) AS week, sentence, rule_hit, feedback, user_guid, LEFT(session_guid, 38) AS session_guid, LEFT(location, 2) AS province, RIGHT(location, 2) AS city,
CONVERT(IFNULL(SUBSTRING(session_guid,38, 2), '0'), UNSIGNED) AS runs
FROM log a LEFT JOIN ip_location b ON a.ip_location = b.ip
WHERE sentence NOT IN
(SELECT sentence FROM feedback_eval WHERE evaluation = '无效'
AND a.rule_hit = rule_hit)
and ((TO_DAYS(check_date)-TO_DAYS('2020-06-26')) DIV 7) = 8

-- 误报处理概览
SELECT 修正规则 + 驳回 + 误报 + 无效 AS 提交误报, 修正规则, 驳回, 误报, 无效 FROM
(SELECT COUNT(*) AS 修正规则
FROM feedback_eval
WHERE evaluation = '修正规则') a
JOIN
(SELECT COUNT(*) AS 驳回
FROM feedback_eval
WHERE evaluation = '驳回') b
JOIN
(SELECT COUNT(*) AS 无效
FROM feedback_eval
WHERE evaluation = '无效') c
JOIN
(SELECT COUNT(*) AS 误报
FROM feedback_eval
WHERE evaluation = '误报') d;

-- 具体误报_按城市
SELECT check_date, location, sentence, rule_hit, datediff(check_date,'2020-06-26') DIV 7 + 1 AS WEEK
FROM log a LEFT JOIN ip_location b ON a.ip_location = b.ip
WHERE feedback = 'false'
ORDER BY 1;

-- 检查的性能
SELECT DISTINCT b.check_date, a.user_guid, a.session_guid, b.ip_location, c.location, word_count, check_type, 
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
LEFT JOIN ip_location c ON b.ip_location = c.ip
ORDER BY b.check_date;

-- 缺失位置的IP
SELECT DISTINCT ip_location AS missing_ip FROM log
WHERE ip_location NOT IN (
SELECT ip FROM ip_location);

-- 误报条数_按城市
SELECT WEEK, city, COUNT(feedback) 误报条数 FROM log_view
WHERE feedback = 'false'
GROUP BY WEEK, city
ORDER BY 1, 3 DESC;

-- 驳回误报_按城市
SELECT a.check_date, location, a.sentence, a.rule_hit
FROM log a INNER JOIN feedback_eval b
ON a.sentence = b.sentence AND DATE(a.check_date) = DATE(b.check_date) AND a.rule_hit = b.rule_hit
LEFT JOIN ip_location c
ON a.ip_location = c.ip
WHERE evaluation = '驳回'
AND a.feedback = 'false';
*/
