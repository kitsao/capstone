VACUUM ANALYZE useview_c_assessment;
SELECT * FROM useview_c_assessment;
DROP MATERIALIZED VIEW useview_c_assessment;

CREATE MATERIALIZED VIEW IF NOT EXISTS useview_c_assessment AS
(
	SELECT
		form.doc ->> '_id' AS uuid,
		form.doc #>> '{contact,_id}' AS chw,
		form.doc #>> '{contact,_id}' AS reported_by,
		form.doc #>> '{contact,parent,_id}' AS reported_by_parent,
		form.doc ->> 'form' AS form,
		to_timestamp((NULLIF(form.doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision) AS reported,
		
		form.doc #>> '{fields,patient_id}' AS patient_id,
		person.date_of_birth AS patient_date_of_birth,
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
		
		form.doc #>> '{fields,group_symptoms,patient_symptoms}' AS patient_symptoms,
		form.doc #>> '{fields,has_diarrhoea}' AS has_diarrhoea,
		
		CASE
			WHEN form.doc #>> '{fields,cough,cough_duration}' = '' THEN 0::int 
			ELSE (form.doc #>> '{fields,cough,cough_duration}')::int 
		END AS cough_duration,
		
		CASE
			WHEN form.doc #>> '{fields,diarrhea,diarrhea_duration}' = '' THEN 0::int
			ELSE (form.doc #>> '{fields,diarrhea,diarrhea_duration}')::int 
		END AS diarrhea_duration,	

		CASE
			WHEN form.doc #>> '{fields,fever,fever_duration}' = '' THEN 0::int
			ELSE (form.doc #>> '{fields,fever,fever_duration}')::int 
		END AS fever_duration,
	
		form.doc #>> '{fields,fever,temperature}' AS temperature,
		form.doc #>> '{fields,has_symptoms}' AS has_symptoms
		 
	FROM
		couchdb AS form
		INNER JOIN contactview_person_fields AS person ON (form.doc #>> '{fields,patient_id}' = person.uuid)
	
	WHERE
		form.doc ->> 'form' = ANY (VALUES ('c_assessment'))
);

/* adding the following indexes */ -- see if others are required for LG
CREATE UNIQUE INDEX useview_c_assessment_reported_age_uuid ON useview_c_assessment USING btree (reported, patient_age_in_years, uuid);
CREATE INDEX useview_c_assessment_reported ON  useview_c_assessment USING btree (reported);
CREATE INDEX useview_c_assessment_chw ON  useview_c_assessment USING btree (chw);
CREATE INDEX useview_c_assessment_reported_by ON  useview_c_assessment USING btree (reported_by);
CREATE INDEX useview_c_assessment_reported_by_parent ON  useview_c_assessment USING btree (reported_by_parent);
CREATE INDEX useview_c_assessment_uuid ON useview_c_assessment USING btree (UUID);

/* permissions, double check on these, to add the others if LG needs them */
REASSIGN OWNED BY current_user TO full_access;
ALTER  VIEW useview_c_assessment OWNER TO full_access;
--GRANT SELECT ON useview_c_assessment TO lg_access; */ it said this wasn't a valid permission */
GRANT SELECT ON useview_c_assessment TO klipfolio;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO klipfolio;
--GRANT SELECT ON useview_c_assessment TO read_only; */ it said this wasn't a valid permission */

