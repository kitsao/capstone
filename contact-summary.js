var cards = [];
var context = {};
var fields = [];

if (contact.type === 'person') {
    fields = [{
        label: 'contact.age',
        value: contact.date_of_birth,
        width: 4,
        filter: 'age'
    }, {
        label: 'Phone Number',
        value: contact.phone,
        width: 4,
        filter: 'phone'
    }, {
        label: 'contact.sex',
        value: contact.sex,   
        translate: true,     
        width: 4
    }, {
        label: 'contact.parent',
        value: lineage,
        filter: 'lineage'
    }];
} else {
    if (lineage) {
        fields.push({
            label: 'contact.parent',
            value: lineage,
            filter: 'lineage'
        });
    }
}

return {
    fields: fields,
    cards: cards,
    context: context
};