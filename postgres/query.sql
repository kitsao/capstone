VACUUM ANALYZE useview_c_assessment_follow_up;
SELECT * FROM useview_c_assessment_follow_up;

DROP VIEW IF EXISTS assess_follow_up  CASCADE;
CREATE VIEW assess_follow_up AS
(
	SELECT 
		a.patient_id AS patient_id, 
		a.reported_date AS reported_date, 
		COUNT(fu.uuid) AS follow_up_count
	FROM 
		useview_c_assessment AS a
		INNER JOIN useview_c_assessment_follow_up AS fu ON (a.uuid = fu.source_id)
	GROUP BY
		a.patient_id;
);