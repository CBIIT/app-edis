const oracledb = require('oracledb');
const AWS = require('aws-sdk'),
    region = 'us-east-1'

// Set the console log level
const logLevel = process.env['LOG_LEVEL'];
if (logLevel && logLevel == 'info') {
  console.debug = function () {}
}

AWS.config.update({ region: region });
const SECRET = 'era-commons-connect';

let user;
let pwd;
let connectString;

// Create a Secrets Manager client
const client = new AWS.SecretsManager({
  region: region
});

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
  console.debug('Incomin event:', JSON.stringify(event));
  
  if (!connectString) {
    await  getSecretParameters();
  }

  // retrieve data from eRA Commons
  await readFromEraCommons();
}

async function readFromEraCommons() {
  oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
  let connection;
  try {
      console.debug('Establishing db connection...');
    connection = await oracledb.getConnection({
      user: user,
      password: pwd,
      connectString: connectString
    });
    console.log('Connection has been established', connection);
    const result = await connection.execute(
        `select * from era_users_t where user_id = 'MULLANEYJ'`
                                // `select a.user_id,
                                //         a.person_id,
                                //         a.email,
                                //         p.name_prefix,
                                //         p.first_name,
                                //         p.mi_name,
                                //         p.last_name,
                                //         p.name_suffix,
                                //         a.status_code,
                                //         CASE a.status_code
                                //           WHEN 0 THEN 'Inactive'
                                //           WHEN 1 THEN 'Active'
                                //           WHEN 2 THEN 'Pending'
                                //           WHEN 3 THEN 'Locked due to inactivity'
                                //           WHEN 4 THEN 'Pending Affiliation'
                                //           WHEN 5 THEN 'Pending Account Owner Agreement'
                                //         END as status_descrip,
                                //         a.created_date as account_created_date,
                                //         a.last_upd_date as account_updated_date,
                                //         a.last_login_date as account_last_login_date,
                                //         exo.external_org_id as org_id,
                                //         exo.org_name as org_name,
                                //         ext.line_1_addr,
                                //         ext.line_2_addr,
                                //         ext.line_3_addr,
                                //         ext.line_4_addr,
                                //         ext.line_5_addr,
                                //         ext.city_name,
                                //         ext.state_code,
                                //         ext.phone_num,
                                //         ext.email_addr
                                //  from era_users_t a,
                                //       external_orgs_mv exo,
                                //       persons_secure p,
                                //       external_org_addresses_t ext
                                //  where a.account_type = 'EXT'
                                //    and a.primary_org_id = exo.external_org_id(+)
                                //    and a.person_id = p.person_id(+)
                                //    and exo.external_org_id = ext.external_org_id(+)
                                //    and ext.addr_type_code(+) = 'MLG'
                                //    and a.created_date > sysdate - 15`
    )
    console.log('*** Result from eRA: ', result);
  }
  catch (e) {
    console.error(e);
  }
  finally {
    if (connection) {
      try {
        await connection.close();
        console.log('connection closed');
      } catch (e) {
        console.error(e);
      }
    }
  }
}

module.exports.readFromEraCommons = readFromEraCommons;

