CREATE OR REPLACE VIEW formview_assessment AS
SELECT 
	form.doc #>> '{fields,inputs,meta,location,lat}'::text[] AS "inputs/meta/location/lat",
	form.doc #>> '{fields,inputs,meta,location,long}'::text[] AS "inputs/meta/location/long",
	form.doc #>> '{fields,inputs,source}'::text[] AS "inputs/source",
	form.doc #>> '{fields,inputs,source_id}'::text[] AS "inputs/source_id",
	form.doc #>> '{fields,inputs,contact,_id}' AS "inputs/contact/_id",
	form.doc #>> '{fields,inputs,contact,name}' AS "inputs/contact/name",
	form.doc #>> '{fields,inputs,contact,date_of_birth}' AS "inputs/contact/date_of_birth",
	form.doc #>> '{fields,inputs,contact,sex}'::text[] AS "inputs/contact/sex",
	form.doc #>> '{fields,inputs,contact,_id}'::text[] AS patient_id,
	form.doc #>> '{fields,group_symptoms,patient_symptoms}'::text[] AS symptoms,
	form.doc #>> '{fields,cough,cough_duration}'::text[] AS cough_duration,
	form.doc #>> '{fields,cough,breathing_difficulty}'::text[] AS symptom_cough,
	form.doc #>> '{fields,cough,diarrhoea_duration}'::text[] AS diarrhoea_duration,
	form.doc #>> '{fields,diarrhoea,watery_stool_episodes}'::text[] AS symptom_watery_stool_episodes,
	form.doc #>> '{fields,diarrhoea,blood_in_diarrhoea}'::text[] AS symptom_blood_in_diarrhoea,
	form.doc #>> '{fields,suck_feed,normal_at_birth}'::text[] AS symptom_normal_at_birth,
	form.doc #>> '{fields,suck_feed,body_stiffness}'::text[] AS symptom_body_stiffness,
	form.doc #>> '{fields,fever,fever_duration}'::text[] AS fever_duration,
	form.doc #>> '{fields,fever,temperature}'::text[] AS symptom_temperature,
	form.doc #>> '{fields,fever,drowsy}'::text[] AS symptom_drowsy,
	form.doc #>> '{fields,fever,fits}'::text[] AS symptom_fits,
	form.doc #>> '{fields,fever,skin_rash}'::text[] AS symptom_skin_rash,
	form.doc #>> '{fields,fever,bleeding}'::text[] AS symptom_bleeding,
	form.doc #>> '{fields,fever,painful_groins}'::text[] AS symptom_painful_groins,
	form.doc #>> '{fields,yellowness,yellowness_period}'::text[] AS symptom_yellowness,
	form.doc #>> '{fields,has_symptoms}'::text[] AS has_symptoms,
	form.doc #>> '{fields,patient_age_in_days}'::text[] AS patient_age_in_days,
	form.doc #>> '{fields,patient_age_in_years}'::text[] AS patient_age_in_years,
	form.doc #>> '{fields,patient_age_in_months}'::text[] AS patient_age_in_months,
	form.doc #>> '{fields,patient_age_display}'::text[] AS patient_age_display,
	form.doc ->> '_id'::text AS xmlforms_uuid

FROM 
	couchdb form
	JOIN form_metadata fm ON fm.uuid = (form.doc ->> '_id'::text)

WHERE
	(form.doc ->> 'form'::text) = ANY (VALUES ('assessment') );