const readme = require('./src/lambda')

const CBIITSQL = `select * from era_commons_users_t where
                  last_changed_date > TRUNC(sysdate) - 2`

async function runme()
{
    // await readme.readFromEraCommons({
    //     user: 'LINK_NCI_BIZAPPS',
    //     pwd: '3edcCDE#3edcCDE#3edcCDE#',
    //     connectString: '(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = flt-scan-irdb-prd-replica.era.nih.gov)(PORT=1551)))(CONNECT_DATA = (SERVICE_NAME = prdirdb)(UR = A)))'
    // });

    const result = await readme.readFromCBIITdb({
        user: 'EDIS',
        pwd: 'Nr2KfaK6_hGgcVD3',
        connectString: '(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = nci-ocm-dev.nci.nih.gov)(PORT=1610)))(CONNECT_DATA = (SERVICE_NAME = CBIITSGD.nci.nih.gov)))' 
    }, CBIITSQL);
    if (result.rows.length > 0) {
        console.log('Completed, first record is ', readme.convert4DynamoDb(result.rows[0]));
    } else {
        console.log('Completed with 0 records');
    }
}

runme();