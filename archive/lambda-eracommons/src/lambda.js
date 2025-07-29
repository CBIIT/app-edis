const oracledb = require('oracledb');
const AWS = require('aws-sdk'),
    region = 'us-east-1'

const CBIITSQL = `select * from era_commons_users_t where
                  last_changed_date > TRUNC(sysdate)`

// Set the console log level
const logLevel = process.env['LOG_LEVEL'];
if (logLevel && logLevel == 'info') {
    console.debug = function () {}
}

AWS.config.update({ region: region });
const SECRET = process.env.SECRET || 'era-commons-connect';
const TABLE  = process.env.TABLE || 'extusers-dev';

let user;
let pwd;
let connectString;

// Create a Secrets Manager client
const client = new AWS.SecretsManager({
    region: region
});

// Create a Dynamo DB client
const docClient = new AWS.DynamoDB.DocumentClient({maxRetries: 15, retryDelayOptions: {base: 200}});

async function getSecretParameters() {
    const data = await client.getSecretValue({SecretId: SECRET}).promise();
    if (data) {
        if (data.SecretString) {
            const parsedSecret = JSON.parse(data.SecretString);
            user = parsedSecret.user;
            pwd = parsedSecret.pwd;
            connectString = parsedSecret.connect;
        }
    }
    else {
        console.error('SecretsManager Success: NO ERR OR DATA');
        throw new Error('SecretsManager Success: NO ERR OR DATA');
    }
}


module.exports.handler = async (event, context, callback) => {
    context.callbackWaitsForEmptyEventLoop = false;
    console.debug('Incoming event:', JSON.stringify(event));

    if (!connectString) {
        await  getSecretParameters();
    }

    // retrieve data from eRA Commons
    const result = await readFromCBIITdb({
        user: user,
        pwd: pwd,
        connectString: connectString
    }, CBIITSQL);
    console.log('*** About to convert from CBIIT db : ', result.rows.length);
    if (event.test) {
        console.log('--- Test mode is on - do not populate ddb table - completed');
        return;
    }
    await populateToDynamoDB(TABLE, result.rows);
}

async function readFromEraCommons(credentials) {
    oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
    let connection;
    try {
        console.debug('Establishing db connection...');
        connection = await oracledb.getConnection({
            user: credentials.user,
            password: credentials.pwd,
            connectString: credentials.connectString
        });
        console.log('Connection has been established', connection);
        const result = await connection.execute(
            `select a.user_id,
                    a.person_id,
                    a.email,
                    p.name_prefix,
                    p.first_name,
                    p.mi_name,
                    p.last_name,
                    p.name_suffix,
                    a.status_code,
                    CASE a.status_code
                        WHEN 0 THEN 'Inactive'
                        WHEN 1 THEN 'Active'
                        WHEN 2 THEN 'Pending'
                        WHEN 3 THEN 'Locked due to inactivity'
                        WHEN 4 THEN 'Pending Affiliation'
                        WHEN 5 THEN 'Pending Account Owner Agreement'
                        END as status_descrip,
                    a.created_date as account_created_date,
                    a.last_upd_date as account_updated_date,
                    a.last_login_date as account_last_login_date,
                    exo.external_org_id as org_id,
                    exo.org_name as org_name,
                    ext.line_1_addr,
                    ext.line_2_addr,
                    ext.line_3_addr,
                    ext.line_4_addr,
                    ext.line_5_addr,
                    ext.city_name,
                    ext.state_code,
                    ext.phone_num,
                    ext.email_addr,
                    ua.EXT_SYS_USER_ID as logingov_user_id,
                    ua.DESCRIP as alias_descrip,
                    'ERA' as data_source,
                    null as last_changed_date
             from era_user_aliases_t ua,
                  era_users_t a,
                  external_orgs_mv exo,
                  persons_secure p,
                  external_org_addresses_t ext
             where ua.ext_sys_name = 'LOGIN.GOV'
               and ua.IMPACII_USER_ID = a.user_id
               and a.account_type = 'EXT'
               and a.primary_org_id = exo.external_org_id(+)
               and a.person_id = p.person_id(+)
               and exo.external_org_id = ext.external_org_id(+)
               and ext.addr_type_code(+) = 'MLG'
               and a.user_id = 'RKDAVIS1'`
        )
        console.log('*** Result from eRA: ', result);
        console.log('*** Convert from eRA: ', convert4DynamoDb(result.rows[0]));
    }
    catch (e) {
        console.error(e);
    }
    finally {
        if (connection) {
            try {
                await connection.close();
                console.log('Database connection closed');
            } catch (e) {
                console.error(e);
            }
        }
    }
}

