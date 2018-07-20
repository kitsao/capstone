VACUUM ANALYZE useview_c_assessment_follow_up;
SELECT * FROM useview_c_assessment_follow_up;

DROP MATERIALIZED VIEW IF EXISTS useview_c_assessment_follow_up CASCADE;
CREATE MATERIALIZED VIEW useview_c_assessment_follow_up AS 
(
	SELECT
		form.doc->>'_id' as uuid,
		form.doc #>> '{contact,_id}' AS chw,
		form.doc ->> 'form' AS form,
		form.doc #>> '{contact,_id}' AS reported_by,
		form.doc #>> '{contact,parent,_id}' AS reported_by_parent,
		to_timestamp((NULLIF(form.doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision) AS reported,
		COALESCE(form.doc #>> '{fields,source_id}','') AS source_id,
		form.doc #>> '{fields,patient_id}' AS patient_id,

		CASE
			WHEN person.date_of_birth <> '' AND person.date_of_birth IS NOT NULL
			THEN 
				(EXTRACT (years from age(to_timestamp((NULLIF(form.doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision), date_of_birth::date)))::int
			WHEN (form.doc #>> '{fields,patient_age_in_years}') <> '' AND (form.doc #>> '{fields,patient_age_in_years}') IS NOT NULL
			THEN
				(form.doc #>> '{fields,patient_age_in_years}')::int
			ELSE 99
		END AS patient_age_in_years,

		CASE
			WHEN person.date_of_birth <> '' AND person.date_of_birth IS NOT NULL
			THEN 
				(((EXTRACT (years from age(to_timestamp((NULLIF(form.doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision), date_of_birth::date))) * 12) 
				+ (EXTRACT (months from age(to_timestamp((NULLIF(form.doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision), date_of_birth::date))))::int
			WHEN (form.doc #>> '{fields,patient_age_in_months}') <> '' AND (form.doc #>> '{fields,patient_age_in_months}') IS NOT NULL
			THEN
				(form.doc #>> '{fields,patient_age_in_months}')::int
			ELSE 99
		END AS patient_age_in_months,	

		person.date_of_birth AS patient_date_of_birth,
		
		form.doc #>> '{fields,referral_follow_up_needed}' AS referral_follow_up_needed,
		form.doc #>> '{fields,follow_up_count}' AS follow_up_count,
		form.doc #>> '{fields,visited_health_facility}' AS visited_health_facility,
		form.doc #>> '{fields,patient_improved}' AS patient_improved,
		form.doc #>> '{fields,patient_better}' AS patient_better

	FROM
		couchdb AS form
		INNER JOIN contactview_person_fields AS person ON (form.doc #>> '{fields,patient_id}' = person.uuid)
				
	WHERE
		form.doc ->> 'form' = 'c_assessment_follow_up'
		
)
;
	
CREATE UNIQUE INDEX IF NOT EXISTS useview_c_assessment_follow_up_source_date_uuid ON useview_c_assessment_follow_up USING btree (source_id, reported, uuid);

/* adding the following indexes */
CREATE INDEX useview_c_assessment_follow_up_reported ON  useview_c_assessment_follow_up USING btree (reported);
CREATE INDEX useview_c_assessment_follow_up_uuid ON useview_c_assessment_follow_up USING btree (uuid);
CREATE INDEX useview_c_assessment_follow_up_source_id ON useview_c_assessment_follow_up USING btree (source_id);
CREATE INDEX useview_c_assessment_follow_up_reported_by ON  useview_c_assessment_follow_up USING btree (reported_by);
CREATE INDEX useview_c_assessment_follow_up_reported_by_parent ON  useview_c_assessment_follow_up USING btree (reported_by_parent);

REASSIGN OWNED BY current_user TO full_access;
GRANT SELECT ON useview_c_assessment_follow_up TO klipfolio;