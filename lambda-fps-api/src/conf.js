
const conf = {
    fps: {}
};

function initConfiguration(configuration) {
    Object.assign(conf.fps, configuration);
}

const SQL_STATEMENT0 =
    `SELECT * from HR_WRKF_GEN_DIM
    WHERE NED_ACTIVE_FLG = 'Y' AND LATEST_REC_FLG = 'Y' AND FULL_NAME LIKE 'GUNI%'
    FETCH NEXT 1000 ROWS ONLY`;

const SQL_STATEMENT =
    `SELECT CURR_NED_ID NED_ID,
            GENDER_CD,
            GENDER_DESC,
            FULL_NAME,
            STAFF_TYP_CD,
            STAFF_TYP_DESC,
            EFFECTIVE_FROM_DT,
            EFFECTIVE_TO_DT,
            NED_ACTIVE_FLG,
            ORG_CD
    FROM HR_WRKF_GEN_DIM
    WHERE NED_ACTIVE_FLG = 'Y' AND LATEST_REC_FLG = 'Y'
    OFFSET %TOKEN% ROWS
    FETCH NEXT %LIMIT% ROWS ONLY`;

module.exports = {conf, initConfiguration, SQL_STATEMENT };