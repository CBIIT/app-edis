
const { conf } = require("./conf");
const { Organization }  = require("./orgListResponse");
const axios = require('axios');
const { getAuthorizationHeader, processPaginatedResult } = require("./util");

function orgRoutes(app, opts) {

    app.get('/orgs', async (req, res) => {
        console.info(opts.prefix + '/orgs', req.params);
        try {
            if (req.query.Testing) {
                console.info(`Return in Testing mode`);
                res.json({ 'Success': true});
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
    app.get('/orgtree/:nihsac', async (req, res) => {
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

async function listAllOrgs(pageToken) {
    console.info(`List All Organizations from NIDAP`);
    let URL = `${conf.nidap.url_v1}objects/${conf.nidap.ontology_org}?orderBy=properties.sac:asc`;
    if (pageToken) {
        URL += `&pageToken=${pageToken}`;
    }
    console.info(`URL: ${URL}`);
    const auth = await getAuthorizationHeader(conf.nidap.auth_type, conf.nidap.auth_token, conf.nidap.auth_client_id,
        conf.nidap.auth_client_secret, conf.nidap.url_token);
    const resp = await axios.get(URL, {
        headers: {
            'Authorization': auth
        }
    });
    const items = [];
    resp.data.data.forEach((r) => {
        const p = r.properties;
        items.push(new Organization(p.sac, p.organizationAcronym, p.organization, p.organizationPath,
            p.instituteAcronym, p.institute, p.parentSac, p.docSac, p.docOrganizationPath));
    });
    return processPaginatedResult(resp.data, items);
}

async function searchOrgBySac(sac) {
    console.info(`Search Organizations by SAC code`);
    let URL = `${conf.nidap.url_v1}objects/${conf.nidap.ontology_org}/${sac}`;
    console.info(`URL: ${URL}`);
    const auth = await getAuthorizationHeader(conf.nidap.auth_type, conf.nidap.auth_token, conf.nidap.auth_client_id,
        conf.nidap.auth_client_secret, conf.nidap.url_token);
    const resp = await axios.get(URL, {
        headers: {
            'Authorization': auth
        }
    });
    if (resp.status === 200) { //Not found
        const p = resp.data.properties;
        const result = new Organization(p.sac, p.organizationAcronym, p.organization, p.organizationPath,
            p.instituteAcronym, p.institute, p.parentSac, p.docSac, p.docOrganizationPath);
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

async function searchOrgTreeBySac(sac, pageToken) {
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
    if (pageToken) {
        data['pageToken'] = pageToken;
    }
    const auth = await getAuthorizationHeader(conf.nidap.auth_type, conf.nidap.auth_token, conf.nidap.auth_client_id,
        conf.nidap.auth_client_secret, conf.nidap.url_token);
    const resp = await axios.post(URL, data, {
            headers: {
                'Authorization': auth
            },
    });

    // console.debug(resp.data);
    const items = [];
    resp.data.data.forEach((r) => {
        const p = r.properties;
        items.push(new Organization(p.sac, p.organizationAcronym, p.organization, p.organizationPath,
            p.instituteAcronym, p.institute, p.parentSac, p.docSac, p.docOrganizationPath));
    });
    return processPaginatedResult(resp.data, items);
}

module.exports = { orgRoutes, listAllOrgs, searchOrgBySac, searchOrgTreeBySac};

