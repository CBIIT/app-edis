
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

const SQL_STATEMENT1 =
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

const SQL_STATEMENT =
    `SELECT ned.uniqueidentifier ned_id,
       ned.givenname first_name,
       ned.middlename middle_name,
       ned.sn last_name,
       wrkf.gender_cd,
       wrkf.gender_desc,
       wrkf.hi_education_desc,
       wrkf.citizenship_desc,
       ned.nihdirentryeffectivedate nih_eod,
       ned.nihservao,
       ned.nihsac,
       fel.awd_prd_from_dt,
       fel.awd_prd_to_dt,
       fel.train_prog_cd,
       fel.train_prog_desc,
       intls.visa_type,
       stip.award_line_type,
       stip.activation_dt,
      -- CASE WHEN ned.inactive_date IS NULL THEN 'Y' ELSE 'N' END ned_active_ind,
       (SELECT MIN (awd_prd_from_dt) 
        FROM hr_fel_awards_dim fps,
             hr_wrkf_dim wrkf
        WHERE wrkf.curr_ned_id = ned.uniqueidentifier
        AND wrkf.fel_awd_nbr = fps.awd_nbr
        AND fps.train_prog_cd = fel.train_prog_cd) train_prog_start_dt,
       ned.mixcase_givenname mixcase_first_name,
       ned.mixcase_middlename mixcase_middle_name,
       ned.nihmixcasecommonsn mixcase_last_name,
       ned.organizationalstat,
       wrkf.hi_education_cd,
       ned.nihorgpath,
       ned.nihorgacronym,
       SYSDATE load_date,
       ned.nihcommongivenname preferred_first_name,
       ned.nihcommonmiddlenam preferred_middle_name,
       ned.nihcommonsn preferred_last_name,
       stip.action_type,
       stip.action_type_desc,
       NVL(ned.mail, ned.nihprimarysmtp) email_address,
       fel.termination_dt,
       stip.act_eff_dt,
       fel.termination_flg
 FROM hr_fel_awards_dim fel,
      HR_NED_HISTORY_FCT_all ned,
      hr_fel_stipend_dim stip,
      (SELECT award_key,
              stipend_key
       FROM (SELECT award_key,
                    stipend_key,
                    fel_summ_key,
                    MAX (fel_summ_key) OVER (PARTITION BY award_key) max_fel_summ_key
           FROM hr_fel_summ_fct)
       WHERE fel_summ_key = max_fel_summ_key) summ,
      (SELECT wrkf_key,
              curr_ned_id,
              fel_awd_nbr,
              first_name,
              middle_name,
              last_name,
              gender_cd,
              gender_desc,
              hi_education_cd,
              hi_education_desc,
              citizenship_desc
         FROM (SELECT wrkf_key,
                      curr_ned_id,
                      fel_awd_nbr,
                      first_name,
                      middle_name,
                      last_name,
                      gender_cd,
                      gender_desc,
                      hi_education_cd,
                      hi_education_desc,
                      citizenship_desc,
                      MAX (wrkf_key) OVER (PARTITION BY curr_ned_id)
                         max_wrkf_key
                 FROM hr_wrkf_dim
                 WHERE latest_rec_flg = 'Y')
        WHERE wrkf_key = max_wrkf_key) wrkf,
       (SELECT wrkf_key,
               curr_ned_id,
               fel_awd_nbr,
               gender_cd,
               gender_desc,
               hi_education_cd,
               hi_education_desc,
               citizenship_desc
        FROM (SELECT wrkf_key,
                     curr_ned_id,
                     fel_awd_nbr,
                     gender_cd,
                     gender_desc,
                     hi_education_cd,
                     hi_education_desc,
                     citizenship_desc,
                     MAX(wrkf_key) OVER (PARTITION BY curr_ned_id) max_wrkf_key
             FROM (SELECT wrkf_key,
                          curr_ned_id,
                          fel_awd_nbr,                                                              
                          gender_cd,
                          gender_desc,
                          hi_education_cd,
                          hi_education_desc,
                          citizenship_desc,
                          effective_from_dt,
                          MAX(effective_from_dt) OVER (PARTITION BY curr_ned_id) max_eff_dt,
                          latest_rec_flg
                     FROM hr_wrkf_dim
                     WHERE confirmed_by_source_flg = 'Y')
            WHERE effective_from_dt = max_eff_dt)
        WHERE wrkf_key = max_wrkf_key) wrkf2,
      (SELECT ned_id, visa_type
         FROM (SELECT ned_id,
                      visa_type,
                      load_date,
                      MAX (load_date) OVER (PARTITION BY ned_id)
                         max_load_date
                 FROM hr_intls_visa_dtls)
        WHERE load_date = max_load_date) intls
WHERE ned.uniqueidentifier = wrkf.curr_ned_id
AND ned.uniqueidentifier = wrkf2.curr_ned_id(+)
--                                        AND ned.nihorgacronym = 'NCI'
AND ned.organizationalstat = 'FELLOW'
AND ned.nihdirentryeffectivedate <= TRUNC(SYSDATE)
AND wrkf2.fel_awd_nbr = fel.awd_nbr(+)
AND fel.award_key = summ.award_key(+)
AND summ.stipend_key = stip.stipend_key(+)
AND wrkf2.curr_ned_id = intls.ned_id(+)
OFFSET %TOKEN% ROWS
    FETCH NEXT %LIMIT ROWS ONLY`;

module.exports = {conf, initConfiguration, SQL_STATEMENT };