
const conf = {
} 

function initConfiguration(configuration, user_prop, pwd_prop, connect_prop) {
    conf.user = configuration[user_prop];
    conf.pwd = configuration[pwd_prop];
    conf.connectString = configuration[connect_prop];
}

const SQL_STATEMENT =
    `SELECT a.user_id             AS USER_ID,
            a.person_id           AS PERSON_ID,
            a.email               AS EMAIL,
            p.name_prefix         AS NAME_PREFIX,
            p.first_name          AS FIRST_NAME,
            p.mi_name             AS MI_NAME,
            p.last_name           AS LAST_NAME,
            p.name_suffix         AS NAME_SUFFIX,
            a.status_code         AS STATUS_CODE,
            CASE a.status_code
                WHEN 0 THEN 'Inactive'
                WHEN 1 THEN 'Active'
                WHEN 2 THEN 'Pending'
                WHEN 3 THEN 'Locked due to inactivity'
                WHEN 4 THEN 'Pending Affiliation'
                WHEN 5 THEN 'Pending Account Owner Agreement'
            END                    AS STATUS_DESCRIP,
            a.created_date         AS ACCOUNT_CREATED_DATE,
            a.last_upd_date        AS ACCOUNT_UPDATED_DATE,
            a.last_login_date      AS ACCOUNT_LAST_LOGIN_DATE,
            exo.external_org_id    AS ORG_ID,
            exo.org_name           AS ORG_NAME,
            ext.line_1_addr        AS LINE_1_ADDR,
            ext.line_2_addr        AS LINE_2_ADDR,
            ext.line_3_addr        AS LINE_3_ADDR,
            ext.line_4_addr        AS LINE_4_ADDR,
            ext.line_5_addr        AS LINE_5_ADDR,
            ext.city_name          AS CITY_NAME,
            ext.state_code         AS STATE_CODE,
            ext.phone_num          AS PHONE_NUM,
            ext.email_addr         AS EMAIL_ADDR,lambda
            ua.EXT_SYS_USER_ID     AS LOGINGOV_USER_ID,
            ua.descrip             AS ALIAS_DESCRIP,
            'ERA'                  AS SOURCE
        FROM era_user_aliases_t        ua,
            era_users_t                a,
            external_orgs_mv           exo,
            persons_secure             p,
            external_org_addresses_t   ext
        WHERE     ua.ext_sys_name = 'LOGIN.GOV'
        AND ua.IMPACII_USER_ID = a.user_id
        AND a.account_type = 'EXT'
        AND a.primary_org_id = TO_CHAR(exo.external_org_id(+))
        AND a.person_id = p.person_id(+)
        AND exo.external_org_id = ext.external_org_id(+)
        AND ext.addr_type_code(+) = 'MLG'`

module.exports = { initConfiguration, conf, SQL_STATEMENT }
