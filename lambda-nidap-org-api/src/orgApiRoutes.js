
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
            res.status(500).send(error);
        }
    });
    // app.get('/userByNIHid/:id', async (req, res) => {
    //     console.info('/userapi/ned/userByNIHid', req.params);
    //     try {
    //         const nihId = req.params.id;
    //
    //         if (nihId === undefined) {
    //             res.status(400).send('nihid is not defined.');
    //         }
    //         else if (!isNum.test(nihId)) {
    //             res.status(400).send('nihid is not numeric.');
    //         }
    //         else if (req.query.Testing) {
    //             console.info(`Return in Testing mode`);
    //             res.json({ 'Success': true});
    //         }
    //         else {
    //             res.json(await getByNIHid(nihid));
    //         }
    //     } catch (error) {
    //         res.status(500).send(error);
    //     }
    // });
    // app.get('/userByIDAccount/:id', async (req, res) => {
    //     console.info('/userapi/ned/userByIDAccount', req.params);
    //     try {
    //         if (req.query.Testing) {
    //             console.info(`Return in Testing mode`);
    //             return { 'Success': true};
    //         }
    //         res.json(await getByADAccount(req.params.id));
    //     } catch (error) {
    //         res.status(500).send(error);
    //     }
    // });
    // app.get('/usersByIc/:ic', async (req, res) => {
    //     console.info('/userapi/ned/usersByIc', req.params);
    //     try {
    //         if (req.query.Testing) {
    //             console.info(`Return in Testing mode`);
    //             return { 'Success': true};
    //         }
    //         res.json(await getByIc(req.params.ic));
    //     } catch (error) {
    //         res.status(500).send(error);
    //     }
    // });
    // app.get('/changesByIc/:ic', async (req, res) => {
    //     console.info('/userapi/ned/changesByIc', req.params);
    //     try {
    //         if (req.query.Testing) {
    //             console.info(`Return in Testing mode - no actual call is performed`);
    //             return { 'Success': true};
    //         }
    //         res.json(await getChangesByIc(req.params.ic,
    //             req.query.From_Date, req.query.From_Time, req.query.To_Date, req.query.To_Time));
    //     } catch (error) {
    //         res.status(500).send(error);
    //     }
    // });
}

async function listAllOrgs(nextPageToken) {
    console.info(`List All Organizations from NIDAP`);
    let URL = `${conf.nidap.url_v1}objects/${conf.nidap.ontology_org}?orderBy=properties.sac:asc`;
    if (nextPageToken) {
        URL += `?nextPageToken=${nextPageToken}`;
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

module.exports = { orgRoutes, listAllOrgs};