async function readFromCBIITdb(credentials, sql) {
    oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
    let connection;
    try {
        console.debug('Establishing db connection...');
        connection = await oracledb.getConnection({
            user: credentials.user,
            password: credentials.pwd,
            connectString: credentials.connectString
        });
        console.log('Connection has been established.  Executing retrieval of updated records...');
        const result = await connection.execute(sql);
        console.log('*** Retrieved ', result.rows.length, 'inserted/updated records');
        return result;
    }
    catch (e) {
        console.error(e);
    }
    finally {
        if (connection) {
            try {
                await connection.close();
                console.log('Database connection closed');
            } catch (e) {
                console.error(e);
            }
        }
    }
}

function convert4DynamoDb(row) {
    const res = {}
    for (const p in row) {
        if (p === 'LAST_CHANGED_DATE') {
            continue;
        }
        const newProp = (p === 'DATA_SOURCE') ? 'SOURCE' : p;
        if (row[p] == null) {
            res[newProp] = null;
        }
        else if (typeof(row[p]) === 'number') {
            res[newProp] = row[p];
        }
        else if (row[p] instanceof Date) {
            res[newProp] = convertDate(row[p]);
        } else {
            res[newProp] = cleanString(row[p]);
        }
    }
    // Add artificial fields
    res['LAST_UPDATED_DAY'] = getLastUpdatedDay(row['LAST_CHANGED_DATE'] != null ? row['LAST_CHANGED_DATE'] : (row['ACCOUNT_UPDATED_DATE'] != null ?
        row['ACCOUNT_UPDATED_DATE'] : row['ACCOUNT_CREATED_DATE']));
    return res;
}

function convertDate(d) {
    return   d.getFullYear().toString().padStart(4, '0') + '-'
        + (d.getMonth()+1).toString().padStart(2, '0') + '-'
        + d.getDate().toString().padStart(2, '0') + 'T'
        + d.getHours().toString().padStart(2, '0') + ':'
        + d.getMinutes().toString().padStart(2, '0') + ':'
        + d.getSeconds().toString().padStart(2, '0') + 'Z';
}

function cleanString(str) {
    if (str.indexOf('\t') >= 0) {
        console.log('string with tab: ', str )
    }
    let ret = str.replace(/"/g, '\\"');
    return ret.replace(/\u0009/g, "");
}

function getLastUpdatedDay(d) {
    // const d = updated != null ? updated : created;
    return   d.getFullYear().toString().padStart(4, '0') + '-'
        + (d.getMonth()+1).toString().padStart(2, '0') + '-'
        + d.getDate().toString().padStart(2, '0');
}

async function populateToDynamoDB(table, rows) {
    console.log("Importing data into DynamoDb table \"" + table + "\"...");

    let n = 1;
    try {
        let batch = [];
        for (let i = 0; i < rows.length; i++) {
            const record = convert4DynamoDb(rows[i]);
            console.debug(n, record.USER_ID);
            batch.push({
                PutRequest : {
                    Item: record
                }
            });
            if (batch.length >= 25 || (i === (rows.length - 1))) {

                var params = {
                    RequestItems: {
                        [table]: batch
                    }
                };
                await docClient.batchWrite(params).promise();
                console.debug('*** batchWrite of ' + batch.length + ' records performed');
                batch = [];
            }
            n++;
        }
    } catch (e) {
        console.error(e);
    }

    console.log("Imported " + (n - 1) + " data records into DynamoDb table \"" + table + "\"");
}

module.exports.readFromEraCommons = readFromEraCommons;
module.exports.readFromCBIITdb = readFromCBIITdb;
module.exports.convert4DynamoDb = convert4DynamoDb;
module.exports.populateToDynamoDB = populateToDynamoDB;


