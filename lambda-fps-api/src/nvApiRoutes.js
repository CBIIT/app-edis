
const { conf, SQL_STATEMENT } = require("./conf");
const oracledb = require('oracledb');
const repl = require("node:repl");

function nvRoutes(app, opts) {
    app.get('/users', async (req, res) => {
        console.info('Route: ' + opts.prefix + '/users', req.params);
        try {
            if (req.query.Testing) {
                console.info(`Return in Testing mode`);
                return { 'Success': true};
            }
            const sql = (conf.fps.sql || SQL_STATEMENT) + (conf.fps.sql_cont1 || '') + (conf.fps.sql_cont2 || '');
            oracledb.initOracleClient({ libDir: '/opt/lib', configDir: '/opt/lib/network/adm' });
            const result = await listFpsUsers(sql, req.query.lastEvaluatedKey);
            console.debug('*** Retrieved ', result.items.length, ' FPS records ***');
            res.json(result);
        } catch (error) {
            console.error('ERROR:', error);
            res.status(500).send(error);
        }
    });
}

async function listFpsUsers(sql, pageToken) {
    oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
    const offset = Number(pageToken) || 0;
    const replacements = { "%TOKEN%" : offset.toString(),
                                         "%LIMIT%" : conf.fps.maxSize };
    // console.debug('replacements ', replacements);
    const curr_sql = sql.replace(/%\w+%/g, function(all) {
        return replacements[all] || all;
    });
    // console.debug('curr sql ', curr_sql);
    let connection;
    try {
        console.debug('Establishing db connection...');
        connection = await oracledb.getConnection({
            user: conf.fps.user,
            password: conf.fps.pwd,
            connectString: conf.fps.connectString
        });
        console.debug('Connection has been established.  Executing retrieval of FPS records...');
        const result = await connection.execute(curr_sql);
        console.debug('*** Retrieved ', result.rows.length, ' records ***');
        return _processPaginatedResult(result.rows, offset);
    } catch (e) {
        console.error('dbExec() - Error retrieving db records', e);
        throw e;
    } finally {
        if (connection) {
            try {
                await connection.close();
                console.debug('Database connection closed');
            } catch (e) {
                console.error(e);
            }
        }
    }
}

function _processPaginatedResult(sqlResult, offset) {
    const ret = {};
    ret['count'] = sqlResult.length;
    const maxSize = Number(conf.fps.maxSize);
    if (sqlResult.length === maxSize) {
        ret['lastEvaluatedKey'] = (offset + maxSize).toString();
    }
    ret['items'] = sqlResult || [];
    return ret;
}

module.exports = { nvRoutes, listFpsUsers };