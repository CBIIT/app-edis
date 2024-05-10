class OrgListResponse {
    count = 0;
    error;
    lastEvaluatedKey;
    items = [];
}

class Organization {
    NIHSAC;
    NIHORGACRONYM;
    NIHORGNAME;
    NIHORGPATH;
    NIHOUACRONYM;
    NIHOUNAME;
    NIHPARENTSAC;
    DOCSAC;
    DOCORGPATH;

    constructor(sac, orgAcronym, orgName, orgPath, ouAcronym, ouName, parentSac, docSac, docPath ) {
        this.NIHSAC = sac;
        this.NIHORGACRONYM = orgAcronym;
        this.NIHORGNAME = orgName;
        this.NIHORGPATH = orgPath;
        this.NIHOUACRONYM = ouAcronym;
        this.NIHOUNAME = ouName;
        this.NIHPARENTSAC = parentSac;
        this.DOCSAC = docSac;
        this.DOCORGPATH = docPath;

    }
}

module.exports = { Organization, OrgListResponse }