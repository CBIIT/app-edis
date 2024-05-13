
const { conf } = require("./conf");
const {Organization, OrgListResponse}  = require("./orgListResponse");
const axios = require('axios');

function orgRoutes(app, opts) {

    app.get('/orgs', async (req, res) => {
        console.info(opts.prefix + '/orgs', req.params);
        try {
            if (req.query.Testing) {
                console.info(`Return in Testing mode`);
                return { 'Success': true};
            }
            res.json(await listAllOrgs(req.query.lastEvaluatedKey));
        } catch (error) {
            console.error('ERROR:', error);
            res.status(500).send(error);
        }
    });
    app.get('/orgs/:nihsac', async (req, res) => {
        console.info(opts.prefix + '/orgs', req.params);
        try {
            if (req.query.Testing) {
                console.info(`Return in Testing mode`);
                return { 'Success': true};
            }
            const result = await searchOrgBySac(req.params.nihsac);
            if (result.status) {
                res.status(result.status).send(result.error);
            }
            else {
                res.json(result);
            }
        } catch (error) {
            console.error('ERROR:', error);
            res.status(500).send(error);
        }
    });
    app.get('/orgTree/:nihsac', async (req, res) => {
        console.info(opts.prefix + '/orgs', req.params);
        try {
            if (req.query.Testing) {
                console.info(`Return in Testing mode`);
                return { 'Success': true};
            }
            res.json(await searchOrgTreeBySac(req.params.nihsac, req.query.lastEvaluatedKey));
        } catch (error) {
            console.error('ERROR:', error);
            res.status(error.response.status).send(error.data);
        }
    });
}

async function listAllOrgs(nextPageToken) {
    console.info(`List All Organizations from NIDAP`);
    let URL = `${conf.nidap.url_v1}objects/${conf.nidap.ontology_org}?orderBy=properties.sac:asc`;
    if (nextPageToken) {
        URL += `&nextPageToken=${nextPageToken}`;
    }
    const resp = await axios.get(URL, {
        headers: {
            'Authorization': `Bearer ${conf.nidap.auth_token}`
        }
    });
    const nidapResp = resp.data;
    const result = new OrgListResponse();
    result.count =nidapResp.data.length;
    if (nidapResp.nextPageToken) {
        result.lastEvaluatedKey = nidapResp.nextPageToken;
    }
    nidapResp.data.forEach((r) => {
        const p = r.properties;
        result.items.push(new Organization(p.sac, p.organizationAcronym, p.organization, p.organizationPath,
            p.instituteAcronym, p.instiute, p.parentSac, p.docSac, p.docOrganizationPath));
    })
    // Post-process NIDAP response


    console.debug(`Got result `);
    console.debug(result);
    // console.debug(JSON.stringify(result));

    return result;
}

async function searchOrgBySac(sac) {
    console.info(`Search Organizations by SAC code`);
    let URL = `${conf.nidap.url_v1}objects/${conf.nidap.ontology_org}/${sac}`;
    const resp = await axios.get(URL, {
        headers: {
            'Authorization': `Bearer ${conf.nidap.auth_token}`
        }
    });
    if (resp.status === 200) { //Not found
        const p = resp.data.properties;
        const result = new Organization(p.sac, p.organizationAcronym, p.organization, p.organizationPath,
            p.instituteAcronym, p.instiute, p.parentSac, p.docSac, p.docOrganizationPath);
        console.debug(`Got result `);
        console.debug(result);
        return result;
    }
    else if (resp.status == 404) { // Not Found
        console.info(`Got result - Not found - ${resp.data}`);
        return new Organization();
    }

    const err_resp = {
        status: resp.status,
        error: resp.statusText
    }

    console.debug(`Got error result ${err_resp}`);
    return err_resp;
}

async function searchOrgTreeBySac(sac, nextPageToken) {
    console.info(`Search Organizations Subtree from NIDAP for the givan SAC Code ${sac}`);
    let URL = `${conf.nidap.url_v1}objects/${conf.nidap.ontology_org}/search`;

    const data = {
        query: {
            type: "prefix",
            field: "properties.sac",
            value: sac
        },
        orderBy: {
            fields: [
                {
                    field: "properties.sac",
                    direction: "asc"
                }
            ]
        }
    }
    if (nextPageToken) {
        data['pageToken'] = nextPageToken;
    }
    const resp = await axios.post(URL, data, {
            headers: {
                'Authorization': `Bearer ${conf.nidap.auth_token}`
            },
    });

    const nidapResp = resp.data;
    // console.debug(nidapResp);
    const result = new OrgListResponse();
    result.count = nidapResp.data.length;
    if (nidapResp.nextPageToken) {
        result.lastEvaluatedKey = nidapResp.nextPageToken;
    }
    nidapResp.data.forEach((r) => {
        const p = r.properties;
        result.items.push(new Organization(p.sac, p.organizationAcronym, p.organization, p.organizationPath,
            p.instituteAcronym, p.instiute, p.parentSac, p.docSac, p.docOrganizationPath));
    })
    // Post-process NIDAP response
    // console.debug(`Got result `);
    // console.debug(result);
    return result;
}

module.exports = { orgRoutes, listAllOrgs, searchOrgBySac, searchOrgTreeBySac};

