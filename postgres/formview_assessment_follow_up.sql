CREATE OR REPLACE VIEW formview_c_assessment_follow_up AS
SELECT 
	form.doc #>> '{fields,inputs,meta,location,lat}'::text[] AS "inputs/meta/location/lat",
    form.doc #>> '{fields,inputs,meta,location,long}'::text[] AS "inputs/meta/location/long",
    form.doc #>> '{fields,inputs,source}'::text[] AS "inputs/source",
    form.doc #>> '{fields,inputs,source_id}'::text[] AS "inputs/source_id",
    form.doc #>> '{fields,inputs,t_follow_up_count}'::text[] AS "inputs/t_follow_up_count",
    COALESCE(form.doc #>> '{fields,inputs,contact,_id}'::text[], patient.doc ->> '_id'::text) AS "inputs/contact/_id",
    COALESCE(form.doc #>> '{fields,inputs,contact,name}'::text[], patient.doc ->> 'name'::text) AS "inputs/contact/name",
    COALESCE(form.doc #>> '{fields,inputs,contact,date_of_birth}'::text[], patient.doc ->> 'date_of_birth'::text) AS "inputs/contact/date_of_birth",
    form.doc #>> '{fields,patient_contact_phone}'::text[] AS patient_contact_phone,
    COALESCE(form.doc #>> '{fields,inputs,contact,_id}'::text[], patient.doc ->> '_id'::text) AS patient_id,
    COALESCE(form.doc #>> '{fields,inputs,contact,name}'::text[], patient.doc ->> 'name'::text) AS patient_name,
    form.doc #>> '{fields,referral_follow_up_needed}'::text[] AS referral_follow_up_needed,
    form.doc #>> '{fields,follow_up_count}'::text[] AS follow_up_count,
    form.doc #>> '{fields,group_improved}'::text[] AS patient_improved,
    form.doc #>> '{fields,referral_follow_up,visited_health_facility}'::text[] AS visited_health_facility,
    form.doc #>> '{fields,group_better,patient_better}'::text[] AS patient_better,
    form.doc #>> '{fields,patient_health_facility_visit}'::text[] AS patient_health_facility_visit,
    form.doc #>> '{fields,patient_age_in_days}'::text[] AS patient_age_in_days,
    form.doc #>> '{fields,patient_age_in_years}'::text[] AS patient_age_in_years,
    form.doc #>> '{fields,patient_age_in_months}'::text[] AS patient_age_in_months,
    form.doc #>> '{fields,form_source_id}'::text[] AS form_source_id,
    form.doc #>> '{fields,group_improved,n_patient_improved_yes}'::text[] AS patient_improved_yes,
    form.doc #>> '{fields,group_improved,n_patient_improved_no}'::text[] AS patient_improved_no,
    form.doc #>> '{fields,group_referral_followup,n_not_visit_health_facility}'::text[] AS no_facility_visit,
    form.doc #>> '{fields,group_better,n_patient_better_yes}'::text[] AS patient_better_yes,
    form.doc #>> '{fields,group_better,n_patient_better_no}'::text[] AS patient_better_no,
    ''::text AS "meta/instanceID",
    form.doc ->> '_id'::text AS xmlforms_uuid
FROM
 	couchdb form
    JOIN form_metadata fm ON fm.uuid = (form.doc ->> '_id'::text)
    LEFT JOIN couchdb patient ON (patient.doc ->> '_id'::text) = (form.doc #>> '{fields,patient_id}'::text[])
WHERE
	(form.doc ->> 'form'::text) = 'c_assessment_follow_up'::text;