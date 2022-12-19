'use strict'

const oracledb = require('oracledb');

/**
 * 
 * @returns {Promise<unknown>}
 */
const getProps = async (credentials, sql) => {

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
        console.log('*** Retrieved ', result.rows.length, ' records ***');
        return result;
    } catch (e) {
        console.error('getProps() - Error retrieving db records', e);
        throw e;
    } finally {
        if (connection) {
            try {
                await connection.close();
                console.log('Database connection closed');
            } catch (e) {
                console.error(e);
            }
        }
    }
};

module.exports = { getProps }
