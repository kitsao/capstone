define Target {
    _id: null,
    deleted: null,
    type: null,
    pass: null,
    date: null
}

define Contact {
    contact: null,
    reports: null
}

define Task {
    _id: null,
    deleted: null,
    doc: null,
    contact: null,
    icon: null,
    date: null,
    title: null,
    fields: null,
    resolved: null,
    priority: null,
    priorityLabel: null,
    reports: null,
    actions: null
}

rule GenerateEvents {
    when {
        c: Contact
    }
    then {
        var today = new Date();
        var MS_IN_DAY = 24 * 60 * 60 * 1000; // 1 day in ms
        var dateInTwoWeeks = Utils.addDate(today, 14);

        var createTask = function(contact, schedule, report) {
            return new Task({
                _id: contact.contact._id + '-' + schedule.id,
                deleted: (contact.contact ? contact.contact.deleted : false) || (report ? report.deleted : false),
                doc: contact,
                contact: contact.contact,
                icon: schedule.icon,
                priority: schedule.description ? 'high' : null,
                priorityLabel: schedule.description ? schedule.description : '',
                date: null,
                title: schedule.title,
                resolved: false,
                actions: []
            });
        };

        var getNextSurveyDate = function(previous_survey_date, days) {
            var result;
            if (previous_survey_date) {
                result = new Date(previous_survey_date);
                result.setDate(result.getDate() + days);
            }
            else {
                result = new Date();
            }
            return result;
        };

        // Person task function definition that doesn't take a report
        var createPersonTask = function(contact, schedule) {
            return new Task({
                _id: contact.contact._id + '-' + schedule.id,
                deleted: (contact.contact ? contact.contact.deleted : false),
                doc: contact,
                contact: contact.contact,
                icon: schedule.icon,
                priority: schedule.description ? 'high' : null,
                priorityLabel: schedule.description ? schedule.description : '',
                date: null,
                title: schedule.title,
                resolved: false,
                actions: []
            });
        };

        var emitTask = function(task, scheduleEvent) {
            if (Utils.isTimely(task.date, scheduleEvent)) {
                emit('task', task);
            }
        };

        var createTargetInstance = function(type, report, pass) {
            return new Target({
                _id: report._id + '-' + type,
                deleted: !!report.deleted,
                type: type,
                pass: pass,
                date: report.reported_date
            });
        };

        var emitTargetInstance = function(instance) {
            emit('target', instance);
        };

        // Generate Targets
        if (c.contact != null) {
            c.reports.forEach(function(r) {
                if (c.contact.type === 'person') {
                    // % of Under-5 Diarrhoea cases experienced for more than 72 hours followed-up within 48 hours
                    if (((r.form === 'assessment' && r.fields.has_symptoms === 'true')
                            || (r.form === 'assessment_follow_up' && r.fields.referral_follow_up_needed === 'true'))
                        && parseInt(r.fields.patient_age_in_years) < 5 && r.fields.has_diarrhoea === 'true' && parseInt(r.fields.diarrhoea.diarrhoea_duration) >= 3) {
                        var pass = Utils.isFormSubmittedInWindow(c.reports, 'assessment_follow_up', r.reported_date, new Date(r.reported_date + (2*MS_IN_DAY)));
                        var instance = createTargetInstance('u5-diarrhoea-72hr-followup-48hr', r, pass);
                        emitTargetInstance(instance);
                    }
                }
            });
        }
        
        // Person tasks: add corresponding task for each form
        // Make this possible for persons added to a family: person->clinic(family)->health_center->district_hospital
        if (c.contact && c.contact.type === 'person') {
            var newestFollowUpTimestamp = Utils.getMostRecentTimestamp(c.reports, 'c_assessment_follow_up');
            var reportCount = c.reports.length;
            var contact_dob = new Date(c.contact.date_of_birth);
            var age_at_registration = Math.round((c.contact.reported_date - contact_dob) / MS_IN_DAY/ 365);
            // Under 100 years
            if (age_at_registration < 100){
                var schedule = Utils.getSchedule('c-assessment');
                if (schedule){
                    schedule.events.forEach(function(s){
                        var survey = createTask(c, s);
                        survey.date = new Date(Utils.addDate(contact_dob, s.days));
                        survey.resolved = Utils.isFormSubmittedInWindow(c.reports, 'c_assessment', Utils.addDate(survey.date, s.start * -1).getTime(), Utils.addDate(survey.date, (s.end + 1)).getTime());
                        survey.actions.push({
                            type: 'report',
                            form: 'c_assessment',
                            label: 'Baseline Assessment',
                            content: {
                                source: 'task',
                                contact: c.contact
                            }
                        });
                        emitTask(survey, s);
                    });
                }
            }
            // Report based tasks
            c.reports.forEach(
                function (r) {
                    switch (r.form) {
                        case 'c_assessment':
                            schedule = Utils.getSchedule('c-assessment-follow-up');
                            var followUpCount = (r && r.fields && r.fields.follow_up_count) ? parseInt(r.fields.follow_up_count, 10) : 0;
                            if ( schedule)
                            {
                                schedule.events.forEach(function(s) {
                                    var review = createTask(c, s, r);
                                    review.date = Utils.addDate(new Date(r.reported_date), s.days);
                                    review.resolved = Utils.isFormSubmittedInWindow(c.reports, 'c_assessment_follow_up', Utils.addDate(review.date, s.start * -1).getTime(), Utils.addDate(review.date, (s.end + 1)).getTime(), followUpCount);
                                    review.actions.push({
                                        type: 'report',
                                        form: 'c_assessment_follow_up',
                                        label: 'Patient Review',
                                        content: {
                                            source: 'task',
                                            source_id: r._id,
                                            contact: c.contact,
                                            t_follow_up_count: followUpCount + 1
                                        }
                                    });
                                    emitTask(review, s);
                                });
                            }
                        break;
                        case 'c_assessment_follow_up':
                            var reportedDate = new Date(r.reported_date);
                            console.log(reportCount);
                            schedule = Utils.getSchedule('c-assessment-follow-up');
                            var followUpCount = (r && r.fields && r.fields.follow_up_count) ? parseInt(r.fields.follow_up_count, 10) : 1;
                            if ( schedule
                                && r && r.fields
                                && r.fields.referral_follow_up_needed != 'false'
                                && followUpCount < 3 )
                            {
                                schedule.events.forEach(function(s) {
                                    var dueDate = new Date(Utils.addDate(reportedDate, s.days));
                                    var review = createTask(c, s, r);
                                    review.date = Utils.addDate(new Date(r.reported_date), s.days);;
                                    review.resolved = Utils.isFormSubmittedInWindow(c.reports, 'c_assessment_follow_up', Utils.addDate(review.date, s.start * -1).getTime(), Utils.addDate(review.date, (s.end + 1)).getTime());
                                    review.actions.push({
                                        type: 'report',
                                        form: 'c_assessment_follow_up',
                                        label: 'Patient Review',
                                        content: {
                                            source: 'task',
                                            source_id: r._id,
                                            contact: c.contact,
                                            t_follow_up_count: followUpCount + 1
                                        }
                                    });
                                    console.log(review);
                                    emitTask(review, s);
                                });
                            }
                        break;
                    }
                }
            );
        }
        
        emit('_complete', { _id: true });
    }
}